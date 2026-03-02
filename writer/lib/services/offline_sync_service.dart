import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/items_dao.dart';
import '../database/dao/chapters_dao.dart';
import '../database/dao/sync_log_dao.dart';
import '../services/storage_service.dart';
import 'api_service.dart';
import 'sync_service.dart';

/// Enhanced Sync Service with Offline-First Support
/// 
/// Features:
/// 1. Offline CRUD operations that queue to SyncLog
/// 2. Background sync processing when online
/// 3. Conflict resolution (complete item overwrite)
/// 4. Automatic retry mechanism
class OfflineSyncService {
  final AppDatabase _db;
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  late final ItemsDao _itemsDao;
  late final ChaptersDao _chaptersDao;
  late final SyncLogDao _syncLogDao;
  
  // For background sync
  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();

  OfflineSyncService(this._db) {
    _itemsDao = ItemsDao(_db);
    _chaptersDao = ChaptersDao(_db);
    _syncLogDao = SyncLogDao(_db);
    _startBackgroundSync();
  }

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // ==================== CONNECTIVITY ====================
  
  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result is List) {
        return result.isNotEmpty && !result.contains(ConnectivityResult.none);
      } else {
        return result != ConnectivityResult.none;
      }
    } catch (e) {
      print('📡 CONNECTIVITY: Error checking connectivity: $e');
      return false;
    }
  }

  // ==================== OFFLINE-FIRST CRUD ====================

  /// Create item offline-first
  /// - If online: create immediately and store locally
  /// - If offline: store locally with null serverId and queue sync operation
  Future<int?> createItemOfflineFirst({
    required String name,
    required String type,
    required String description,
    required List<Map<String, dynamic>> chapters,
    String? imageUrl,
  }) async {
    final userId = await _storage.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final isConnected = await isOnline();
    
    if (isConnected) {
      // Try to create online first
      try {
        final serverId = await _api.createItem(
          name: name,
          type: type,
          description: description,
          imageUrl: imageUrl,
        );
        
        if (serverId != null) {
          // Create chapters on server
          if (chapters.isNotEmpty) {
            await _api.createChapters(serverId, chapters);
          }
          
          // Store locally with server ID
          final localId = await _itemsDao.upsertItem(ItemsCompanion(
            serverId: Value(serverId),
            name: Value(name),
            author: Value(''), // Will be filled from user profile
            authorId: Value(userId),
            type: Value(type),
            description: Value(description),
            chaptersCount: Value(chapters.length),
            imageUrl: Value(imageUrl),
            isSynced: const Value(true),
            hasChanged: const Value(false),
            lastSyncedAt: Value(DateTime.now()),
          ));
          
          // Store chapters locally
          for (final chapter in chapters) {
            await _chaptersDao.upsertChapter(ChaptersCompanion(
              itemId: Value(localId),
              number: Value(chapter['number']),
              title: Value(chapter['title']),
              content: Value(chapter['content']),
              isDownloaded: const Value(true),
            ));
          }
          
          print('✅ OFFLINE SYNC: Item created online and stored locally');
          return localId;
        }
      } catch (e) {
        print('⚠️ OFFLINE SYNC: Online creation failed, falling back to offline: $e');
      }
    }

    // Create offline (either no connection or online failed)
    print('💾 OFFLINE SYNC: Creating item offline...');
    
    final localId = await _itemsDao.upsertItem(ItemsCompanion(
      serverId: const Value.absent(), // No server ID yet
      name: Value(name),
      author: Value(''), // Will be filled from user profile
      authorId: Value(userId),
      type: Value(type),
      description: Value(description),
      chaptersCount: Value(chapters.length),
      imageUrl: Value(imageUrl),
      isSynced: const Value(false),
      hasChanged: const Value(true),
    ));

    // Store chapters locally
    for (final chapter in chapters) {
      await _chaptersDao.upsertChapter(ChaptersCompanion(
        itemId: Value(localId),
        number: Value(chapter['number']),
        title: Value(chapter['title']),
        content: Value(chapter['content']),
        isDownloaded: const Value(true),
      ));
    }

    // Queue for sync
    await _syncLogDao.logItemCreate(localId, {
      'name': name,
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
      'chapters': chapters,
    }, userId: userId);

    print('✅ OFFLINE SYNC: Item created offline and queued for sync');
    _notifySyncStatus(SyncStatus.queued);
    return localId;
  }

  /// Update item offline-first
  Future<bool> updateItemOfflineFirst({
    required int localId,
    required String name,
    required String type,
    required String description,
    required List<Map<String, dynamic>> chapters,
    String? imageUrl,
  }) async {
    final userId = await _storage.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final item = await _itemsDao.getItemById(localId);
    if (item == null) throw Exception('Item not found');

    final isConnected = await isOnline();
    
    if (isConnected && item.serverId != null) {
      // Try to update online first
      try {
        final success = await _api.updateItem(
          itemId: item.serverId!,
          name: name,
          type: type,
          description: description,
          imageUrl: imageUrl,
        );
        
        if (success) {
          // Update chapters on server (complete replacement)
          await _api.updateChapters(item.serverId!, chapters);
          
          // Update locally
          await _updateItemLocally(localId, name, type, description, chapters, imageUrl, synced: true);
          
          print('✅ OFFLINE SYNC: Item updated online');
          return true;
        }
      } catch (e) {
        print('⚠️ OFFLINE SYNC: Online update failed, storing offline: $e');
      }
    }

    // Update offline
    print('💾 OFFLINE SYNC: Updating item offline...');
    
    await _updateItemLocally(localId, name, type, description, chapters, imageUrl, synced: false);

    // Queue for sync
    await _syncLogDao.logItemUpdate(localId, {
      'name': name,
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
      'chapters': chapters,
    }, userId: userId);

    print('✅ OFFLINE SYNC: Item updated offline and queued for sync');
    _notifySyncStatus(SyncStatus.queued);
    return true;
  }

  /// Delete item offline-first
  Future<bool> deleteItemOfflineFirst(int localId) async {
    final userId = await _storage.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final item = await _itemsDao.getItemById(localId);
    if (item == null) throw Exception('Item not found');

    final isConnected = await isOnline();
    
    if (isConnected && item.serverId != null) {
      // Try to delete online first
      try {
        final success = await _api.deleteItem(item.serverId!);
        if (success) {
          // Delete locally
          await _chaptersDao.deleteChaptersByItemId(localId);
          await _itemsDao.deleteItem(localId);
          
          print('✅ OFFLINE SYNC: Item deleted online');
          return true;
        }
      } catch (e) {
        print('⚠️ OFFLINE SYNC: Online delete failed, queuing for later: $e');
      }
    }

    // Queue for sync (don't delete locally yet if it hasn't been synced)
    if (item.serverId != null) {
      print('💾 OFFLINE SYNC: Queueing item delete...');
      await _syncLogDao.logItemDelete(localId, userId: userId);
      
      // Mark as deleted locally but keep data until sync
      await _itemsDao.upsertItem(ItemsCompanion(
        id: Value(localId),
        hasChanged: const Value(true),
        isSynced: const Value(false),
      ));
      
      _notifySyncStatus(SyncStatus.queued);
    } else {
      // Item was never synced, safe to delete immediately
      print('💾 OFFLINE SYNC: Deleting unsynced item locally');
      await _chaptersDao.deleteChaptersByItemId(localId);
      await _itemsDao.deleteItem(localId);
    }

    return true;
  }

  /// Delete chapter offline-first
  Future<bool> deleteChapterOfflineFirst(int itemId, int chapterNumber) async {
    final userId = await _storage.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final item = await _itemsDao.getItemById(itemId);
    if (item == null) throw Exception('Item not found');

    final chapter = await _chaptersDao.getChapter(itemId, chapterNumber);
    if (chapter == null) throw Exception('Chapter not found');

    final isConnected = await isOnline();
    
    if (isConnected && item.serverId != null) {
      // Try to delete online first
      try {
        final success = await _api.deleteChapter(item.serverId!, chapterNumber);
        if (success) {
          // Delete locally
          await _chaptersDao.deleteChapter(itemId, chapterNumber);
          print('✅ OFFLINE SYNC: Chapter deleted online');
          return true;
        }
      } catch (e) {
        print('⚠️ OFFLINE SYNC: Online chapter delete failed, queuing: $e');
      }
    }

    // Queue for sync
    print('💾 OFFLINE SYNC: Queueing chapter delete...');
    await _syncLogDao.logChapterDelete(chapter.id!, itemId, chapterNumber, userId: userId);
    
    // Delete locally
    await _chaptersDao.deleteChapter(itemId, chapterNumber);
    
    _notifySyncStatus(SyncStatus.queued);
    return true;
  }

  // ==================== BACKGROUND SYNC ====================

  void _startBackgroundSync() {
    // Sync every 2 minutes when app is active
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!_isSyncing) {
        _processSyncQueue();
      }
    });
  }

  /// Process all pending sync operations
  Future<SyncResult> processSyncQueue() async {
    return await _processSyncQueue();
  }

  Future<SyncResult> _processSyncQueue() async {
    if (_isSyncing || !await isOnline()) {
      return SyncResult(success: false, message: 'Already syncing or offline');
    }

    _isSyncing = true;
    _notifySyncStatus(SyncStatus.syncing);
    
    try {
      final operations = await _syncLogDao.getPendingOperations();
      if (operations.isEmpty) {
        _notifySyncStatus(SyncStatus.synced);
        return SyncResult(success: true, message: 'No pending operations');
      }

      print('🔄 OFFLINE SYNC: Processing ${operations.length} pending operations...');
      
      int successful = 0;
      int failed = 0;

      for (final op in operations) {
        try {
          final success = await _processOperation(op);
          if (success) {
            await _syncLogDao.removeOperation(op.id);
            successful++;
          } else {
            await _syncLogDao.markAttempted(op.id, 'Operation failed');
            failed++;
          }
        } catch (e) {
          await _syncLogDao.markAttempted(op.id, 'Exception: $e');
          failed++;
          print('❌ OFFLINE SYNC: Operation ${op.id} failed: $e');
        }
      }

      final message = 'Sync completed: $successful successful, $failed failed';
      print('✅ OFFLINE SYNC: $message');
      
      _notifySyncStatus(failed == 0 ? SyncStatus.synced : SyncStatus.error);
      return SyncResult(success: true, message: message, itemCount: successful);
      
    } catch (e) {
      print('❌ OFFLINE SYNC: Sync queue processing failed: $e');
      _notifySyncStatus(SyncStatus.error);
      return SyncResult(success: false, message: 'Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processOperation(SyncLogEntry op) async {
    final data = jsonDecode(op.payload) as Map<String, dynamic>;
    
    switch (op.entityType) {
      case 'item':
        return await _processItemOperation(op, data);
      case 'chapter':
        return await _processChapterOperation(op, data);
      default:
        print('❌ OFFLINE SYNC: Unknown entity type: ${op.entityType}');
        return false;
    }
  }

  Future<bool> _processItemOperation(SyncLogEntry op, Map<String, dynamic> data) async {
    final item = await _itemsDao.getItemById(op.entityId);
    
    switch (op.operation) {
      case 'create':
        return await _syncCreateItem(op, item, data);
      case 'update':
        return await _syncUpdateItem(op, item, data);
      case 'delete':
        return await _syncDeleteItem(op, item);
      default:
        return false;
    }
  }

  Future<bool> _processChapterOperation(SyncLogEntry op, Map<String, dynamic> data) async {
    switch (op.operation) {
      case 'delete':
        if (op.parentId == null) return false;
        final item = await _itemsDao.getItemById(op.parentId!);
        if (item?.serverId == null) return false;
        return await _api.deleteChapter(item!.serverId!, data['number']);
      default:
        return false;
    }
  }

  Future<bool> _syncCreateItem(SyncLogEntry op, ItemEntity? item, Map<String, dynamic> data) async {
    if (item == null) return true; // Item was deleted locally
    
    final serverId = await _api.createItem(
      name: data['name'],
      type: data['type'],
      description: data['description'],
      imageUrl: data['imageUrl'],
    );
    
    if (serverId == null) return false;

    // Create chapters if any
    final chapters = data['chapters'] as List<dynamic>? ?? [];
    if (chapters.isNotEmpty) {
      final chaptersSuccess = await _api.createChapters(serverId, chapters.cast<Map<String, dynamic>>());
      if (!chaptersSuccess) {
        print('⚠️ OFFLINE SYNC: Item created but chapters failed');
      }
    }

    // Update local item with server ID
    await _itemsDao.upsertItem(ItemsCompanion(
      id: Value(item.id),
      serverId: Value(serverId),
      isSynced: const Value(true),
      hasChanged: const Value(false),
      lastSyncedAt: Value(DateTime.now()),
    ));

    print('✅ OFFLINE SYNC: Created item ${item.name} on server');
    return true;
  }

  Future<bool> _syncUpdateItem(SyncLogEntry op, ItemEntity? item, Map<String, dynamic> data) async {
    if (item?.serverId == null) return false;
    
    final success = await _api.updateItem(
      itemId: item!.serverId!,
      name: data['name'],
      type: data['type'],
      description: data['description'],
      imageUrl: data['imageUrl'],
    );
    
    if (!success) return false;

    // Update chapters (complete replacement)
    final chapters = data['chapters'] as List<dynamic>? ?? [];
    if (chapters.isNotEmpty) {
      await _api.updateChapters(item.serverId!, chapters.cast<Map<String, dynamic>>());
    }

    // Update local sync status
    await _itemsDao.upsertItem(ItemsCompanion(
      id: Value(item.id),
      isSynced: const Value(true),
      hasChanged: const Value(false),
      lastSyncedAt: Value(DateTime.now()),
    ));

    print('✅ OFFLINE SYNC: Updated item ${item.name} on server');
    return true;
  }

  Future<bool> _syncDeleteItem(SyncLogEntry op, ItemEntity? item) async {
    if (item?.serverId == null) {
      // Item was never synced, just remove locally
      await _chaptersDao.deleteChaptersByItemId(op.entityId);
      await _itemsDao.deleteItem(op.entityId);
      return true;
    }
    
    final success = await _api.deleteItem(item!.serverId!);
    if (success) {
      await _chaptersDao.deleteChaptersByItemId(op.entityId);
      await _itemsDao.deleteItem(op.entityId);
    }
    return success;
  }

  // ==================== HELPERS ====================

  Future<void> _updateItemLocally(
    int localId,
    String name,
    String type,
    String description,
    List<Map<String, dynamic>> chapters,
    String? imageUrl,
    {bool synced = false}
  ) async {
    // Update item
    await _itemsDao.upsertItem(ItemsCompanion(
      id: Value(localId),
      name: Value(name),
      type: Value(type),
      description: Value(description),
      chaptersCount: Value(chapters.length),
      imageUrl: Value(imageUrl),
      isSynced: Value(synced),
      hasChanged: Value(!synced),
      lastSyncedAt: synced ? Value(DateTime.now()) : const Value.absent(),
    ));

    // Replace all chapters
    await _chaptersDao.deleteChaptersByItemId(localId);
    for (final chapter in chapters) {
      await _chaptersDao.upsertChapter(ChaptersCompanion(
        itemId: Value(localId),
        number: Value(chapter['number']),
        title: Value(chapter['title']),
        content: Value(chapter['content']),
        isDownloaded: const Value(true),
      ));
    }
  }

  void _notifySyncStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  /// Get pending sync count
  Future<int> getPendingCount() => _syncLogDao.getPendingCount();

  /// Get pending sync count stream
  Stream<int> watchPendingCount() => _syncLogDao.watchPendingCount();

  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}

// ==================== DATA CLASSES ====================

enum SyncStatus {
  synced,
  queued, 
  syncing,
  error,
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