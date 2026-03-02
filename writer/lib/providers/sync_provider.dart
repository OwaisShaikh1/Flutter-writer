import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database.dart';
import '../services/sync_service.dart';
import '../services/offline_sync_service.dart';

/// Enhanced SyncProvider with Offline Sync Support
/// Handles connectivity status, background sync, and offline queue processing
class SyncProvider with ChangeNotifier {
  final AppDatabase _db;
  late final SyncService _syncService;
  late final OfflineSyncService _offlineSyncService;

  bool _isOnline = true;
  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;
  SyncStatus _syncStatus = SyncStatus.synced;
  int _pendingCount = 0;

  StreamSubscription<dynamic>? _connectivitySubscription;
  StreamSubscription<SyncStatus>? _syncStatusSubscription;
  StreamSubscription<int>? _pendingCountSubscription;
  Timer? _backgroundSyncTimer;

  SyncProvider(this._db) {
    _syncService = SyncService(_db);
    _offlineSyncService = OfflineSyncService(_db);
    _initConnectivity();
    _initSyncStatusWatching();
    _startBackgroundSync();
  }

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncStatus get syncStatus => _syncStatus;
  int get pendingCount => _pendingCount;
  bool get hasOfflineChanges => _pendingCount > 0;
  SyncService get syncService => _syncService;
  OfflineSyncService get offlineSyncService => _offlineSyncService;

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

  /// Start background sync timer
  void _startBackgroundSync() {
    // Sync every 5 minutes when app is active
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline && !_isSyncing && _pendingCount > 0) {
        print('⏰ SYNC PROVIDER: Background sync triggered...');
        _processOfflineQueue();
      }
    });
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
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      print('🔄 SYNC PROVIDER: Starting full sync...');
      
      SyncResult pullResult = SyncResult(success: true, message: 'No pull needed');
      SyncResult queueResult = SyncResult(success: true, message: 'No queue to process');

      // Pull latest data from server
      if (_isOnline) {
        pullResult = await _syncService.pullItems();
        print('📥 SYNC PROVIDER: Pull result - ${pullResult.success ? 'SUCCESS' : 'FAILED'}: ${pullResult.message}');
      }

      // Process offline queue
      if (_isOnline && _pendingCount > 0) {
        queueResult = await _offlineSyncService.processSyncQueue();
        print('📤 SYNC PROVIDER: Queue result - ${queueResult.success ? 'SUCCESS' : 'FAILED'}: ${queueResult.message}');
      }

      // Update sync time if either operation succeeded
      if (pullResult.success || queueResult.success) {
        _lastSyncTime = DateTime.now();
      } else {
        _lastError = queueResult.message.isNotEmpty ? queueResult.message : pullResult.message;
      }

      _isSyncing = false;
      notifyListeners();

      return SyncResult(
        success: pullResult.success || queueResult.success,
        message: 'Pull: ${pullResult.message} | Queue: ${queueResult.message}',
        itemCount: (pullResult.itemCount ?? 0) + (queueResult.itemCount ?? 0),
      );
    } catch (e) {
      print('❌ SYNC PROVIDER: Sync failed - $e');
      _lastError = 'Sync failed: $e';
      _isSyncing = false;
      notifyListeners();
      return SyncResult(success: false, message: _lastError!);
    }
  }

  /// Process offline queue only
  Future<SyncResult> processOfflineQueue() async {
    return _processOfflineQueue();
  }

  Future<SyncResult> _processOfflineQueue() async {
    if (_isSyncing || !_isOnline || _pendingCount == 0) {
      return SyncResult(success: false, message: 'Cannot process queue right now');
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
      return SyncResult(success: false, message: _lastError!);
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
  Future<SyncResult> downloadChapters(int itemId) async {
    if (!_isOnline) {
      return SyncResult(success: false, message: 'No internet connection');
    }
    return await _syncService.pullChapters(itemId);
  }

  /// Download a single chapter (lazy loading)
  Future<bool> downloadChapter(int itemId, int chapterNumber) async {
    if (!_isOnline) return false;
    return await _syncService.downloadChapter(itemId, chapterNumber);
  }

  /// Force sync to happen immediately (manual trigger)
  Future<SyncResult> forcSync() async {
    print('🚀 SYNC PROVIDER: Force sync triggered');
    return await sync();
  }

  /// Reset for user change
  Future<void> resetForUserChange() async {
    _lastSyncTime = null;
    _lastError = null;
    _pendingCount = 0;
    _syncStatus = SyncStatus.synced;
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
      case SyncStatus.synced:
        return _pendingCount > 0 ? 'Changes pending' : 'Synced';
      case SyncStatus.queued:
        return 'Changes queued ($pendingCount)';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.error:
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

