import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database.dart';
import '../services/sync_service.dart' as sync_svc;
import '../services/offline_sync_service.dart' as offline;

/// Enhanced SyncProvider with Offline Sync Support
/// Handles connectivity status, background sync, and offline queue processing
class SyncProvider with ChangeNotifier {
  final AppDatabase _db;
  late final sync_svc.SyncService _syncService;
  late final offline.OfflineSyncService _offlineSyncService;

  bool _isOnline = true;
  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;
  offline.SyncStatus _syncStatus = offline.SyncStatus.synced;
  int _pendingCount = 0;

  StreamSubscription<dynamic>? _connectivitySubscription;
  StreamSubscription<offline.SyncStatus>? _syncStatusSubscription;
  StreamSubscription<int>? _pendingCountSubscription;
  Timer? _backgroundSyncTimer;

  SyncProvider(this._db, offline.OfflineSyncService offlineSyncService) {
    _syncService = sync_svc.SyncService(_db);
    _offlineSyncService = offlineSyncService;
    _initConnectivity();
    _initSyncStatusWatching();
    _startBackgroundSync();
  }

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  offline.SyncStatus get syncStatus => _syncStatus;
  int get pendingCount => _pendingCount;
  bool get hasOfflineChanges => _pendingCount > 0;
  sync_svc.SyncService get syncService => _syncService;
  offline.OfflineSyncService get offlineSyncService => _offlineSyncService;

  /// Initialize connectivity monitoring
  void _initConnectivity() {
    _checkConnectivity();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (dynamic result) {
        final wasOnline = _isOnline;
        if (result is List) {
          _isOnline = (result as List).isNotEmpty && !(result as List).contains(ConnectivityResult.none);
        } else {
          _isOnline = result != ConnectivityResult.none;
        }
        
        if (wasOnline != _isOnline) {
          print('📡 SYNC PROVIDER: Connectivity changed - Online: $_isOnline');
          notifyListeners();
          
          // Trigger immediate sync when coming back online
          if (_isOnline && !wasOnline && _pendingCount > 0) {
            print('🔄 SYNC PROVIDER: Back online with pending changes, triggering sync...');
            _triggerImmediateSync();
          }
        }
      },
    );
  }

  /// Initialize sync status watching
  void _initSyncStatusWatching() {
    // Watch offline sync status
    _syncStatusSubscription = _offlineSyncService.syncStatusStream.listen((status) {
      _syncStatus = status;
      notifyListeners();
    });

    // Watch pending operations count
    _pendingCountSubscription = _offlineSyncService.watchPendingCount().listen((count) {
      _pendingCount = count;
      notifyListeners();
    });
  }

  /// Start background sync monitoring
  void _startBackgroundSync() {
    // The OfflineSyncService now handles its own intelligent exponential backoff
    // We just need to trigger immediate sync when coming back online
    print('📡 SYNC PROVIDER: Background sync monitoring started');
  }

  Future<void> _checkConnectivity() async {
    final dynamic result = await Connectivity().checkConnectivity();
    if (result is List) {
      _isOnline = (result as List).isNotEmpty && !(result as List).contains(ConnectivityResult.none);
    } else {
      _isOnline = result != ConnectivityResult.none;
    }
    notifyListeners();
  }

  /// Full sync: Pull from server + Process offline queue
  Future<offline.SyncResult> sync() async {
    if (_isSyncing) {
      return offline.SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      print('🔄 SYNC PROVIDER: Starting full sync...');
      
      sync_svc.SyncResult pullResult =
          sync_svc.SyncResult(success: true, message: 'No pull needed');
      offline.SyncResult queueResult =
          offline.SyncResult(success: true, message: 'No queue to process');

      // Process queue first so pending local changes get pushed before pull.
      if (_isOnline) {
        queueResult = await _offlineSyncService.processSyncQueue();
        print(
          '📤 SYNC PROVIDER: Queue result - '
          '${queueResult.success ? 'SUCCESS' : 'FAILED'}: ${queueResult.message}',
        );
      }

      final pendingAfterQueue = await _offlineSyncService.getPendingCount();

      // Pull only if queue is drained or had nothing pending.
      if (_isOnline && (queueResult.success || pendingAfterQueue == 0)) {
        pullResult = await _syncService.pullItems();
        print(
          '📥 SYNC PROVIDER: Pull result - '
          '${pullResult.success ? 'SUCCESS' : 'FAILED'}: ${pullResult.message}',
        );
      } else if (_isOnline) {
        pullResult = sync_svc.SyncResult(
          success: false,
          message: 'Skipped pull because local changes are still pending',
          itemCount: 0,
        );
        print('⏭️ SYNC PROVIDER: Pull skipped while pending changes remain');
      }

      // Re-check pending count after queue processing.
      final pendingAfter = await _offlineSyncService.getPendingCount();
      _pendingCount = pendingAfter;

      // Update sync time if either operation succeeded
      if (pullResult.success || queueResult.success) {
        _lastSyncTime = DateTime.now();
      } else {
        _lastError = queueResult.message.isNotEmpty ? queueResult.message : pullResult.message;
      }

      _isSyncing = false;
      notifyListeners();

      final queueDrained = pendingAfter == 0;
      final syncSuccess = pullResult.success && queueResult.success && queueDrained;
      if (!syncSuccess) {
        _lastError = !queueDrained
            ? '$pendingAfter change(s) still pending sync'
            : (queueResult.success ? pullResult.message : queueResult.message);
      }

      return offline.SyncResult(
        success: syncSuccess,
        message: syncSuccess
            ? 'Sync completed successfully'
            : (_lastError ?? 'Sync incomplete'),
        itemCount: (pullResult.itemCount ?? 0) + (queueResult.itemCount ?? 0),
      );
    } catch (e) {
      print('❌ SYNC PROVIDER: Sync failed - $e');
      _lastError = 'Sync failed: $e';
      _isSyncing = false;
      notifyListeners();
      return offline.SyncResult(success: false, message: _lastError!);
    }
  }

  /// Process offline queue only
  Future<offline.SyncResult> processOfflineQueue() async {
    return _processOfflineQueue();
  }

  Future<offline.SyncResult> _processOfflineQueue() async {
    if (_isSyncing || !_isOnline || _pendingCount == 0) {
      return offline.SyncResult(success: false, message: 'Cannot process queue right now');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _offlineSyncService.processSyncQueue();
      
      if (result.success) {
        _lastSyncTime = DateTime.now();
      } else {
        _lastError = result.message;
      }

      _isSyncing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _lastError = 'Queue processing failed: $e';
      _isSyncing = false;
      notifyListeners();
      return offline.SyncResult(success: false, message: _lastError!);
    }
  }

  /// Trigger immediate sync (used when connectivity restored)
  void _triggerImmediateSync() {
    Timer(const Duration(seconds: 2), () {
      if (_isOnline && !_isSyncing) {
        _processOfflineQueue();
      }
    });
  }

  /// Download chapters for an item
  Future<sync_svc.SyncResult> downloadChapters(int itemId) async {
    if (!_isOnline) {
      return sync_svc.SyncResult(success: false, message: 'No internet connection');
    }
    return await _syncService.pullChapters(itemId);
  }

  /// Download a single chapter (lazy loading)
  Future<bool> downloadChapter(int itemId, int chapterNumber) async {
    if (!_isOnline) return false;
    return await _syncService.downloadChapter(itemId, chapterNumber);
  }

  /// Force sync to happen immediately (manual trigger)
  Future<offline.SyncResult> forceSync() async {
    print('🚀 SYNC PROVIDER: Force sync triggered');
    return await sync();
  }

  /// Reset for user change
  Future<void> resetForUserChange() async {
    _lastSyncTime = null;
    _lastError = null;
    _pendingCount = 0;
    _syncStatus = offline.SyncStatus.synced;
    notifyListeners();
  }

  /// Refresh connectivity status
  Future<void> refreshConnectivity() async {
    await _checkConnectivity();
  }

  /// Get sync status description for UI
  String getSyncStatusDescription() {
    if (_isSyncing) return 'Syncing...';
    if (!_isOnline) return 'Offline';
    
    switch (_syncStatus) {
      case offline.SyncStatus.synced:
        return _pendingCount > 0 ? 'Changes pending' : 'Synced';
      case offline.SyncStatus.queued:
        return 'Changes queued ($pendingCount)';
      case offline.SyncStatus.syncing:
        return 'Syncing...';
      case offline.SyncStatus.error:
        return 'Sync error';
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusSubscription?.cancel();
    _pendingCountSubscription?.cancel();
    _backgroundSyncTimer?.cancel();
    _offlineSyncService.dispose();
    super.dispose();
  }
}

