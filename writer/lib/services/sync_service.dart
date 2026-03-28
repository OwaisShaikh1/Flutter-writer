import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/items_dao.dart';
import '../database/dao/chapters_dao.dart';
import 'api_service.dart';

/// Simplified Sync Service - Direct API calls
/// 
/// Handles:
/// - Pull: Fetching items/chapters from server
/// - Push: Direct CRUD operations to server (no offline queue)
class SyncService {
  final AppDatabase _db;
  final ApiService _api = ApiService();
  late final ItemsDao _itemsDao;
  late final ChaptersDao _chaptersDao;

  SyncService(this._db) {
    _itemsDao = ItemsDao(_db);
    _chaptersDao = ChaptersDao(_db);
  }

  // ==================== CONNECTIVITY ====================
  
  Future<bool> isOnline() async {
    try {
      final dynamic result = await Connectivity().checkConnectivity();

      // Handle both List<ConnectivityResult> (newer API) and single ConnectivityResult (older API)
      if (result is List) {
        return result.isNotEmpty && !result.contains(ConnectivityResult.none);
      }

      return result != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  // ==================== PULL FROM BACKEND ====================

  /// Pull all items (metadata) from backend to local DB
  Future<SyncResult> pullItems() async {
    try {
      if (!await isOnline()) {
        return SyncResult(success: false, message: 'No internet connection');
      }

      print('📥 SYNC: Pulling items from server...');
      final items = await _api.fetchItems();

      for (final item in items) {
        await _itemsDao.upsertItem(ItemsCompanion(
          id: Value(item.id),
          serverId: Value(item.id),
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
          version: Value(item.version),
        ));
      }

      print('✅ SYNC: Pulled ${items.length} items');
      return SyncResult(
        success: true,
        message: 'Pulled ${items.length} items',
        itemCount: items.length,
      );
    } catch (e) {
      print('❌ SYNC: Pull failed - $e');
      return SyncResult(success: false, message: 'Pull failed: $e');
    }
  }

  /// Pull all chapters for an item (for reading)
  Future<SyncResult> pullChapters(int itemId) async {
    print('📥 SYNC: pullChapters called for item $itemId');
    try {
      final online = await isOnline();
      print('📥 SYNC: isOnline returned: $online');
      if (!online) {
        return SyncResult(success: false, message: 'No internet connection');
      }

      print('📥 SYNC: Pulling chapters for item $itemId...');
      final chapters = await _api.fetchChapters(itemId);
      
      // Get existing local chapters to find ones that should be deleted
      final localChapters = await _chaptersDao.getChaptersByItemId(itemId);
      final serverChapterNumbers = chapters.map((c) => c.number).toSet();
      
      // Delete local chapters that no longer exist on server
      for (final localChapter in localChapters) {
        if (!serverChapterNumbers.contains(localChapter.number)) {
          print('🗑️ SYNC: Deleting local chapter ${localChapter.number} (removed from server)');
          await _chaptersDao.deleteChapter(itemId, localChapter.number);
        }
      }
      
      if (chapters.isEmpty) {
        print('📥 SYNC: No chapters found on server');
        return SyncResult(success: true, message: 'No chapters', itemCount: 0);
      }

      for (final chapter in chapters) {
        await _chaptersDao.upsertChapter(ChaptersCompanion(
          itemId: Value(itemId),
          number: Value(chapter.number),
          title: Value(chapter.title),
          content: Value(chapter.content),
          isDownloaded: const Value(true),
          downloadedAt: Value(DateTime.now()),
        ));
      }

      print('✅ SYNC: Pulled ${chapters.length} chapters');
      return SyncResult(
        success: true,
        message: 'Pulled ${chapters.length} chapters',
        itemCount: chapters.length,
      );
    } catch (e) {
      print('❌ SYNC: Pull chapters failed - $e');
      return SyncResult(success: false, message: 'Pull chapters failed: $e');
    }
  }

  /// Download a single chapter (lazy loading for reading)
  Future<bool> downloadChapter(int itemId, int chapterNumber) async {
    try {
      if (!await isOnline()) return false;
      
      print('📥 SYNC: Downloading chapter $chapterNumber for item $itemId...');
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
      
      print('✅ SYNC: Downloaded chapter $chapterNumber');
      return true;
    } catch (e) {
      print('❌ SYNC: Download chapter failed - $e');
      return false;
    }
  }

  // ==================== PUSH TO BACKEND (Direct API calls) ====================

  /// Create item on server, then store locally
  /// Returns the server-assigned ID, or null on failure
  Future<int?> createItem({
    required String name,
    required String type,
    required String description,
    String? imageUrl,
  }) async {
    if (!await isOnline()) {
      print('❌ CREATE: No internet connection');
      return null;
    }

    try {
      print('📤 CREATE: Pushing item "$name" to server...');
      final serverId = await _api.createItem(
        name: name,
        type: type,
        description: description,
        imageUrl: imageUrl,
      );
      
      if (serverId != null) {
        print('✅ CREATE: Item created on server with ID $serverId');
        return serverId;
      }
      print('❌ CREATE: Server returned null');
      return null;
    } catch (e) {
      print('❌ CREATE: Failed - $e');
      return null;
    }
  }

  /// Update item on server
  Future<bool> updateItem({
    required int itemId,
    required String name,
    required String type,
    required String description,
    String? imageUrl,
  }) async {
    if (!await isOnline()) {
      print('❌ UPDATE: No internet connection');
      return false;
    }

    try {
      print('📤 UPDATE: Pushing item $itemId to server...');
      final success = await _api.updateItem(
        itemId: itemId,
        name: name,
        type: type,
        description: description,
        imageUrl: imageUrl,
      );
      
      if (success) {
        print('✅ UPDATE: Item updated on server');
      } else {
        print('❌ UPDATE: Server returned false');
      }
      return success;
    } catch (e) {
      print('❌ UPDATE: Failed - $e');
      return false;
    }
  }

  /// Delete item from server
  Future<bool> deleteItem(int itemId) async {
    if (!await isOnline()) {
      print('❌ DELETE: No internet connection');
      return false;
    }

    try {
      print('📤 DELETE: Deleting item $itemId from server...');
      final success = await _api.deleteItem(itemId);
      
      if (success) {
        print('✅ DELETE: Item deleted from server');
      } else {
        print('❌ DELETE: Server returned false');
      }
      return success;
    } catch (e) {
      print('❌ DELETE: Failed - $e');
      return false;
    }
  }

  /// Create chapters on server
  Future<bool> createChapters(int itemId, List<Map<String, dynamic>> chapters) async {
    if (!await isOnline()) {
      print('❌ CREATE CHAPTERS: No internet connection');
      return false;
    }

    try {
      print('📤 CREATE CHAPTERS: Pushing ${chapters.length} chapters for item $itemId...');
      final success = await _api.createChapters(itemId, chapters);
      
      if (success) {
        print('✅ CREATE CHAPTERS: Chapters created on server');
      } else {
        print('❌ CREATE CHAPTERS: Server returned false');
      }
      return success;
    } catch (e) {
      print('❌ CREATE CHAPTERS: Failed - $e');
      return false;
    }
  }

  /// Update chapter on server
  Future<bool> updateChapter(int itemId, int chapterNumber, Map<String, dynamic> data) async {
    if (!await isOnline()) {
      print('❌ UPDATE CHAPTER: No internet connection');
      return false;
    }

    try {
      print('📤 UPDATE CHAPTER: Pushing chapter $chapterNumber for item $itemId...');
      final success = await _api.updateChapter(itemId, chapterNumber, data);
      
      if (success) {
        print('✅ UPDATE CHAPTER: Chapter updated on server');
      } else {
        print('❌ UPDATE CHAPTER: Server returned false');
      }
      return success;
    } catch (e) {
      print('❌ UPDATE CHAPTER: Failed - $e');
      return false;
    }
  }

  /// Delete chapter from server
  Future<bool> deleteChapter(int itemId, int chapterNumber) async {
    if (!await isOnline()) {
      print('❌ DELETE CHAPTER: No internet connection');
      return false;
    }

    try {
      print('📤 DELETE CHAPTER: Deleting chapter $chapterNumber from item $itemId...');
      final success = await _api.deleteChapter(itemId, chapterNumber);
      
      if (success) {
        print('✅ DELETE CHAPTER: Chapter deleted from server');
      } else {
        print('❌ DELETE CHAPTER: Server returned false');
      }
      return success;
    } catch (e) {
      print('❌ DELETE CHAPTER: Failed - $e');
      return false;
    }
  }

  /// Toggle like on server
  Future<Map<String, dynamic>?> toggleLike(int itemId) async {
    if (!await isOnline()) return null;
    try {
      return await _api.toggleLike(itemId);
    } catch (e) {
      print('❌ TOGGLE LIKE: Failed - $e');
      return null;
    }
  }

  /// Add comment on server
  Future<dynamic> addComment(int itemId, String content) async {
    if (!await isOnline()) return null;
    try {
      return await _api.addComment(itemId, content);
    } catch (e) {
      print('❌ ADD COMMENT: Failed - $e');
      return null;
    }
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

