import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database.dart';
import '../services/sync_service.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncProvider with ChangeNotifier {
  final AppDatabase _db;
  late final SyncService _syncService;

  SyncStatus _status = SyncStatus.idle;
  bool _isOnline = true;
  String? _lastSyncMessage;
  DateTime? _lastSyncTime;
  int _pendingSyncCount = 0;
  Timer? _backgroundSyncTimer;
  bool _isBackgroundSyncing = false;

  SyncProvider(this._db) {
    _syncService = SyncService(_db);
    _initConnectivityListener();
    _checkConnectivity();
    _watchPendingCount();
    _startBackgroundSyncTimer();
  }

  // Getters
  SyncStatus get status => _status;
  bool get isOnline => _isOnline;
  bool get isSyncing => _status == SyncStatus.syncing;
  String? get lastSyncMessage => _lastSyncMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingSyncCount => _pendingSyncCount;
  bool get hasPendingChanges => _pendingSyncCount > 0;

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      // When coming back online, trigger a silent background sync
      if (wasOffline && _isOnline && _pendingSyncCount > 0) {
        _silentBackgroundSync();
      }
      
      notifyListeners();
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  /// Watch the pending sync count reactively from the sync log
  void _watchPendingCount() {
    _syncService.watchPendingSyncCount().listen((count) {
      _pendingSyncCount = count;
      notifyListeners();
    });
  }

  /// Full sync: Push local changes, then pull remote
  Future<SyncResult> syncAll() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(success: false, message: 'Already syncing');
    }

    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final result = await _syncService.fullSync();
      
      if (result.success) {
        _status = SyncStatus.success;
        _lastSyncTime = DateTime.now();
      } else {
        _status = SyncStatus.error;
      }
      
      _lastSyncMessage = result.message;
      notifyListeners();
      return result;
    } catch (e) {
      _status = SyncStatus.error;
      _lastSyncMessage = 'Sync failed: $e';
      notifyListeners();
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  /// Push only local changes (without pulling)
  Future<SyncResult> pushChanges() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(success: false, message: 'Already syncing');
    }

    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final result = await _syncService.processSyncLog();
      
      _status = result.success ? SyncStatus.success : SyncStatus.error;
      _lastSyncMessage = result.message;
      if (result.success) _lastSyncTime = DateTime.now();
      
      notifyListeners();
      return result;
    } catch (e) {
      _status = SyncStatus.error;
      _lastSyncMessage = 'Push failed: $e';
      notifyListeners();
      return SyncResult(success: false, message: 'Push failed: $e');
    }
  }

  /// Pull only remote items (without pushing)
  Future<SyncResult> pullChanges() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(success: false, message: 'Already syncing');
    }

    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final result = await _syncService.pullItems();
      
      _status = result.success ? SyncStatus.success : SyncStatus.error;
      _lastSyncMessage = result.message;
      if (result.success) _lastSyncTime = DateTime.now();
      
      notifyListeners();
      return result;
    } catch (e) {
      _status = SyncStatus.error;
      _lastSyncMessage = 'Pull failed: $e';
      notifyListeners();
      return SyncResult(success: false, message: 'Pull failed: $e');
    }
  }

  Future<SyncResult> downloadChapters(int itemId) async {
    if (!_isOnline) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final result = await _syncService.pullChapters(itemId);
      
      _status = result.success ? SyncStatus.success : SyncStatus.error;
      _lastSyncMessage = result.message;
      notifyListeners();
      
      return result;
    } catch (e) {
      _status = SyncStatus.error;
      _lastSyncMessage = 'Download failed: $e';
      notifyListeners();
      return SyncResult(success: false, message: 'Download failed: $e');
    }
  }

  Future<bool> downloadChapter(int itemId, int chapterNumber) async {
    if (!_isOnline) return false;
    return await _syncService.downloadChapter(itemId, chapterNumber);
  }

  void resetStatus() {
    _status = SyncStatus.idle;
    _lastSyncMessage = null;
    notifyListeners();
  }

  /// Start a periodic timer for background sync
  void _startBackgroundSyncTimer() {
    // Cancel any existing timer
    _backgroundSyncTimer?.cancel();
    
    // Run background sync every 30 seconds if there are pending changes
    _backgroundSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline && _pendingSyncCount > 0 && !_isBackgroundSyncing) {
        _silentBackgroundSync();
      }
    });
  }

  /// Silent background sync - doesn't update UI status, just pushes changes
  Future<void> _silentBackgroundSync() async {
    if (_isBackgroundSyncing || !_isOnline || _pendingSyncCount == 0) return;
    
    // Don't interfere with user-initiated sync
    if (_status == SyncStatus.syncing) return;
    
    _isBackgroundSyncing = true;
    
    try {
      await _syncService.backgroundSync();
      // Pending count will update automatically via the watcher
    } catch (e) {
      // Silent failure - will retry on next timer tick or connectivity change
      debugPrint('Background sync failed: $e');
    } finally {
      _isBackgroundSyncing = false;
    }
  }

  /// Manually trigger background sync (e.g., when app comes to foreground)
  Future<void> triggerBackgroundSync() async {
    await _silentBackgroundSync();
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    super.dispose();
  }
}
