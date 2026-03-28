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
import 'conflict_resolver.dart';

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
  Completer<SyncResult>? _syncCompleter; // Fix race conditions
  StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  // Exponential backoff state
  Duration _currentBackoffDelay = const Duration(seconds: 2); // Start with 2 seconds
  static const Duration _maxBackoffDelay = Duration(minutes: 5); // Cap at 5 minutes
  static const Duration _baseDelay = Duration(seconds: 2);
  int _consecutiveFailures = 0;

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

      // Handle both List<ConnectivityResult> (newer API) and single ConnectivityResult
      if (result is List) {
        final list = result as List;
        final hasNetwork = list.isNotEmpty && !list.every((r) => r == ConnectivityResult.none);
        print('📡 CONNECTIVITY: $hasNetwork (list: $list)');
        return hasNetwork;
      } else {
        final hasNetwork = result != ConnectivityResult.none;
        print('📡 CONNECTIVITY: $hasNetwork ($result)');
        return hasNetwork;
      }
    } catch (e) {
      print('📡 CONNECTIVITY: Error - $e');
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
    final userName = await _storage.getName();
    if (userId == null) throw Exception('User not logged in');
    
    // Use stored display name or fallback to empty string
    final authorName = userName ?? '';

    final isConnected = await isOnline();
    
    if (isConnected) {
      // Try to create online first with fast timeout
      try {
        final serverId = await _api.createItem(
          name: name,
          type: type,
          description: description,
          imageUrl: imageUrl,
        ).timeout(const Duration(seconds: 15));
        
        if (serverId != null) {
          // Create chapters on server
          if (chapters.isNotEmpty) {
            await _api.createChapters(serverId, chapters)
                .timeout(const Duration(seconds: 5));
          }
          
          // Store locally with server ID
          final localId = await _itemsDao.upsertItem(ItemsCompanion(
            serverId: Value(serverId),
            name: Value(name),
            author: Value(authorName),
            authorId: Value(userId),
            type: Value(type),
            description: Value(description),
            chaptersCount: Value(chapters.length),
            imageUrl: Value(imageUrl),
            isSynced: const Value(true),
            hasChanged: const Value(false),
            lastSyncedAt: Value(DateTime.now()),
            version: const Value(1), // New items start at version 1
          ));
          
          // Store chapters locally
          for (final chapter in chapters) {
            await _chaptersDao.upsertChapter(ChaptersCompanion(
              itemId: Value(localId),
              number: Value(chapter['number']),
              title: Value(chapter['title']),
              content: Value(chapter['content']),
              isDownloaded: const Value(true),
              version: const Value(1), // New chapters start at version 1
            ));
          }
          
          print('✅ OFFLINE SYNC: Item created online and stored locally');
          return localId;
        }
      } catch (e) {
        print('⚠️ OFFLINE SYNC: Online creation failed (${e.runtimeType}): $e — queuing for sync');
      }
    }

    // Create offline (either no connection or online failed)
    print('💾 OFFLINE SYNC: Creating item offline...');
    
    // Wrap in transaction to prevent partial state
    return await _db.transaction(() async {
      final localId = await _itemsDao.upsertItem(ItemsCompanion(
        serverId: const Value.absent(), // No server ID yet
        name: Value(name),
        author: Value(authorName),
        authorId: Value(userId),
        type: Value(type),
        description: Value(description),
        chaptersCount: Value(chapters.length),
        imageUrl: Value(imageUrl),
        isSynced: const Value(false),
        hasChanged: const Value(true),
        version: const Value(1), // New items start at version 1
      ));

      // Store chapters locally
      for (final chapter in chapters) {
        await _chaptersDao.upsertChapter(ChaptersCompanion(
          itemId: Value(localId),
          number: Value(chapter['number']),
          title: Value(chapter['title']),
          content: Value(chapter['content']),
          isDownloaded: const Value(true),
          version: const Value(1), // New chapters start at version 1
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
    });
  }

  /// Update item offline-first
  Future<bool> updateItemOfflineFirst({
    required int localId,
    required String name,
    required String author,
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
      // Try to update online first with fast timeout
      try {
        final success = await _api.updateItem(
          itemId: item.serverId!,
          name: name,
          type: type,
          description: description,
          imageUrl: imageUrl,
        ).timeout(const Duration(seconds: 15));
        
        if (success) {
          // Update chapters on server (complete replacement)
          await _api.updateChapters(item.serverId!, chapters)
              .timeout(const Duration(seconds: 15));
          
          // Update locally
          await _updateItemLocally(localId, name, author, type, description, chapters, imageUrl, synced: true);
          
          print('✅ OFFLINE SYNC: Item updated online');
          return true;
        }
      } catch (e) {
        print('⚠️ OFFLINE SYNC: Online update failed (${e.runtimeType}), storing offline: $e');
      }
    }

    // Update offline
    print('💾 OFFLINE SYNC: Updating item offline...');
    
    // Wrap in transaction to prevent partial state
    await _db.transaction(() async {
      await _updateItemLocally(localId, name, author, type, description, chapters, imageUrl, synced: false);

      // Queue for sync
      await _syncLogDao.logItemUpdate(localId, {
        'name': name,
        'author': author,
        'type': type,
        'description': description,
        'imageUrl': imageUrl,
        'chapters': chapters,
      }, userId: userId);
    });

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
      // Try to delete online first with fast timeout
      try {
        final success = await _api.deleteItem(item.serverId!)
            .timeout(const Duration(seconds: 15));
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

    // Queue for sync (with transaction)
    if (item.serverId != null) {
      print('💾 OFFLINE SYNC: Queueing item delete...');
      
      await _db.transaction(() async {
        await _syncLogDao.logItemDelete(localId, userId: userId);
        
        // Mark as deleted locally but keep data until sync
        await _itemsDao.upsertItem(ItemsCompanion(
          id: Value(localId),
          hasChanged: const Value(true),
          isSynced: const Value(false),
        ));
      });
      
      _notifySyncStatus(SyncStatus.queued);
    } else {
      // Item was never synced, safe to delete immediately
      print('💾 OFFLINE SYNC: Deleting unsynced item locally');
      await _db.transaction(() async {
        await _chaptersDao.deleteChaptersByItemId(localId);
        await _itemsDao.deleteItem(localId);
      });
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
    _scheduleNextSync();
  }

  void _scheduleNextSync() {
    _syncTimer?.cancel();
    
    // Only schedule if there might be pending operations
    _syncTimer = Timer(_currentBackoffDelay, () async {
      if (!_isSyncing) {
        final result = await _processSyncQueue();
        _handleSyncResult(result);
      }
      
      // Schedule next sync
      _scheduleNextSync();
    });
    
    print('⏰ OFFLINE SYNC: Next sync in ${_currentBackoffDelay.inSeconds}s (failures: $_consecutiveFailures)');
  }

  void _handleSyncResult(SyncResult result) {
    if (result.success) {
      // Reset backoff on success
      _consecutiveFailures = 0;
      _currentBackoffDelay = _baseDelay;
      print('✅ OFFLINE SYNC: Success - reset backoff to ${_baseDelay.inSeconds}s');
    } else {
      // Increase backoff on failure
      _consecutiveFailures++;
      final newDelay = Duration(
        milliseconds: (_baseDelay.inMilliseconds * (1 << _consecutiveFailures)).clamp(
          _baseDelay.inMilliseconds, 
          _maxBackoffDelay.inMilliseconds
        )
      );
      _currentBackoffDelay = newDelay;
      print('❌ OFFLINE SYNC: Failure $_consecutiveFailures - backoff to ${newDelay.inSeconds}s');
    }
  }

  /// Process all pending sync operations (thread-safe)
  Future<SyncResult> processSyncQueue() async {
    // Use completer to handle concurrent calls safely
    if (_syncCompleter != null) {
      print('🔄 OFFLINE SYNC: Sync already in progress, waiting...');
      return await _syncCompleter!.future;
    }

    return await _processSyncQueue();
  }

  Future<SyncResult> _processSyncQueue() async {
    // Thread-safe sync guard
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
      
      final operations = await _syncLogDao.getPendingOperations();
      if (operations.isEmpty) {
        final result = SyncResult(success: true, message: 'No pending operations');
        _notifySyncStatus(SyncStatus.synced);
        _syncCompleter!.complete(result);
        return result;
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
      
      final allSucceeded = failed == 0;
      final result = SyncResult(success: allSucceeded, message: message, itemCount: successful);
      _notifySyncStatus(allSucceeded ? SyncStatus.synced : SyncStatus.error);
      _syncCompleter!.complete(result);
      return result;
      
    } catch (e) {
      print('❌ OFFLINE SYNC: Sync queue processing failed: $e');
      final result = SyncResult(success: false, message: 'Sync failed: $e');
      _notifySyncStatus(SyncStatus.error);
      _syncCompleter!.complete(result);
      return result;
    } finally {
      _isSyncing = false;
      _syncCompleter = null;
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
    
    try {
      // Get current server item data to check for conflicts
      final serverItem = await _api.getItem(item!.serverId!);
      if (serverItem == null) {
        print('❌ OFFLINE SYNC: Server item not found, may have been deleted');
        return false;
      }

      // Check for version conflicts
      final serverVersion = serverItem['version'] as int? ?? 1;
      final clientVersion = item.version ?? 1;
      
      if (serverVersion != clientVersion) {
        print('⚠️ CONFLICT DETECTED: Item ${item.name} - Server:v$serverVersion Client:v$clientVersion');
        print('🗑️ VERSION INFO: Server item version: ${serverItem['version']}, Client item version: ${item.version}');
        print('🗑️ DATA COMPARISON:');
        print('  Server name: ${serverItem['name']}, Client name: ${item.name}');
        print('  Server type: ${serverItem['type']}, Client type: ${item.type}');
        print('  Update data name: ${data['name']}, Update data type: ${data['type']}');
        
        // Create conflict info
        final conflict = ConflictInfo(
          entityType: 'item',
          entityId: item.id,
          serverVersion: serverVersion,
          clientVersion: clientVersion,
          serverData: serverItem,
          clientData: {
            'name': data['name'] as String? ?? item.name,
            'type': data['type'] as String? ?? item.type,
            'description': data['description'] as String? ?? item.description,
            'imageUrl': data['imageUrl'] as String? ?? item.imageUrl,
            'version': clientVersion,
          },
          serverUpdatedAt: serverItem['updatedAt'] != null ? DateTime.parse(serverItem['updatedAt'] as String) : DateTime.now(),
          clientUpdatedAt: item.updatedAt ?? DateTime.now(),
        );
        
        try {
          // Use automatic conflict resolution (merge strategy)
          final resolvedData = ConflictResolver.resolveConflict(
            conflict, 
            ConflictResolution.mergeChanges
          );
          
          print('🔧 CONFLICT RESOLVED: Using merge strategy for item ${item.name}');
          print('🗑️ RESOLVED DATA: name=${resolvedData['name']}, type=${resolvedData['type']}, version=${resolvedData['version']}');
          
          // Update server with resolved data
          // Server expects the CURRENT server version (optimistic locking); it increments internally
          print('🔄 CONFLICT RESOLUTION: Updating server for item ${item.name} (server ID: ${item.serverId})');
          final success = await _api.updateItem(
            itemId: item.serverId!,
            name: resolvedData['name'] as String? ?? item.name,
            type: resolvedData['type'] as String? ?? item.type,
            description: resolvedData['description'] as String? ?? item.description,
            imageUrl: resolvedData['imageUrl'] as String? ?? item.imageUrl,
            version: serverVersion, // Must match current server version exactly
          );
          
          if (!success) {
            print('❌ CONFLICT RESOLUTION: Server update failed for item ${item.name}');
            return false;
          }
          print('✅ CONFLICT RESOLUTION: Server updated successfully for item ${item.name}');

          // Update chapters with resolved data
          final chapters = data['chapters'] as List<dynamic>? ?? [];
          if (chapters.isNotEmpty) {
            print('📝 CONFLICT RESOLUTION: Updating ${chapters.length} chapters for item ${item.name}');
            try {
              await _api.updateChapters(item.serverId!, chapters.cast<Map<String, dynamic>>());
              print('✅ CONFLICT RESOLUTION: Chapters updated successfully');
            } catch (e) {
              print('❌ CONFLICT RESOLUTION: Chapter update failed: $e');
              return false;
            }
          }

          // Update local item - server increments version, so our new local version = serverVersion + 1
          await _itemsDao.upsertItem(ItemsCompanion(
            id: Value(item.id),
            name: Value(resolvedData['name'] as String? ?? item.name),
            author: Value(resolvedData['author'] as String? ?? item.author),
            type: Value(resolvedData['type'] as String? ?? item.type),
            description: Value(resolvedData['description'] as String? ?? item.description),
            imageUrl: Value(resolvedData['imageUrl'] as String?),
            version: Value(serverVersion + 1), // Server incremented it, so local = serverVersion + 1
            isSynced: const Value(true),
            hasChanged: const Value(false),
            lastSyncedAt: Value(DateTime.now()),
          ));

          print('✅ CONFLICT RESOLVED: Item ${resolvedData['name'] as String? ?? 'Unknown'} updated with version ${serverVersion + 1}');
          return true;
          
        } catch (e) {
          print('🚨 CONFLICT RESOLUTION ERROR: $e');
          print('🚨 ERROR TYPE: ${e.runtimeType}');
          if (e is ConflictNeedsManualResolutionException) {
            print('🤝 MANUAL RESOLUTION NEEDED: Item ${item.name}');
            // For now, we'll use server wins as fallback
            // In a real app, you'd queue this for user resolution
            try {
              final resolvedData = ConflictResolver.resolveConflict(
                conflict, 
                ConflictResolution.serverWins
              );
              
              // Update local with server data
              await _itemsDao.upsertItem(ItemsCompanion(
                id: Value(item.id),
                name: Value(resolvedData['name'] as String? ?? item.name),
                author: Value(item.author), // Keep existing author
                type: Value(resolvedData['type'] as String? ?? item.type),
                description: Value(resolvedData['description'] as String? ?? item.description),
                imageUrl: Value(resolvedData['imageUrl'] as String?),
                version: Value(serverVersion),
                isSynced: const Value(true),
                hasChanged: const Value(false),
                lastSyncedAt: Value(DateTime.now()),
              ));
              
              print('✅ CONFLICT RESOLVED: Used server data for item ${resolvedData['name'] as String? ?? 'Unknown'}');
              return true;
            } catch (manualResolutionError) {
              print('❌ MANUAL RESOLUTION FAILED: $manualResolutionError');
              return false;
            }
          }
          print('❌ CONFLICT RESOLUTION: Unexpected error, rethrowing: $e');
          return false; // Don't rethrow, just mark as failed
        }
      }
      
      // No conflicts, proceed with normal update
      final success = await _api.updateItem(
        itemId: item.serverId!,
        name: data['name'] as String? ?? item.name,
        type: data['type'] as String? ?? item.type,
        description: data['description'] as String? ?? item.description,
        imageUrl: data['imageUrl'] as String? ?? item.imageUrl,
        version: clientVersion, // Send current version; server checks equality then increments
      );
      
      if (!success) return false;

      // Update chapters (complete replacement)
      final chapters = data['chapters'] as List<dynamic>? ?? [];
      if (chapters.isNotEmpty) {
        await _api.updateChapters(item.serverId!, chapters.cast<Map<String, dynamic>>());
      }

      // Update local sync status - server incremented to clientVersion + 1
      await _itemsDao.upsertItem(ItemsCompanion(
        id: Value(item.id),
        isSynced: const Value(true),
        hasChanged: const Value(false),
        lastSyncedAt: Value(DateTime.now()),
        version: Value(clientVersion + 1),
      ));

      print('✅ OFFLINE SYNC: Updated item ${item.name} on server (v${clientVersion + 1})');
      return true;
      
    } catch (e) {
      print('❌ OFFLINE SYNC: Failed to sync update for item ${item?.name}: $e');
      return false;
    }
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
    String author,
    String type,
    String description,
    List<Map<String, dynamic>> chapters,
    String? imageUrl,
    {bool synced = false}
  ) async {
    // Wrap in transaction to prevent data corruption
    await _db.transaction(() async {
      final currentItem = await _itemsDao.getItemById(localId);
      final newVersion = synced ? (currentItem?.version ?? 1) : (currentItem?.version ?? 0) + 1;
      
      // Update item
      await _itemsDao.upsertItem(ItemsCompanion(
        id: Value(localId),
        name: Value(name),
        author: Value(author),
        type: Value(type),
        description: Value(description),
        chaptersCount: Value(chapters.length),
        imageUrl: Value(imageUrl),
        isSynced: Value(synced),
        hasChanged: Value(!synced),
        lastSyncedAt: synced ? Value(DateTime.now()) : const Value.absent(),
        version: Value(newVersion), // Increment version on changes
      ));

      // Replace all chapters atomically
      await _chaptersDao.deleteChaptersByItemId(localId);
      for (final chapter in chapters) {
        final chapterVersion = synced ? 1 : (currentItem?.version ?? 0) + 1;
        await _chaptersDao.upsertChapter(ChaptersCompanion(
          itemId: Value(localId),
          number: Value(chapter['number']),
          title: Value(chapter['title']),
          content: Value(chapter['content']),
          isDownloaded: const Value(true),
          version: Value(chapterVersion), // Increment version on changes
        ));
      }
    });
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
    
    // Complete any pending sync operations
    if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
      _syncCompleter!.complete(SyncResult(
        success: false, 
        message: 'Service disposed during sync'
      ));
    }
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