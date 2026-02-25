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
  Future<void> logChapterDelete(int chapterId, int itemId) async {
    await _syncLogDao.logChapterDelete(chapterId, itemId);
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
    if (await isOnline()) {
      try {
        final remoteId = await _api.createItem(
          name: name,
          type: type,
          description: description,
          imageUrl: imageUrl,
        );
        
        if (remoteId != null) {
          // Update local item with backend ID
          final item = await _itemsDao.getItemById(localId);
          if (item != null) {
            await _itemsDao.changeItemId(localId, remoteId, item);
            await _chaptersDao.updateChaptersItemId(localId, remoteId);
            await _itemsDao.deleteItem(localId);
          }
          return remoteId;
        }
      } catch (e) {
        // Failed - fall through to log
        print('Auto-push create failed: $e');
      }
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
    return localId;
  }

  /// Update item: try to push immediately, fallback to sync log
  Future<bool> autoPushItemUpdate(int itemId, Map<String, dynamic> changes) async {
    if (await isOnline()) {
      try {
        final success = await _api.updateItem(
          itemId: itemId,
          name: changes['name'] as String? ?? '',
          type: changes['type'] as String? ?? '',
          description: changes['description'] as String? ?? '',
          imageUrl: changes['imageUrl'] as String?,
        );
        
        if (success) {
          await _itemsDao.markAsSynced(itemId);
          return true;
        }
      } catch (e) {
        print('Auto-push update failed: $e');
      }
    }
    
    // Offline or failed - log for later
    await logItemUpdate(itemId, changes);
    return false;
  }

  /// Delete item: try to push immediately, fallback to sync log
  Future<bool> autoPushItemDelete(int itemId) async {
    if (await isOnline()) {
      try {
        final success = await _api.deleteItem(itemId);
        if (success) return true;
      } catch (e) {
        print('Auto-push delete failed: $e');
      }
    }
    
    // Offline or failed - log for later
    await logItemDelete(itemId);
    return false;
  }

  /// Create chapter: try to push immediately, fallback to sync log
  Future<bool> autoPushChapterCreate(int chapterId, int itemId, {
    required int number,
    required String title,
    required String content,
  }) async {
    if (await isOnline()) {
      try {
        final success = await _api.createChapters(itemId, [
          {'number': number, 'title': title, 'content': content}
        ]);
        if (success) return true;
      } catch (e) {
        print('Auto-push chapter create failed: $e');
      }
    }
    
    // Offline or failed - log for later
    await logChapterCreate(chapterId, itemId,
      number: number,
      title: title,
      content: content,
    );
    return false;
  }

  /// Update chapter: try to push immediately, fallback to sync log
  Future<bool> autoPushChapterUpdate(int chapterId, int itemId, Map<String, dynamic> changes) async {
    if (await isOnline()) {
      try {
        final success = await _api.updateChapter(itemId, changes['number'] as int, changes);
        if (success) return true;
      } catch (e) {
        print('Auto-push chapter update failed: $e');
      }
    }
    
    // Offline or failed - log for later
    await logChapterUpdate(chapterId, itemId, changes);
    return false;
  }

  /// Delete chapter: try to push immediately, fallback to sync log
  Future<bool> autoPushChapterDelete(int chapterId, int itemId, int chapterNumber) async {
    if (await isOnline()) {
      try {
        final success = await _api.deleteChapter(itemId, chapterNumber);
        if (success) return true;
      } catch (e) {
        print('Auto-push chapter delete failed: $e');
      }
    }
    
    // Offline or failed - log for later
    await logChapterDelete(chapterId, itemId);
    return false;
  }

  /// Toggle like: try immediately, no fallback (likes are always online)
  Future<Map<String, dynamic>?> autoPushToggleLike(int itemId) async {
    if (!await isOnline()) return null;
    return await _api.toggleLike(itemId);
  }

  /// Add comment: try immediately, no fallback (comments are always online)
  Future<dynamic> autoPushAddComment(int itemId, String content) async {
    if (!await isOnline()) return null;
    return await _api.addComment(itemId, content);
  }

  // ==================== SYNC OPERATIONS ====================

  /// Get count of pending sync operations
  Future<int> getPendingSyncCount() => _syncLogDao.getPendingCount();

  /// Watch pending sync count (reactive)
  Stream<int> watchPendingSyncCount() => _syncLogDao.watchPendingCount();

  /// Process all pending sync operations
  Future<SyncResult> processSyncLog() async {
    if (!await isOnline()) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    final operations = await _syncLogDao.getPendingOperations();
    
    if (operations.isEmpty) {
      return SyncResult(success: true, message: 'Nothing to sync', itemCount: 0);
    }

    int successCount = 0;
    int failCount = 0;
    
    // Track local ID -> remote ID mappings for new items
    final Map<int, int> itemIdMapping = {};

    for (final op in operations) {
      try {
        final payload = jsonDecode(op.payload) as Map<String, dynamic>;
        
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
        
      } catch (e) {
        // Failed - mark as attempted with error
        await _syncLogDao.markAttempted(op.id, e.toString());
        failCount++;
      }
    }

    return SyncResult(
      success: failCount == 0,
      message: 'Synced $successCount operations, $failCount failed',
      itemCount: successCount,
    );
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
          // Store mapping for chapter operations
          itemIdMapping[op.entityId] = remoteId;
          
          // Update local item with backend ID
          await _itemsDao.changeItemId(op.entityId, remoteId, 
            await _itemsDao.getItemById(op.entityId) as ItemEntity);
          await _chaptersDao.updateChaptersItemId(op.entityId, remoteId);
          await _itemsDao.deleteItem(op.entityId);
        } else {
          throw Exception('Backend returned null ID');
        }
        break;
        
      case 'update':
        final success = await _api.updateItem(
          itemId: op.entityId,
          name: payload['name'] as String? ?? '',
          type: payload['type'] as String? ?? '',
          description: payload['description'] as String? ?? '',
          imageUrl: payload['imageUrl'] as String?,
        );
        if (!success) throw Exception('Update failed');
        
        // Mark local item as synced
        await _itemsDao.markAsSynced(op.entityId);
        break;
        
      case 'delete':
        await _api.deleteItem(op.entityId);
        break;
    }
  }

  Future<void> _processChapterOperation(
    SyncLogEntry op, 
    Map<String, dynamic> payload,
    Map<int, int> itemIdMapping,
  ) async {
    // Resolve the actual item ID (might have been remapped)
    final actualItemId = itemIdMapping[op.parentId] ?? op.parentId!;
    
    switch (op.operation) {
      case 'create':
        final success = await _api.createChapters(actualItemId, [payload]);
        if (!success) throw Exception('Create chapter failed');
        
        // Update chapter count on backend item
        // (Backend should handle this automatically, but we update locally)
        final item = await _itemsDao.getItemById(actualItemId);
        if (item != null) {
          await _itemsDao.updateItem(actualItemId, ItemsCompanion(
            chaptersCount: Value(item.chaptersCount + 1),
          ));
        }
        break;
        
      case 'update':
        final success = await _api.updateChapter(
          actualItemId,
          payload['number'] as int,
          payload,
        );
        if (!success) throw Exception('Update chapter failed');
        break;
        
      case 'delete':
        final success = await _api.deleteChapter(actualItemId, payload['number'] as int);
        if (!success) throw Exception('Delete chapter failed');
        
        // Update chapter count locally
        final item = await _itemsDao.getItemById(actualItemId);
        if (item != null && item.chaptersCount > 0) {
          await _itemsDao.updateItem(actualItemId, ItemsCompanion(
            chaptersCount: Value(item.chaptersCount - 1),
          ));
        }
        break;
    }
  }

  // ==================== PULL FROM BACKEND ====================

  /// Pull all items from backend to local DB
  Future<SyncResult> pullItems() async {
    try {
      if (!await isOnline()) {
        return SyncResult(success: false, message: 'No internet connection');
      }

      final items = await _api.fetchItems();

      final companions = items.map((item) {
        return ItemsCompanion(
          id: Value(item.id),
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
        );
      }).toList();

      await _itemsDao.insertItems(companions);

      return SyncResult(
        success: true,
        message: 'Pulled ${items.length} items',
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

      final chapters = await _api.fetchChapters(itemId);
      
      if (chapters.isEmpty) {
        return SyncResult(success: true, message: 'No chapters', itemCount: 0);
      }

      final companions = chapters.map((chapter) {
        return ChaptersCompanion(
          itemId: Value(itemId),
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

    // 3. Pull chapters for all items
    if (pullResult.success) {
      final items = await _itemsDao.getAllItems();
      for (final item in items) {
        await pullChapters(item.id);
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
      final chapter = await _api.fetchChapter(itemId, chapterNumber);
      if (chapter == null) return false;

      await _chaptersDao.upsertChapter(ChaptersCompanion(
        itemId: Value(itemId),
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
