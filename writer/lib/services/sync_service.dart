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

/// Sync Service using Change Log Pattern
/// 
/// Instead of marking items as "unsynced", we log each operation (create/update/delete)
/// and process them in order when the user clicks sync.
class SyncService {
  final AppDatabase _db;
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  late final ItemsDao _itemsDao;
  late final ChaptersDao _chaptersDao;
  late final UserDao _userDao;
  late final SyncLogDao _syncLogDao;

  SyncService(this._db) {
    _itemsDao = ItemsDao(_db);
    _chaptersDao = ChaptersDao(_db);
    _userDao = UserDao(_db);
    _syncLogDao = SyncLogDao(_db);
  }

  // ==================== CONNECTIVITY ====================
  
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // ==================== CHANGE LOGGING ====================
  
  /// Log creation of a new item (to be synced later)
  Future<void> logItemCreate(int localId, {
    required String name,
    required String type,
    required String description,
    required String author,
    int? authorId,
    String? imageUrl,
  }) async {
    await _syncLogDao.logItemCreate(localId, {
      'name': name,
      'type': type,
      'description': description,
      'author': author,
      'authorId': authorId,
      'imageUrl': imageUrl,
    });
  }

  /// Log update of an existing item
  Future<void> logItemUpdate(int itemId, Map<String, dynamic> changes) async {
    await _syncLogDao.logItemUpdate(itemId, changes);
  }

  /// Log deletion of an item
  Future<void> logItemDelete(int itemId) async {
    await _syncLogDao.logItemDelete(itemId);
  }

  /// Log creation of a new chapter
  Future<void> logChapterCreate(int chapterId, int itemId, {
    required int number,
    required String title,
    required String content,
  }) async {
    await _syncLogDao.logChapterCreate(chapterId, itemId, {
      'number': number,
      'title': title,
      'content': content,
    });
  }

  /// Log update of a chapter
  Future<void> logChapterUpdate(int chapterId, int itemId, Map<String, dynamic> changes) async {
    await _syncLogDao.logChapterUpdate(chapterId, itemId, changes);
  }

  /// Log deletion of a chapter
  Future<void> logChapterDelete(int chapterId, int itemId, int chapterNumber) async {
    await _syncLogDao.logChapterDelete(chapterId, itemId, chapterNumber);
  }

  // ==================== AUTO-PUSH (Try immediately, fallback to log) ====================

  /// Create item: try to push immediately, fallback to sync log
  /// Returns the actual item ID (remote if synced, local if queued)
  Future<int> autoPushItemCreate(int localId, {
    required String name,
    required String type,
    required String description,
    required String author,
    int? authorId,
    String? imageUrl,
  }) async {
    print('🔄 SYNC: Starting item create - "$name" (localId: $localId)');
    if (await isOnline()) {
      try {
        print('📡 SYNC: Online - pushing item to backend...');
        final remoteId = await _api.createItem(
          name: name,
          type: type,
          description: description,
          imageUrl: imageUrl,
        );
        
        if (remoteId != null) {
          // Store serverId on the local item — local id stays the same forever.
          // This avoids the duplicate-item bug caused by the old key-swap approach.
          await _itemsDao.setServerId(localId, remoteId);
          print('✅ SYNC SUCCESS: Item created on backend (localId: $localId → serverId: $remoteId)');
          return localId; // Always return local ID (never changes)
        } else {
          print('❌ SYNC FAILED: Backend returned null remoteId');
        }
      } catch (e) {
        // Failed - fall through to log
        print('❌ SYNC ERROR: Item create failed - $e');
      }
    } else {
      print('📴 SYNC: Offline - queueing for later');
    }
    
    // Offline or failed - log for later
    await logItemCreate(localId,
      name: name,
      type: type,
      description: description,
      author: author,
      authorId: authorId,
      imageUrl: imageUrl,
    );
    print('📝 SYNC: Item create queued in sync log (localId: $localId)');
    return localId;
  }

  /// Update item: try to push immediately, fallback to sync log
  Future<bool> autoPushItemUpdate(int localId, Map<String, dynamic> changes) async {
    print('🔄 SYNC: Starting item update (localId: $localId) - ${changes.keys.join(", ")}');
    if (await isOnline()) {
      try {
        final serverId = await _itemsDao.getServerId(localId);
        if (serverId == null) {
          print('⚠️ SYNC: Item $localId not synced yet, queueing update');
        } else {
          print('📡 SYNC: Online - pushing update to backend (serverId: $serverId)...');
          final success = await _api.updateItem(
            itemId: serverId,
            name: changes['name'] as String? ?? '',
            type: changes['type'] as String? ?? '',
            description: changes['description'] as String? ?? '',
            imageUrl: changes['imageUrl'] as String?,
          );
          if (success) {
            await _itemsDao.markAsSynced(localId);
            print('✅ SYNC SUCCESS: Item updated on backend (serverId: $serverId)');
            return true;
          } else {
            print('❌ SYNC FAILED: Backend returned false');
          }
        }
      } catch (e) {
        print('❌ SYNC ERROR: Item update failed - $e');
      }
    } else {
      print('📴 SYNC: Offline - queueing for later');
    }
    
    // Offline or failed - log for later
    await logItemUpdate(localId, changes);
    print('📝 SYNC: Item update queued in sync log (localId: $localId)');
    return false;
  }

  /// Delete item: try to push immediately, fallback to sync log
  Future<bool> autoPushItemDelete(int localId) async {
    print('🔄 SYNC: Starting item delete (localId: $localId)');
    if (await isOnline()) {
      try {
        final serverId = await _itemsDao.getServerId(localId);
        if (serverId == null) {
          print('⚠️ SYNC: Item $localId not synced, skipping backend delete');
          return true; // Nothing to delete on backend
        }
        print('📡 SYNC: Online - pushing delete to backend (serverId: $serverId)...');
        final success = await _api.deleteItem(serverId);
        if (success) {
          print('✅ SYNC SUCCESS: Item deleted on backend (serverId: $serverId)');
          return true;
        } else {
          print('❌ SYNC FAILED: Backend returned false');
        }
      } catch (e) {
        print('❌ SYNC ERROR: Item delete failed - $e');
      }
    } else {
      print('📴 SYNC: Offline - queueing for later');
    }
    
    // Offline or failed - log for later
    await logItemDelete(localId);
    print('📝 SYNC: Item delete queued in sync log (localId: $localId)');
    return false;
  }

  /// Create chapter: try to push immediately, fallback to sync log
  Future<bool> autoPushChapterCreate(int chapterId, int localItemId, {
    required int number,
    required String title,
    required String content,
  }) async {
    print('🔄 SYNC: Starting chapter create - "$title" (Ch.$number, localItemId: $localItemId)');
    if (await isOnline()) {
      try {
        final serverItemId = await _itemsDao.getServerId(localItemId);
        if (serverItemId == null) {
          print('⚠️ SYNC: Parent item $localItemId not synced yet, queueing chapter');
        } else {
          print('📡 SYNC: Online - pushing chapter to backend (serverItemId: $serverItemId)...');
          final success = await _api.createChapters(serverItemId, [
            {'number': number, 'title': title, 'content': content}
          ]);
          if (success) {
            print('✅ SYNC SUCCESS: Chapter created on backend (Ch.$number)');
            return true;
          } else {
            print('❌ SYNC FAILED: Backend returned false');
          }
        }
      } catch (e) {
        print('❌ SYNC ERROR: Chapter create failed - $e');
      }
    } else {
      print('📴 SYNC: Offline - queueing for later');
    }
    
    // Offline or failed - log for later
    await logChapterCreate(chapterId, localItemId,
      number: number,
      title: title,
      content: content,
    );
    print('📝 SYNC: Chapter create queued in sync log (Ch.$number)');
    return false;
  }

  /// Update chapter: try to push immediately, fallback to sync log
  Future<bool> autoPushChapterUpdate(int chapterId, int localItemId, Map<String, dynamic> changes) async {
    final chapterNum = changes['number'] ?? '?';
    print('🔄 SYNC: Starting chapter update (Ch.$chapterNum, localItemId: $localItemId)');
    if (await isOnline()) {
      try {
        final serverItemId = await _itemsDao.getServerId(localItemId);
        if (serverItemId == null) {
          print('⚠️ SYNC: Parent item $localItemId not synced yet, queueing chapter update');
        } else {
          print('📡 SYNC: Online - pushing chapter update to backend (serverItemId: $serverItemId)...');
          final success = await _api.updateChapter(serverItemId, changes['number'] as int, changes);
          if (success) {
            print('✅ SYNC SUCCESS: Chapter updated on backend (Ch.$chapterNum)');
            return true;
          } else {
            print('❌ SYNC FAILED: Backend returned false');
          }
        }
      } catch (e) {
        print('❌ SYNC ERROR: Chapter update failed - $e');
      }
    } else {
      print('📴 SYNC: Offline - queueing for later');
    }
    
    // Offline or failed - log for later
    await logChapterUpdate(chapterId, localItemId, changes);
    print('📝 SYNC: Chapter update queued in sync log (Ch.$chapterNum)');
    return false;
  }

  /// Delete chapter: try to push immediately, fallback to sync log
  Future<bool> autoPushChapterDelete(int chapterId, int localItemId, int chapterNumber) async {
    print('🔄 SYNC: Starting chapter delete (Ch.$chapterNumber, localItemId: $localItemId)');
    if (await isOnline()) {
      try {
        final serverItemId = await _itemsDao.getServerId(localItemId);
        if (serverItemId == null) {
          // Item has never been synced so there is nothing on the backend to
          // delete. Queue anyway in case the item gets synced later.
          print('⚠️ SYNC: Parent item $localItemId not synced yet, queueing chapter delete');
        } else {
          print('📡 SYNC: Online - pushing chapter delete to backend (serverItemId: $serverItemId)...');
          final success = await _api.deleteChapter(serverItemId, chapterNumber);
          if (success) {
            print('✅ SYNC SUCCESS: Chapter deleted on backend (Ch.$chapterNumber)');
            return true;
          } else {
            print('❌ SYNC FAILED: Backend returned false');
          }
        }
      } catch (e) {
        print('❌ SYNC ERROR: Chapter delete failed - $e');
      }
    } else {
      print('📴 SYNC: Offline - queueing for later');
    }
    
    // Offline or failed - log for later (include chapter number so sync replay works)
    await logChapterDelete(chapterId, localItemId, chapterNumber);
    print('📝 SYNC: Chapter delete queued in sync log (Ch.$chapterNumber)');
    return false;
  }

  /// Toggle like: try immediately, no fallback (likes are always online)
  Future<Map<String, dynamic>?> autoPushToggleLike(int localItemId) async {
    print('👍 SYNC: Toggle like (localItemId: $localItemId)');
    if (!await isOnline()) {
      print('📴 SYNC: Offline - like operation requires connection');
      return null;
    }
    try {
      final serverId = await _itemsDao.getServerId(localItemId);
      if (serverId == null) {
        print('⚠️ SYNC: Item $localItemId not synced, cannot toggle like');
        return null;
      }
      final result = await _api.toggleLike(serverId);
      if (result != null) {
        print('✅ SYNC SUCCESS: Like toggled on backend (serverId: $serverId)');
      } else {
        print('❌ SYNC FAILED: Toggle like returned null');
      }
      return result;
    } catch (e) {
      print('❌ SYNC ERROR: Toggle like failed - $e');
      return null;
    }
  }

  /// Add comment: try immediately, no fallback (comments are always online)
  Future<dynamic> autoPushAddComment(int localItemId, String content) async {
    print('💬 SYNC: Adding comment (localItemId: $localItemId)');
    if (!await isOnline()) {
      print('📴 SYNC: Offline - comment operation requires connection');
      return null;
    }
    try {
      final serverId = await _itemsDao.getServerId(localItemId);
      if (serverId == null) {
        print('⚠️ SYNC: Item $localItemId not synced, cannot add comment');
        return null;
      }
      final result = await _api.addComment(serverId, content);
      if (result != null) {
        print('✅ SYNC SUCCESS: Comment added on backend (serverId: $serverId)');
      } else {
        print('❌ SYNC FAILED: Add comment returned null');
      }
      return result;
    } catch (e) {
      print('❌ SYNC ERROR: Add comment failed - $e');
      return null;
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Get count of pending sync operations
  Future<int> getPendingSyncCount() => _syncLogDao.getPendingCount();

  /// Watch pending sync count (reactive)
  Stream<int> watchPendingSyncCount() => _syncLogDao.watchPendingCount();

  /// Process all pending sync operations
  Future<SyncResult> processSyncLog() async {
    print('🔄 PUSH SYNC: Starting to process sync log...');
    
    if (!await isOnline()) {
      print('📴 PUSH SYNC: No internet connection');
      return SyncResult(success: false, message: 'No internet connection');
    }

    final operations = await _syncLogDao.getPendingOperations();
    
    if (operations.isEmpty) {
      print('✅ PUSH SYNC: Nothing to sync');
      return SyncResult(success: true, message: 'Nothing to sync', itemCount: 0);
    }

    print('📋 PUSH SYNC: Found ${operations.length} pending operations');
    
    int successCount = 0;
    int failCount = 0;
    
    // Track local ID -> remote ID mappings for new items
    final Map<int, int> itemIdMapping = {};

    for (final op in operations) {
      try {
        final payload = jsonDecode(op.payload) as Map<String, dynamic>;
        print('🔄 PUSH SYNC: Processing ${op.entityType} ${op.operation} (id: ${op.entityId})');
        
        switch (op.entityType) {
          case 'item':
            await _processItemOperation(op, payload, itemIdMapping);
            break;
          case 'chapter':
            await _processChapterOperation(op, payload, itemIdMapping);
            break;
        }
        
        // Success - remove from log
        await _syncLogDao.removeOperation(op.id);
        successCount++;
        print('✅ PUSH SYNC: Operation completed successfully');
        
      } catch (e) {
        print('❌ PUSH SYNC: Operation failed - $e');
        print('   Entity: ${op.entityType}, Operation: ${op.operation}, EntityId: ${op.entityId}');
        print('   Payload: ${op.payload}');
        // Failed - mark as attempted with error
        await _syncLogDao.markAttempted(op.id, e.toString());
        failCount++;
      }
    }

    final result = SyncResult(
      success: failCount == 0,
      message: 'Synced $successCount operations, $failCount failed',
      itemCount: successCount,
    );
    
    print('📊 PUSH SYNC: Complete - $successCount succeeded, $failCount failed');
    return result;
  }

  Future<void> _processItemOperation(
    SyncLogEntry op, 
    Map<String, dynamic> payload,
    Map<int, int> itemIdMapping,
  ) async {
    switch (op.operation) {
      case 'create':
        // Create new item on backend
        final remoteId = await _api.createItem(
          name: payload['name'] as String,
          type: payload['type'] as String,
          description: payload['description'] as String? ?? '',
          imageUrl: payload['imageUrl'] as String?,
        );
        if (remoteId != null) {
          // Store serverId on local item — local id never changes
          await _itemsDao.setServerId(op.entityId, remoteId);
          // Track localId→serverId for chapter operations in this batch
          itemIdMapping[op.entityId] = remoteId;
          print('   ✅ Item serverId set: localId=${op.entityId} → serverId=$remoteId');
        } else {
          throw Exception('Backend returned null ID');
        }
        break;
        
      case 'update':
        final serverId = await _itemsDao.getServerId(op.entityId);
        if (serverId == null) throw Exception('Item ${op.entityId} not synced, cannot update');
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
        final serverIdForDelete = await _itemsDao.getServerId(op.entityId);
        if (serverIdForDelete != null) await _api.deleteItem(serverIdForDelete);
        break;
    }
  }

  Future<void> _processChapterOperation(
    SyncLogEntry op, 
    Map<String, dynamic> payload,
    Map<int, int> itemIdMapping,
  ) async {
    // Resolve the backend server ID for the parent item.
    // If this batch just created the item, use the itemIdMapping; otherwise look up serverId.
    int actualServerId;
    if (itemIdMapping.containsKey(op.parentId)) {
      actualServerId = itemIdMapping[op.parentId]!;
    } else {
      final serverId = await _itemsDao.getServerId(op.parentId!);
      if (serverId == null) {
        throw Exception('Parent item ${op.parentId} not yet synced to backend');
      }
      actualServerId = serverId;
    }
    print('   Chapter operation: ${op.operation}, serverItemId: $actualServerId (localParent: ${op.parentId}), payload: $payload');
    
    switch (op.operation) {
      case 'create':
        print('   Creating chapter on backend (serverItemId: $actualServerId)...');
        final success = await _api.createChapters(actualServerId, [payload]);
        if (!success) throw Exception('Create chapter failed');
        print('   Chapter created successfully');
        break;
        
      case 'update':
        print('   Updating chapter on backend (serverItemId: $actualServerId)...');
        final updateSuccess = await _api.updateChapter(
          actualServerId,
          payload['number'] as int,
          payload,
        );
        if (!updateSuccess) throw Exception('Update chapter failed');
        print('   Chapter updated successfully');
        break;
        
      case 'delete':
        print('   Deleting chapter on backend (serverItemId: $actualServerId)...');
        // Guard against old log entries that were saved with an empty payload
        // before the chapter-number fix was introduced.
        final chapterNumRaw = payload['number'];
        if (chapterNumRaw == null) {
          print('   ⚠️ Chapter delete log entry has no number in payload – skipping (stale entry)');
          break;
        }
        final deleteSuccess = await _api.deleteChapter(actualServerId, chapterNumRaw as int);
        if (!deleteSuccess) throw Exception('Delete chapter failed');
        print('   Chapter deleted successfully');
        break;
    }
  }

  // ==================== PULL FROM BACKEND ====================

  /// Pull all items from backend to local DB
  /// Deletes items that were synced but no longer exist on server
  Future<SyncResult> pullItems() async {
    try {
      if (!await isOnline()) {
        return SyncResult(success: false, message: 'No internet connection');
      }

      final items = await _api.fetchItems();
      int deleted = 0;

      // Build a set of all server item IDs for quick lookup
      final serverItemIds = items.map((item) => item.id).toSet();

      // Smart deduplication: if we already have this backend item as a locally-created
      // and synced item (serverId matches), update it in place instead of creating a duplicate.
      for (final item in items) {
        final existingByServerId = await _itemsDao.getItemByServerId(item.id);
        if (existingByServerId != null) {
          // Locally-created item already synced — update its data from backend
          await _itemsDao.updateItem(existingByServerId.id, ItemsCompanion(
            name: Value(item.title),
            author: Value(item.author),
            authorId: item.authorId != null ? Value(item.authorId!) : const Value.absent(),
            type: Value(item.type),
            rating: Value(item.rating),
            chaptersCount: Value(item.chapters),
            commentsCount: Value(item.comments),
            likesCount: Value(item.likes),
            isLikedByUser: Value(item.isLikedByUser),
            imageUrl: Value(item.imageUrl),
            description: Value(item.description),
            serverId: Value(item.id),
            isSynced: const Value(true),
            lastSyncedAt: Value(DateTime.now()),
          ));
        } else {
          // Backend-originated item — store with backend ID as local ID
          await _itemsDao.upsertItem(ItemsCompanion(
            id: Value(item.id),
            serverId: Value(item.id), // For pulled items localId == serverId
            name: Value(item.title),
            author: Value(item.author),
            authorId: item.authorId != null ? Value(item.authorId!) : const Value.absent(),
            type: Value(item.type),
            rating: Value(item.rating),
            chaptersCount: Value(item.chapters),
            commentsCount: Value(item.comments),
            likesCount: Value(item.likes),
            isLikedByUser: Value(item.isLikedByUser),
            imageUrl: Value(item.imageUrl),
            description: Value(item.description),
            isSynced: const Value(true),
            lastSyncedAt: Value(DateTime.now()),
          ));
        }
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
          ? 'Pulled ${items.length} items, deleted $deleted'
          : 'Pulled ${items.length} items';

      return SyncResult(
        success: true,
        message: message,
        itemCount: items.length,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Pull failed: $e');
    }
  }

  /// Pull all chapters for an item
  Future<SyncResult> pullChapters(int itemId) async {
    try {
      if (!await isOnline()) {
        return SyncResult(success: false, message: 'No internet connection');
      }

      // Resolve to backend server ID so the API call uses the correct ID.
      // For backend-originated items localId == serverId, so the fallback is safe.
      final serverItemId = await _itemsDao.getServerId(itemId) ?? itemId;
      final chapters = await _api.fetchChapters(serverItemId);
      
      if (chapters.isEmpty) {
        return SyncResult(success: true, message: 'No chapters', itemCount: 0);
      }

      final companions = chapters.map((chapter) {
        return ChaptersCompanion(
          itemId: Value(itemId), // always store under the local ID
          number: Value(chapter.number),
          title: Value(chapter.title),
          content: Value(chapter.content),
          isDownloaded: const Value(true),
          downloadedAt: Value(DateTime.now()),
        );
      }).toList();

      await _chaptersDao.insertChapters(companions);

      return SyncResult(
        success: true,
        message: 'Pulled ${chapters.length} chapters',
        itemCount: chapters.length,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Pull chapters failed: $e');
    }
  }

  /// Full sync: Push local changes, then pull remote
  Future<SyncResult> fullSync() async {
    if (!await isOnline()) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    // 1. Push local changes (process sync log)
    final pushResult = await processSyncLog();
    
    // 2. Pull remote items
    final pullResult = await pullItems();

    // 3. Pull chapters only for backend-originated items (where localId == serverId).
    // Locally-created items already have their chapters stored locally.
    if (pullResult.success) {
      final items = await _itemsDao.getAllItems();
      for (final item in items) {
        if (item.serverId != null && item.id == item.serverId) {
          await pullChapters(item.id); // item.id is the server ID for these items
        }
      }
    }

    return SyncResult(
      success: pushResult.success && pullResult.success,
      message: 'Push: ${pushResult.message}. Pull: ${pullResult.message}',
      itemCount: (pushResult.itemCount ?? 0) + (pullResult.itemCount ?? 0),
    );
  }

  // ==================== LEGACY METHODS (for compatibility) ====================

  Future<SyncResult> syncItems() => pullItems();
  Future<SyncResult> downloadAllChapters(int itemId) => pullChapters(itemId);
  
  Future<bool> downloadChapter(int itemId, int chapterNumber) async {
    try {
      if (!await isOnline()) return false;
      // For locally-created items localId != serverId. Always resolve to the
      // backend ID before hitting the API; fall back to itemId for backend-
      // originated items where localId == serverId.
      final serverItemId = await _itemsDao.getServerId(itemId) ?? itemId;
      final chapter = await _api.fetchChapter(serverItemId, chapterNumber);
      if (chapter == null) return false;

      await _chaptersDao.upsertChapter(ChaptersCompanion(
        itemId: Value(itemId), // always store under the local ID
        number: Value(chapterNumber),
        title: Value(chapter.title),
        content: Value(chapter.content),
        isDownloaded: const Value(true),
        downloadedAt: Value(DateTime.now()),
      ));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncUserProfile(int userId) async {
    try {
      if (!await isOnline()) return false;
      final user = await _api.fetchUserProfile(userId);
      if (user == null) return false;

      await _userDao.upsertUser(UsersCompanion(
        id: Value(user.id),
        name: Value(user.name),
        username: Value(user.username),
        email: Value(user.email),
        bio: Value(user.bio),
        followers: Value(user.followers),
        following: Value(user.following),
        posts: Value(user.posts),
      ));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearAllData() async {
    await _itemsDao.clearAllItems();
    await _userDao.clearAllUsers();
    await _syncLogDao.clearAll();
  }

  // ==================== BACKGROUND SYNC ====================

  /// Silent background sync - tries to push any pending changes
  /// Returns true if all pending operations were synced successfully
  Future<bool> backgroundSync() async {
    if (!await isOnline()) return false;
    
    final pendingCount = await getPendingSyncCount();
    if (pendingCount == 0) return true;
    
    final result = await processSyncLog();
    return result.success;
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int? itemCount;

  SyncResult({
    required this.success,
    required this.message,
    this.itemCount,
  });

  @override
  String toString() => 'SyncResult(success: $success, message: $message, itemCount: $itemCount)';
}
