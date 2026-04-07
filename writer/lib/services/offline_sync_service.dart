import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/dao/chapters_dao.dart';
import '../database/dao/items_dao.dart';
import '../database/dao/sync_log_dao.dart';
import '../services/storage_service.dart';
import 'api_service.dart';

/// Simple offline-first sync engine:
/// 1) Always write locally first.
/// 2) Always log an outbox operation in sync_log.
/// 3) Process outbox sequentially when online.
class OfflineSyncService {
  final AppDatabase _db;
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  late final ItemsDao _itemsDao;
  late final ChaptersDao _chaptersDao;
  late final SyncLogDao _syncLogDao;

  Timer? _backgroundTimer;
  bool _isSyncing = false;
  Completer<SyncResult>? _syncCompleter;

  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  OfflineSyncService(this._db) {
    _itemsDao = ItemsDao(_db);
    _chaptersDao = ChaptersDao(_db);
    _syncLogDao = SyncLogDao(_db);
    _startBackgroundSync();
  }

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  Future<bool> isOnline() async {
    try {
      final dynamic result = await Connectivity().checkConnectivity();
      if (result is List) {
        return result.isNotEmpty && !result.every((r) => r == ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  String? _toRemoteImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('blob:') ||
        imageUrl.startsWith('file:') ||
        imageUrl.startsWith('data:')) {
      return null;
    }
    return imageUrl;
  }

  // ==================== OFFLINE-FIRST CRUD ====================

  Future<int?> createItemOfflineFirst({
    required String name,
    required String type,
    required String description,
    required List<Map<String, dynamic>> chapters,
    String? imageUrl,
    String? imageLocalPath,
  }) async {
    final userId = await _storage.getUserId();
    final userName = await _storage.getName();
    if (userId == null) throw Exception('User not logged in');

    final requestId =
        'm-$userId-${DateTime.now().microsecondsSinceEpoch}-${name.hashCode.abs()}';

    final localId = await _db.transaction(() async {
      final id = await _itemsDao.upsertItem(
        ItemsCompanion(
          serverId: const Value.absent(),
          name: Value(name),
          author: Value(userName ?? ''),
          authorId: Value(userId),
          type: Value(type),
          description: Value(description),
          chaptersCount: Value(chapters.length),
          imageUrl: Value(imageUrl),
          imageLocalPath: Value(imageLocalPath),
          isSynced: const Value(false),
          hasChanged: const Value(true),
          version: const Value(1),
        ),
      );

      for (final chapter in chapters) {
        await _chaptersDao.upsertChapter(
          ChaptersCompanion(
            itemId: Value(id),
            number: Value(chapter['number']),
            title: Value(chapter['title']),
            content: Value(chapter['content']),
            isDownloaded: const Value(true),
            version: const Value(1),
          ),
        );
      }

      await _syncLogDao.logItemCreate(
        id,
        {
          'name': name,
          'type': type,
          'description': description,
          'imageUrl': imageUrl,
          'imageLocalPath': imageLocalPath,
          'chapters': chapters,
          'clientRequestId': requestId,
        },
        userId: userId,
      );

      return id;
    });

    _notifySyncStatus(SyncStatus.queued);
    unawaited(_triggerSyncIfOnline());
    return localId;
  }

  Future<bool> updateItemOfflineFirst({
    required int localId,
    required String name,
    required String author,
    required String type,
    required String description,
    required List<Map<String, dynamic>> chapters,
    String? imageUrl,
    String? imageLocalPath,
  }) async {
    final userId = await _storage.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final item = await _itemsDao.getItemById(localId);
    if (item == null) throw Exception('Item not found');

    await _db.transaction(() async {
      await _itemsDao.upsertItem(
        ItemsCompanion(
          id: Value(localId),
          name: Value(name),
          author: Value(author),
          type: Value(type),
          description: Value(description),
          chaptersCount: Value(chapters.length),
          imageUrl: Value(imageUrl),
          imageLocalPath: Value(imageLocalPath),
          isSynced: const Value(false),
          hasChanged: const Value(true),
          version: Value(item.version + 1),
        ),
      );

      await _chaptersDao.deleteChaptersByItemId(localId);
      for (final chapter in chapters) {
        await _chaptersDao.upsertChapter(
          ChaptersCompanion(
            itemId: Value(localId),
            number: Value(chapter['number']),
            title: Value(chapter['title']),
            content: Value(chapter['content']),
            isDownloaded: const Value(true),
            version: Value(item.version + 1),
          ),
        );
      }

      await _syncLogDao.logItemUpdate(
        localId,
        {
          'name': name,
          'author': author,
          'type': type,
          'description': description,
          'imageUrl': imageUrl,
          'imageLocalPath': imageLocalPath,
          'chapters': chapters,
        },
        userId: userId,
      );
    });

    _notifySyncStatus(SyncStatus.queued);
    unawaited(_triggerSyncIfOnline());
    return true;
  }

  Future<bool> deleteItemOfflineFirst(int localId) async {
    final userId = await _storage.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final item = await _itemsDao.getItemById(localId);
    if (item == null) return true;

    await _db.transaction(() async {
      // Queue delete regardless; sync processor will no-op if no server id exists.
      await _syncLogDao.logItemDelete(localId, userId: userId);
      await _chaptersDao.deleteChaptersByItemId(localId);
      await _itemsDao.deleteItem(localId);
    });

    _notifySyncStatus(SyncStatus.queued);
    unawaited(_triggerSyncIfOnline());
    return true;
  }

  Future<bool> deleteChapterOfflineFirst(int itemId, int chapterNumber) async {
    final userId = await _storage.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final chapter = await _chaptersDao.getChapter(itemId, chapterNumber);
    if (chapter == null) return true;

    await _db.transaction(() async {
      await _syncLogDao.logChapterDelete(chapter.id, itemId, chapterNumber, userId: userId);
      await _chaptersDao.deleteChapter(itemId, chapterNumber);
    });

    _notifySyncStatus(SyncStatus.queued);
    unawaited(_triggerSyncIfOnline());
    return true;
  }

  // ==================== SYNC PROCESSING ====================

  void _startBackgroundSync() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(_triggerSyncIfOnline());
    });
  }

  Future<void> _triggerSyncIfOnline() async {
    if (!await isOnline()) return;
    await processSyncQueue();
  }

  Future<SyncResult> processSyncQueue() async {
    if (_syncCompleter != null) {
      return _syncCompleter!.future;
    }
    return _processSyncQueue();
  }

  Future<SyncResult> _processSyncQueue() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync in progress');
    }

    _isSyncing = true;
    _syncCompleter = Completer<SyncResult>();

    try {
      if (!await isOnline()) {
        final result = SyncResult(success: false, message: 'Offline');
        _syncCompleter!.complete(result);
        return result;
      }

      _notifySyncStatus(SyncStatus.syncing);

      final userId = await _storage.getUserId();
      final operations = userId != null
          ? await _syncLogDao.getPendingOperationsForUser(userId)
          : await _syncLogDao.getPendingOperations();

      if (operations.isEmpty) {
        final result = SyncResult(success: true, message: 'No pending operations', itemCount: 0);
        _notifySyncStatus(SyncStatus.synced);
        _syncCompleter!.complete(result);
        return result;
      }

      int successCount = 0;
      int failCount = 0;
      const int maxRetries = 3; // Max attempts before discarding operation

      for (final op in operations) {
        try {
          final ok = await _processOperation(op);
          if (ok) {
            await _syncLogDao.removeOperation(op.id);
            successCount++;
          } else {
            // Mark as attempted, but remove if too many retries
            await _syncLogDao.markAttempted(op.id, 'Operation failed');
            if ((op.attempts + 1) >= maxRetries) {
              // Too many failures; discard to prevent infinite loops
              print('⚠️ Sync: Discarding operation ${op.id} after ${op.attempts + 1} attempts');
              await _syncLogDao.removeOperation(op.id);
            }
            failCount++;
          }
        } catch (e) {
          await _syncLogDao.markAttempted(op.id, 'Exception: $e');
          if ((op.attempts + 1) >= maxRetries) {
            print('⚠️ Sync: Discarding operation ${op.id} after ${op.attempts + 1} attempts (exception)');
            await _syncLogDao.removeOperation(op.id);
          }
          failCount++;
        }
      }

      final allSucceeded = failCount == 0;
      _notifySyncStatus(allSucceeded ? SyncStatus.synced : SyncStatus.error);
      final result = SyncResult(
        success: allSucceeded,
        message: 'Sync: $successCount successful, $failCount failed',
        itemCount: successCount,
      );
      _syncCompleter!.complete(result);
      return result;
    } catch (e) {
      _notifySyncStatus(SyncStatus.error);
      final result = SyncResult(success: false, message: 'Sync failed: $e');
      _syncCompleter!.complete(result);
      return result;
    } finally {
      _isSyncing = false;
      _syncCompleter = null;
    }
  }

  Future<bool> _processOperation(SyncLogEntry op) async {
    final data = jsonDecode(op.payload) as Map<String, dynamic>;

    if (op.entityType == 'item') {
      switch (op.operation) {
        case 'create':
          return _syncItemCreate(op, data);
        case 'update':
          return _syncItemUpdate(op, data);
        case 'delete':
          return _syncItemDelete(op);
      }
    }

    if (op.entityType == 'chapter') {
      switch (op.operation) {
        case 'delete':
          return _syncChapterDelete(op, data);
      }
    }

    return false;
  }

  Future<bool> _syncItemCreate(SyncLogEntry op, Map<String, dynamic> data) async {
    final item = await _itemsDao.getItemById(op.entityId);
    if (item == null) return true;

    // If already mapped to server id, only ensure chapters are synced.
    if (item.serverId != null) {
      final chapters = (data['chapters'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (chapters.isNotEmpty) {
        final ok = await _api.updateChapters(item.serverId!, chapters);
        if (!ok) return false;
      }
      await _itemsDao.upsertItem(
        ItemsCompanion(
          id: Value(item.id),
          isSynced: const Value(true),
          hasChanged: const Value(false),
          lastSyncedAt: Value(DateTime.now()),
        ),
      );
      return true;
    }

    final requestId = data['clientRequestId'] as String? ?? 'legacy-create-${op.id}-${op.entityId}';
    final serverId = await _api.createItem(
      name: data['name'] as String? ?? item.name,
      type: data['type'] as String? ?? item.type,
      description: data['description'] as String? ?? item.description,
      imageUrl: _toRemoteImageUrl(data['imageUrl'] as String?),
      clientRequestId: requestId,
    );

    if (serverId == null) return false;

    await _itemsDao.upsertItem(
      ItemsCompanion(
        id: Value(item.id),
        serverId: Value(serverId),
        isSynced: const Value(false),
        hasChanged: const Value(true),
      ),
    );

    final chapters = (data['chapters'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    if (chapters.isNotEmpty) {
      final ok = await _api.createChapters(serverId, chapters);
      if (!ok) return false;
    }

    await _itemsDao.upsertItem(
      ItemsCompanion(
        id: Value(item.id),
        serverId: Value(serverId),
        isSynced: const Value(true),
        hasChanged: const Value(false),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );

    return true;
  }

  Future<bool> _syncItemUpdate(SyncLogEntry op, Map<String, dynamic> data) async {
    final item = await _itemsDao.getItemById(op.entityId);
    if (item == null) return true;

    // If server mapping does not exist yet, treat as create-snapshot.
    if (item.serverId == null) {
      return _syncItemCreate(op, data);
    }

    final okItem = await _api.updateItem(
      itemId: item.serverId!,
      name: data['name'] as String? ?? item.name,
      type: data['type'] as String? ?? item.type,
      description: data['description'] as String? ?? item.description,
      imageUrl: _toRemoteImageUrl(data['imageUrl'] as String?) ??
          _toRemoteImageUrl(item.imageUrl),
      version: item.version,
    );

    int newLocalVersion = item.version + 1;
    if (!okItem) {
      // Recover from optimistic-lock conflicts (409): fetch current server version
      // and retry the same update once with that version.
      final serverItem = await _api.getItem(item.serverId!);
      final serverVersion = serverItem?['version'] as int?;
      if (serverVersion == null) return false;

      final retryOk = await _api.updateItem(
        itemId: item.serverId!,
        name: data['name'] as String? ?? item.name,
        type: data['type'] as String? ?? item.type,
        description: data['description'] as String? ?? item.description,
        imageUrl: _toRemoteImageUrl(data['imageUrl'] as String?) ??
            _toRemoteImageUrl(item.imageUrl),
        version: serverVersion,
      );

      if (!retryOk) {
        // Even the retry failed; log it and fail the operation
        print('❌ Sync: Item update retry failed for item ${item.serverId} (server v$serverVersion)');
        return false;
      }
      // Successful retry! Use server version + 1 as new local version
      newLocalVersion = serverVersion + 1;
    }

    final chapters = (data['chapters'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    if (chapters.isNotEmpty) {
      final okChapters = await _api.updateChapters(item.serverId!, chapters);
      if (!okChapters) {
        print('⚠️ Sync: Item ${item.serverId} chapters update failed, but item already synced');
        // Don't fail entirely - item was updated successfully, just chapters failed
        // (chapters will be retried in next sync)
      }
    }

    // Mark item as synced with new version
    await _itemsDao.upsertItem(
      ItemsCompanion(
        id: Value(item.id),
        isSynced: const Value(true),
        hasChanged: const Value(false),
        lastSyncedAt: Value(DateTime.now()),
        version: Value(newLocalVersion),
      ),
    );

    return true;
  }

  Future<bool> _syncItemDelete(SyncLogEntry op) async {
    final item = await _itemsDao.getItemById(op.entityId);
    if (item == null) return true;

    if (item.serverId == null) {
      await _chaptersDao.deleteChaptersByItemId(item.id);
      await _itemsDao.deleteItem(item.id);
      return true;
    }

    final ok = await _api.deleteItem(item.serverId!);
    if (!ok) return false;

    await _chaptersDao.deleteChaptersByItemId(item.id);
    await _itemsDao.deleteItem(item.id);
    return true;
  }

  Future<bool> _syncChapterDelete(SyncLogEntry op, Map<String, dynamic> data) async {
    if (op.parentId == null) return true;

    final item = await _itemsDao.getItemById(op.parentId!);
    if (item == null || item.serverId == null) return true;

    final chapterNumber = data['number'];
    if (chapterNumber is! int) return false;

    return _api.deleteChapter(item.serverId!, chapterNumber);
  }

  void _notifySyncStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  Future<int> getPendingCount() async {
    final userId = await _storage.getUserId();
    if (userId != null) {
      return _syncLogDao.getPendingCountForUser(userId);
    }
    return _syncLogDao.getPendingCount();
  }

  Stream<int> watchPendingCount() async* {
    final userId = await _storage.getUserId();
    if (userId != null) {
      yield* _syncLogDao.watchPendingCountForUser(userId);
      return;
    }
    yield* _syncLogDao.watchPendingCount();
  }

  void dispose() {
    _backgroundTimer?.cancel();
    if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
      _syncCompleter!.complete(
        SyncResult(success: false, message: 'Service disposed while syncing'),
      );
    }
    _syncStatusController.close();
  }
}

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
  String toString() =>
      'SyncResult(success: $success, message: $message, itemCount: $itemCount)';
}
