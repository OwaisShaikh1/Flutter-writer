/// ============================================================================
/// MINIMAL DATABASE SYNC SERVICE v2
/// ============================================================================
/// 
/// This service handles offline-first synchronization between local SQLite and
/// remote MySQL backend. Designed to work in ANY scenario: online, offline,
/// partial sync, interrupted operations, etc.
/// 
/// ## DATABASE MAPPING
/// 
/// ### Server (MySQL):
/// ```
/// items:    id (server-assigned), name, type, description, author_id...
/// chapters: id, item_id (→ server items.id), number, name, Text
/// ```
/// 
/// ### Local (SQLite):
/// ```
/// items:    id (local), server_id (nullable), is_synced, name...
/// chapters: id (local), item_id (→ LOCAL items.id), number, title, content
/// sync_log: entity_type, entity_id, parent_id, operation, payload
/// ```
/// 
/// ## KEY CONCEPT: Local ID vs Server ID
/// 
/// - `id` (local): SQLite auto-increment, NEVER changes, used for all local FK refs
/// - `server_id`: Backend-assigned ID, set ONCE after first sync, used for API calls
/// 
/// ## SYNC FLOW
/// 
/// 1. **Create locally** → item gets local id, server_id = null, is_synced = false
/// 2. **Push to server** → server returns server_id, we store it, is_synced = true
/// 3. **Chapters use local id** → chapters.item_id always points to local items.id
/// 4. **API calls resolve server_id** → before any API call, look up server_id from local id
/// 
/// ## OFFLINE HANDLING
/// 
/// When offline, operations are logged in sync_log table. When online:
/// 1. Process sync_log in order (oldest first)
/// 2. For new items, capture local_id → server_id mapping during batch
/// 3. Use that mapping for dependent chapters in the same batch
/// 
/// ============================================================================

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/items_dao.dart';
import '../database/dao/chapters_dao.dart';
import '../database/dao/user_dao.dart';
import '../database/dao/sync_log_dao.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
  });

  @override
  String toString() => 'SyncResult(success: $success, message: $message, synced: $syncedCount, failed: $failedCount)';
}

/// Minimal Sync Service - handles all sync operations
class SyncServiceV2 {
  final AppDatabase _db;
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  late final ItemsDao _itemsDao;
  late final ChaptersDao _chaptersDao;
  late final UserDao _userDao;
  late final SyncLogDao _syncLogDao;

  SyncServiceV2(this._db) {
    _itemsDao = ItemsDao(_db);
    _chaptersDao = ChaptersDao(_db);
    _userDao = UserDao(_db);
    _syncLogDao = SyncLogDao(_db);
  }

  /// Get current logged in user ID for sync log filtering
  Future<int?> _getCurrentUserId() => _storage.getUserId();

  // ============================================================================
  // CONNECTIVITY
  // ============================================================================

  /// Check if device has internet connection
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ============================================================================
  // ITEM CRUD OPERATIONS
  // ============================================================================

  /// Create a new item locally
  /// Returns the LOCAL id (not server id)
  /// 
  /// Flow:
  /// 1. Insert into local DB with auto-generated id
  /// 2. server_id = null, is_synced = false
  /// 3. If online: try to push immediately
  /// 4. If offline/failed: log to sync_log for later
  Future<int> createItem({
    required String name,
    required String type,
    required String description,
    required String author,
    int? authorId,
    String? imageUrl,
  }) async {
    // 1. Insert locally - get auto-generated local ID
    final localId = await _itemsDao.upsertItem(ItemsCompanion(
      name: Value(name),
      type: Value(type),
      description: Value(description),
      author: Value(author),
      authorId: authorId != null ? Value(authorId) : const Value.absent(),
      imageUrl: Value(imageUrl),
      isSynced: const Value(false),
      serverId: const Value.absent(), // null until synced
    ));

    print('📝 Created item locally: "$name" (localId: $localId)');

    // 2. Try to push immediately if online
    if (await isOnline()) {
      final pushed = await _pushItemCreate(localId, name, type, description, imageUrl);
      if (pushed) {
        print('✅ Item pushed to server immediately');
        return localId;
      }
    }

    // 3. Offline or failed - queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logItemCreate(localId, {
      'name': name,
      'type': type,
      'description': description,
      'author': author,
      'authorId': authorId,
      'imageUrl': imageUrl,
    }, userId: userId);
    print('📋 Item queued in sync log (offline)');

    return localId;
  }

  /// Update an existing item
  /// Uses LOCAL id as parameter
  Future<bool> updateItem({
    required int localId,
    required String name,
    required String type,
    required String description,
    String? imageUrl,
  }) async {
    // 1. Update locally first (always succeeds)
    await _itemsDao.updateItem(localId, ItemsCompanion(
      name: Value(name),
      type: Value(type),
      description: Value(description),
      imageUrl: Value(imageUrl),
    ));

    print('📝 Updated item locally (localId: $localId)');

    // 2. Check if item has been synced to server
    final serverId = await _itemsDao.getServerId(localId);

    // 3. Try to push if online AND item has server_id
    if (await isOnline() && serverId != null) {
      final pushed = await _pushItemUpdate(serverId, name, type, description, imageUrl);
      if (pushed) {
        await _itemsDao.markAsSynced(localId);
        print('✅ Item update pushed to server (serverId: $serverId)');
        return true;
      }
    }

    // 4. Offline or not synced yet - queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logItemUpdate(localId, {
      'name': name,
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
    }, userId: userId);
    print('📋 Item update queued (${serverId == null ? "not synced yet" : "offline"})');

    return false;
  }

  /// Delete an item
  /// Uses LOCAL id as parameter
  Future<bool> deleteItem(int localId) async {
    // 1. Get server_id before deleting (need it for backend delete)
    final serverId = await _itemsDao.getServerId(localId);

    // 2. Delete locally (cascades to chapters via FK)
    await _chaptersDao.deleteChaptersByItemId(localId);
    await _itemsDao.deleteItem(localId);
    print('📝 Deleted item locally (localId: $localId)');

    // 3. If never synced, just clear any pending operations
    if (serverId == null) {
      final userId = await _getCurrentUserId();
      await _syncLogDao.logItemDelete(localId, userId: userId); // This clears pending creates/updates
      print('✅ Item was never synced, no backend delete needed');
      return true;
    }

    // 4. Try to delete from backend if online
    if (await isOnline()) {
      final deleted = await _api.deleteItem(serverId);
      if (deleted) {
        print('✅ Item deleted from server (serverId: $serverId)');
        return true;
      }
    }

    // 5. Queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logItemDelete(localId, userId: userId);
    print('📋 Item delete queued (offline)');

    return false;
  }

  // ============================================================================
  // CHAPTER CRUD OPERATIONS
  // ============================================================================

  /// Create a new chapter
  /// itemId is LOCAL id
  /// Returns LOCAL chapter id
  Future<int> createChapter({
    required int itemId, // LOCAL item id
    required int number,
    required String title,
    required String content,
  }) async {
    // 1. Insert locally - chapters.item_id references LOCAL items.id
    final chapterId = await _chaptersDao.upsertChapter(ChaptersCompanion(
      itemId: Value(itemId),
      number: Value(number),
      title: Value(title),
      content: Value(content),
    ));

    // 2. Update parent item's chapter count
    final item = await _itemsDao.getItemById(itemId);
    if (item != null) {
      final chapters = await _chaptersDao.getChaptersByItemId(itemId);
      await _itemsDao.updateItem(itemId, ItemsCompanion(
        chaptersCount: Value(chapters.length),
      ));
    }

    print('📝 Created chapter locally: "$title" (Ch.$number, localItemId: $itemId)');

    // 3. Try to push if online AND parent item has server_id
    final serverItemId = await _itemsDao.getServerId(itemId);
    if (await isOnline() && serverItemId != null) {
      final pushed = await _pushChapterCreate(serverItemId, number, title, content);
      if (pushed) {
        print('✅ Chapter pushed to server');
        return chapterId;
      }
    }

    // 4. Queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logChapterCreate(chapterId, itemId, {
      'number': number,
      'title': title,
      'content': content,
    }, userId: userId);
    print('📋 Chapter queued (${serverItemId == null ? "parent not synced" : "offline"})');

    return chapterId;
  }

  /// Update an existing chapter
  Future<bool> updateChapter({
    required int itemId, // LOCAL item id
    required int chapterNumber,
    required String title,
    required String content,
    int? newNumber,
  }) async {
    // 1. Get the chapter
    final chapter = await _chaptersDao.getChapter(itemId, chapterNumber);
    if (chapter == null) {
      print('⚠️ Chapter not found (itemId: $itemId, number: $chapterNumber)');
      return false;
    }

    // 2. Update locally
    await _db.customStatement('''
      UPDATE chapters 
      SET title = ?, content = ?, number = ?
      WHERE item_id = ? AND number = ?
    ''', [title, content, newNumber ?? chapterNumber, itemId, chapterNumber]);

    print('📝 Updated chapter locally (Ch.$chapterNumber)');

    // 3. Try to push if parent has server_id
    final serverItemId = await _itemsDao.getServerId(itemId);
    if (await isOnline() && serverItemId != null) {
      final pushed = await _api.updateChapter(serverItemId, chapterNumber, {
        'title': title,
        'content': content,
        'number': newNumber ?? chapterNumber,
      });
      if (pushed) {
        print('✅ Chapter update pushed to server');
        return true;
      }
    }

    // 4. Queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logChapterUpdate(chapter.id, itemId, {
      'number': newNumber ?? chapterNumber,
      'title': title,
      'content': content,
    }, userId: userId);
    print('📋 Chapter update queued');

    return false;
  }

  /// Delete a chapter
  Future<bool> deleteChapter({
    required int itemId, // LOCAL item id
    required int chapterNumber,
  }) async {
    // 1. Get chapter before deleting
    final chapter = await _chaptersDao.getChapter(itemId, chapterNumber);

    // 2. Delete locally
    await _chaptersDao.deleteChapter(itemId, chapterNumber);

    // 3. Update parent item's chapter count
    final chapters = await _chaptersDao.getChaptersByItemId(itemId);
    await _itemsDao.updateItem(itemId, ItemsCompanion(
      chaptersCount: Value(chapters.length),
    ));

    print('📝 Deleted chapter locally (Ch.$chapterNumber)');

    // 4. Try to delete from backend
    final serverItemId = await _itemsDao.getServerId(itemId);
    final userId = await _getCurrentUserId();
    if (serverItemId == null) {
      // Parent never synced, so chapter never existed on server
      if (chapter != null) {
        await _syncLogDao.logChapterDelete(chapter.id, itemId, chapterNumber, userId: userId);
      }
      print('✅ Parent item never synced, no backend delete needed');
      return true;
    }

    if (await isOnline()) {
      final deleted = await _api.deleteChapter(serverItemId, chapterNumber);
      if (deleted) {
        print('✅ Chapter deleted from server');
        return true;
      }
    }

    // 5. Queue for later
    if (chapter != null) {
      await _syncLogDao.logChapterDelete(chapter.id, itemId, chapterNumber, userId: userId);
    }
    print('📋 Chapter delete queued');

    return false;
  }

  // ============================================================================
  // PUSH SYNC (Local → Server)
  // ============================================================================

  /// Process all pending operations in sync_log for current user
  /// Call this when user clicks "Sync" or when coming back online
  Future<SyncResult> pushSync() async {
    if (!await isOnline()) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    final userId = await _getCurrentUserId();
    if (userId == null) {
      return SyncResult(success: false, message: 'No user logged in');
    }

    final operations = await _syncLogDao.getPendingOperationsForUser(userId);
    if (operations.isEmpty) {
      return SyncResult(success: true, message: 'Nothing to sync');
    }

    print('🔄 PUSH: Processing ${operations.length} pending operations...');

    int synced = 0;
    int failed = 0;

    // Track local_id → server_id for items created in this batch
    // Needed because chapters might reference items created earlier in same batch
    final Map<int, int> newItemIdMapping = {};

    for (final op in operations) {
      try {
        final payload = jsonDecode(op.payload) as Map<String, dynamic>;

        switch (op.entityType) {
          case 'item':
            await _processPendingItemOp(op, payload, newItemIdMapping);
            break;
          case 'chapter':
            await _processPendingChapterOp(op, payload, newItemIdMapping);
            break;
        }

        // Success - remove from log
        await _syncLogDao.removeOperation(op.id);
        synced++;
        print('   ✅ ${op.entityType} ${op.operation} completed');

      } catch (e) {
        // Failed - mark as attempted
        await _syncLogDao.markAttempted(op.id, e.toString());
        failed++;
        print('   ❌ ${op.entityType} ${op.operation} failed: $e');
      }
    }

    return SyncResult(
      success: failed == 0,
      message: failed == 0 ? 'All operations synced' : '$synced synced, $failed failed',
      syncedCount: synced,
      failedCount: failed,
    );
  }

  /// Process a pending item operation
  Future<void> _processPendingItemOp(
    SyncLogEntry op,
    Map<String, dynamic> payload,
    Map<int, int> newItemIdMapping,
  ) async {
    switch (op.operation) {
      case 'create':
        // Push new item to server
        final serverId = await _api.createItem(
          name: payload['name'] as String,
          type: payload['type'] as String,
          description: payload['description'] as String? ?? '',
          imageUrl: payload['imageUrl'] as String?,
        );

        if (serverId == null) throw Exception('Server returned null id');

        // Store server_id on local item
        await _itemsDao.setServerId(op.entityId, serverId);

        // Track for chapters in this batch
        newItemIdMapping[op.entityId] = serverId;

        print('   Item created: localId=${op.entityId} → serverId=$serverId');
        break;

      case 'update':
        // Get server_id (might have been set earlier in this batch)
        int? serverId = newItemIdMapping[op.entityId];
        serverId ??= await _itemsDao.getServerId(op.entityId);

        if (serverId == null) {
          throw Exception('Item ${op.entityId} has no server_id, cannot update');
        }

        final success = await _api.updateItem(
          itemId: serverId,
          name: payload['name'] as String? ?? '',
          type: payload['type'] as String? ?? '',
          description: payload['description'] as String? ?? '',
          imageUrl: payload['imageUrl'] as String?,
        );

        if (!success) throw Exception('Update failed');
        await _itemsDao.markAsSynced(op.entityId);
        break;

      case 'delete':
        // Get server_id for delete
        int? serverId = newItemIdMapping[op.entityId];
        serverId ??= await _itemsDao.getServerId(op.entityId);

        // If no server_id, item was never synced - nothing to delete
        if (serverId != null) {
          await _api.deleteItem(serverId);
        }
        break;
    }
  }

  /// Process a pending chapter operation
  Future<void> _processPendingChapterOp(
    SyncLogEntry op,
    Map<String, dynamic> payload,
    Map<int, int> newItemIdMapping,
  ) async {
    // Resolve parent item's server_id
    // Check batch mapping first (for items created in same batch)
    int? serverItemId = newItemIdMapping[op.parentId];
    serverItemId ??= await _itemsDao.getServerId(op.parentId!);

    if (serverItemId == null && op.operation != 'delete') {
      throw Exception('Parent item ${op.parentId} not synced, cannot ${op.operation} chapter');
    }

    switch (op.operation) {
      case 'create':
        final success = await _api.createChapters(serverItemId!, [payload]);
        if (!success) throw Exception('Create chapter failed');
        break;

      case 'update':
        final success = await _api.updateChapter(
          serverItemId!,
          payload['number'] as int,
          payload,
        );
        if (!success) throw Exception('Update chapter failed');
        break;

      case 'delete':
        if (serverItemId != null && payload['number'] != null) {
          await _api.deleteChapter(serverItemId, payload['number'] as int);
        }
        // If no server_id, parent was never synced - chapter never existed on server
        break;
    }
  }

  // ============================================================================
  // PULL SYNC (Server → Local)
  // ============================================================================

  /// Pull all items from server
  /// Smart merge: updates existing items, adds new ones, preserves local-only items
  /// Deletes items that were synced but no longer exist on server
  Future<SyncResult> pullItems() async {
    if (!await isOnline()) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    try {
      final serverItems = await _api.fetchItems();
      int synced = 0;
      int deleted = 0;

      // Build a set of all server item IDs for quick lookup
      final serverItemIds = serverItems.map((item) => item.id).toSet();

      for (final serverItem in serverItems) {
        // Check if we already have this item (by server_id)
        final existingByServerId = await _itemsDao.getItemByServerId(serverItem.id);

        if (existingByServerId != null) {
          // Update existing item (preserve local id)
          await _itemsDao.updateItem(existingByServerId.id, ItemsCompanion(
            name: Value(serverItem.title),
            author: Value(serverItem.author),
            authorId: serverItem.authorId != null ? Value(serverItem.authorId!) : const Value.absent(),
            type: Value(serverItem.type),
            rating: Value(serverItem.rating),
            chaptersCount: Value(serverItem.chapters),
            commentsCount: Value(serverItem.comments),
            likesCount: Value(serverItem.likes),
            isLikedByUser: Value(serverItem.isLikedByUser),
            imageUrl: Value(serverItem.imageUrl),
            description: Value(serverItem.description),
            isSynced: const Value(true),
            lastSyncedAt: Value(DateTime.now()),
          ));
        } else {
          // New item from server - use server id as local id too
          // (makes life simpler: for server-originated items, id == server_id)
          await _itemsDao.upsertItem(ItemsCompanion(
            id: Value(serverItem.id),
            serverId: Value(serverItem.id),
            name: Value(serverItem.title),
            author: Value(serverItem.author),
            authorId: serverItem.authorId != null ? Value(serverItem.authorId!) : const Value.absent(),
            type: Value(serverItem.type),
            rating: Value(serverItem.rating),
            chaptersCount: Value(serverItem.chapters),
            commentsCount: Value(serverItem.comments),
            likesCount: Value(serverItem.likes),
            isLikedByUser: Value(serverItem.isLikedByUser),
            imageUrl: Value(serverItem.imageUrl),
            description: Value(serverItem.description),
            isSynced: const Value(true),
            lastSyncedAt: Value(DateTime.now()),
          ));
        }
        synced++;
      }

      // 🔄 DELETION SYNC: Remove items that were synced but no longer exist on server
      // Get all locally synced items (those with server_id)
      final localSyncedItems = await _itemsDao.getSyncedItems();
      
      for (final localItem in localSyncedItems) {
        // If this item has a server_id but that ID is not in the server list,
        // it was deleted on another device
        if (localItem.serverId != null && !serverItemIds.contains(localItem.serverId)) {
          print('🗑️ SYNC: Deleting item "${localItem.name}" (server_id: ${localItem.serverId}) - no longer on server');
          
          // Delete chapters first (foreign key cascade should handle this, but be explicit)
          await _chaptersDao.deleteChaptersByItemId(localItem.id);
          
          // Delete the item
          await _itemsDao.deleteItem(localItem.id);
          deleted++;
        }
      }

      final message = deleted > 0 
          ? 'Pulled $synced items, deleted $deleted'
          : 'Pulled $synced items';

      return SyncResult(
        success: true,
        message: message,
        syncedCount: synced,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Pull failed: $e');
    }
  }

  /// Pull chapters for a specific item
  Future<SyncResult> pullChapters(int localItemId) async {
    if (!await isOnline()) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    try {
      // Resolve to server_id for API call
      final serverId = await _itemsDao.getServerId(localItemId);
      if (serverId == null) {
        return SyncResult(success: false, message: 'Item not synced');
      }

      final chapters = await _api.fetchChapters(serverId);

      for (final chapter in chapters) {
        await _chaptersDao.upsertChapter(ChaptersCompanion(
          itemId: Value(localItemId), // Store under LOCAL id
          number: Value(chapter.number),
          title: Value(chapter.title),
          content: Value(chapter.content),
          isDownloaded: const Value(true),
          downloadedAt: Value(DateTime.now()),
        ));
      }

      return SyncResult(
        success: true,
        message: 'Pulled ${chapters.length} chapters',
        syncedCount: chapters.length,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Pull chapters failed: $e');
    }
  }

  // ============================================================================
  // FULL SYNC
  // ============================================================================

  /// Perform full bidirectional sync: push local changes, then pull remote updates
  Future<SyncResult> fullSync() async {
    if (!await isOnline()) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    // 1. Push local changes first
    final pushResult = await pushSync();

    // 2. Pull remote items
    final pullResult = await pullItems();

    // 3. Pull chapters for server-originated items
    if (pullResult.success) {
      final allItems = await _itemsDao.getAllItems();
      for (final item in allItems) {
        // Only pull chapters for items that originated from server
        // (where local id == server_id)
        if (item.serverId != null && item.id == item.serverId) {
          await pullChapters(item.id);
        }
      }
    }

    return SyncResult(
      success: pushResult.success && pullResult.success,
      message: 'Push: ${pushResult.message}. Pull: ${pullResult.message}',
      syncedCount: pushResult.syncedCount + pullResult.syncedCount,
      failedCount: pushResult.failedCount,
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Push a new item create to server (immediate)
  Future<bool> _pushItemCreate(int localId, String name, String type, String description, String? imageUrl) async {
    try {
      final serverId = await _api.createItem(
        name: name,
        type: type,
        description: description,
        imageUrl: imageUrl,
      );

      if (serverId != null) {
        await _itemsDao.setServerId(localId, serverId);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Push item create failed: $e');
      return false;
    }
  }

  /// Push an item update to server (immediate)
  Future<bool> _pushItemUpdate(int serverId, String name, String type, String description, String? imageUrl) async {
    try {
      return await _api.updateItem(
        itemId: serverId,
        name: name,
        type: type,
        description: description,
        imageUrl: imageUrl,
      );
    } catch (e) {
      print('❌ Push item update failed: $e');
      return false;
    }
  }

  /// Push a new chapter to server (immediate)
  Future<bool> _pushChapterCreate(int serverItemId, int number, String title, String content) async {
    try {
      return await _api.createChapters(serverItemId, [
        {'number': number, 'title': title, 'content': content}
      ]);
    } catch (e) {
      print('❌ Push chapter create failed: $e');
      return false;
    }
  }

  /// Get count of pending sync operations for current user
  Future<int> getPendingSyncCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return 0;
    return _syncLogDao.getPendingCountForUser(userId);
  }

  /// Watch pending sync count for current user (reactive)
  Stream<int> watchPendingSyncCount() async* {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      yield 0;
      return;
    }
    yield* _syncLogDao.watchPendingCountForUser(userId);
  }

  /// Clear all local data
  Future<void> clearAllData() async {
    await _itemsDao.clearAllItems();
    await _userDao.clearAllUsers();
    await _syncLogDao.clearAll();
  }

  /// Clear pending sync operations (for logout - keeps cached items)
  Future<void> clearPendingOperations() async {
    await _syncLogDao.clearAll();
  }

  // ============================================================================
  // COMPATIBILITY LAYER (for existing providers)
  // These methods match the old SyncService API so providers work without changes
  // ============================================================================

  /// Alias for pushSync() - for backward compatibility
  Future<SyncResult> processSyncLog() => pushSync();

  /// Download a single chapter for an item
  Future<bool> downloadChapter(int localItemId, int chapterNumber) async {
    try {
      if (!await isOnline()) return false;
      
      final serverId = await _itemsDao.getServerId(localItemId);
      if (serverId == null) return false;
      
      final chapter = await _api.fetchChapter(serverId, chapterNumber);
      if (chapter == null) return false;

      await _chaptersDao.upsertChapter(ChaptersCompanion(
        itemId: Value(localItemId),
        number: Value(chapterNumber),
        title: Value(chapter.title),
        content: Value(chapter.content),
        isDownloaded: const Value(true),
        downloadedAt: Value(DateTime.now()),
      ));
      return true;
    } catch (e) {
      print('❌ Download chapter failed: $e');
      return false;
    }
  }

  /// Silent background sync - tries to push any pending changes
  Future<bool> backgroundSync() async {
    if (!await isOnline()) return false;
    
    final pendingCount = await getPendingSyncCount();
    if (pendingCount == 0) return true;
    
    final result = await pushSync();
    return result.success;
  }

  // ============================================================================
  // AUTO-PUSH METHODS (try immediately, fallback to sync log)
  // These are used by LiteratureProvider which handles local DB ops separately
  // ============================================================================

  /// Auto-push item create: tries server immediately, falls back to sync log
  /// Returns the local ID (never changes)
  Future<int> autoPushItemCreate(int localId, {
    required String name,
    required String type,
    required String description,
    required String author,
    int? authorId,
    String? imageUrl,
  }) async {
    print('🔄 SYNC: Auto-push item create - "$name" (localId: $localId)');
    
    if (await isOnline()) {
      final pushed = await _pushItemCreate(localId, name, type, description, imageUrl);
      if (pushed) {
        print('✅ SYNC: Item pushed to server immediately');
        return localId;
      }
    }
    
    // Offline or failed - queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logItemCreate(localId, {
      'name': name,
      'type': type,
      'description': description,
      'author': author,
      'authorId': authorId,
      'imageUrl': imageUrl,
    }, userId: userId);
    print('📋 SYNC: Item queued in sync log');
    return localId;
  }

  /// Auto-push item update
  Future<bool> autoPushItemUpdate(int localId, Map<String, dynamic> changes) async {
    print('🔄 SYNC: Auto-push item update (localId: $localId)');
    
    if (await isOnline()) {
      final serverId = await _itemsDao.getServerId(localId);
      if (serverId != null) {
        final success = await _api.updateItem(
          itemId: serverId,
          name: changes['name'] as String? ?? '',
          type: changes['type'] as String? ?? '',
          description: changes['description'] as String? ?? '',
          imageUrl: changes['imageUrl'] as String?,
        );
        if (success) {
          await _itemsDao.markAsSynced(localId);
          print('✅ SYNC: Item update pushed');
          return true;
        }
      }
    }
    
    // Offline or failed - queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logItemUpdate(localId, changes, userId: userId);
    print('📋 SYNC: Item update queued');
    return false;
  }

  /// Auto-push item delete
  Future<bool> autoPushItemDelete(int localId) async {
    print('🔄 SYNC: Auto-push item delete (localId: $localId)');
    
    final serverId = await _itemsDao.getServerId(localId);
    final userId = await _getCurrentUserId();
    
    if (serverId == null) {
      // Never synced - just clear pending operations
      await _syncLogDao.logItemDelete(localId, userId: userId);
      print('✅ SYNC: Item was never synced, no backend delete needed');
      return true;
    }
    
    if (await isOnline()) {
      final success = await _api.deleteItem(serverId);
      if (success) {
        print('✅ SYNC: Item deleted from server');
        return true;
      }
    }
    
    // Offline or failed - queue for later
    await _syncLogDao.logItemDelete(localId, userId: userId);
    print('📋 SYNC: Item delete queued');
    return false;
  }

  /// Auto-push chapter create
  Future<bool> autoPushChapterCreate(int chapterId, int localItemId, {
    required int number,
    required String title,
    required String content,
  }) async {
    print('🔄 SYNC: Auto-push chapter create (Ch.$number, localItemId: $localItemId)');
    
    if (await isOnline()) {
      final serverItemId = await _itemsDao.getServerId(localItemId);
      if (serverItemId != null) {
        final success = await _pushChapterCreate(serverItemId, number, title, content);
        if (success) {
          print('✅ SYNC: Chapter pushed');
          return true;
        }
      }
    }
    
    // Offline or parent not synced - queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logChapterCreate(chapterId, localItemId, {
      'number': number,
      'title': title,
      'content': content,
    }, userId: userId);
    print('📋 SYNC: Chapter queued');
    return false;
  }

  /// Auto-push chapter update
  Future<bool> autoPushChapterUpdate(int chapterId, int localItemId, Map<String, dynamic> changes) async {
    final chapterNum = changes['number'] ?? '?';
    print('🔄 SYNC: Auto-push chapter update (Ch.$chapterNum, localItemId: $localItemId)');
    
    if (await isOnline()) {
      final serverItemId = await _itemsDao.getServerId(localItemId);
      if (serverItemId != null) {
        final success = await _api.updateChapter(serverItemId, changes['number'] as int, changes);
        if (success) {
          print('✅ SYNC: Chapter update pushed');
          return true;
        }
      }
    }
    
    // Offline or parent not synced - queue for later
    final userId = await _getCurrentUserId();
    await _syncLogDao.logChapterUpdate(chapterId, localItemId, changes, userId: userId);
    print('📋 SYNC: Chapter update queued');
    return false;
  }

  /// Auto-push chapter delete
  Future<bool> autoPushChapterDelete(int chapterId, int localItemId, int chapterNumber) async {
    print('🔄 SYNC: Auto-push chapter delete (Ch.$chapterNumber, localItemId: $localItemId)');
    
    final serverItemId = await _itemsDao.getServerId(localItemId);
    final userId = await _getCurrentUserId();
    
    if (serverItemId == null) {
      // Parent never synced - just queue
      await _syncLogDao.logChapterDelete(chapterId, localItemId, chapterNumber, userId: userId);
      print('✅ SYNC: Parent not synced, no backend delete needed');
      return true;
    }
    
    if (await isOnline()) {
      final success = await _api.deleteChapter(serverItemId, chapterNumber);
      if (success) {
        print('✅ SYNC: Chapter deleted from server');
        return true;
      }
    }
    
    // Offline or failed - queue for later
    await _syncLogDao.logChapterDelete(chapterId, localItemId, chapterNumber, userId: userId);
    print('📋 SYNC: Chapter delete queued');
    return false;
  }

  /// Auto-push toggle like (online only - likes don't queue)
  Future<Map<String, dynamic>?> autoPushToggleLike(int localItemId) async {
    print('👍 SYNC: Toggle like (localItemId: $localItemId)');
    
    if (!await isOnline()) {
      print('📴 SYNC: Offline - like requires connection');
      return null;
    }
    
    final serverId = await _itemsDao.getServerId(localItemId);
    if (serverId == null) {
      print('⚠️ SYNC: Item not synced, cannot toggle like');
      return null;
    }
    
    try {
      final result = await _api.toggleLike(serverId);
      if (result != null) {
        print('✅ SYNC: Like toggled');
      }
      return result;
    } catch (e) {
      print('❌ SYNC: Toggle like failed - $e');
      return null;
    }
  }

  /// Auto-push add comment (online only - comments don't queue)
  Future<dynamic> autoPushAddComment(int localItemId, String content) async {
    print('💬 SYNC: Add comment (localItemId: $localItemId)');
    
    if (!await isOnline()) {
      print('📴 SYNC: Offline - comment requires connection');
      return null;
    }
    
    final serverId = await _itemsDao.getServerId(localItemId);
    if (serverId == null) {
      print('⚠️ SYNC: Item not synced, cannot add comment');
      return null;
    }
    
    try {
      final result = await _api.addComment(serverId, content);
      if (result != null) {
        print('✅ SYNC: Comment added');
      }
      return result;
    } catch (e) {
      print('❌ SYNC: Add comment failed - $e');
      return null;
    }
  }

  // ============================================================================
  // LEGACY ALIASES (for complete backward compatibility)
  // ============================================================================

  Future<SyncResult> syncItems() => pullItems();
  Future<SyncResult> downloadAllChapters(int itemId) => pullChapters(itemId);
}
