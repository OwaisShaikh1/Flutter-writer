import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/items_dao.dart';
import '../database/dao/chapters_dao.dart';
import '../services/sync_service.dart' as sync;
import '../services/offline_sync_service.dart' as offline;
import '../services/novel_export/novel_export_service.dart';
import '../services/storage_service.dart';
import '../models/literature_item.dart';
import '../models/chapter.dart';
import '../pages/create_literature_page.dart';

/// LiteratureProvider with Offline-First Support
/// 
/// - Pull: Fetch items/chapters from server
/// - Push: Offline-first CRUD operations that work with or without internet
/// - Queue: Operations are queued when offline and synced when online
class LiteratureProvider with ChangeNotifier {
  final AppDatabase _db;
  late final ItemsDao _itemsDao;
  late final ChaptersDao _chaptersDao;
  late final sync.SyncService _syncService;
  late final offline.OfflineSyncService _offlineSyncService;
  final NovelExportService _novelExportService = createNovelExportService();
  final StorageService _storageService = StorageService();

  List<LiteratureItem> _items = [];
  List<LiteratureItem> _myWorks = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String? _errorMessage;
  DateTime? _lastSyncTime;
  int? _currentUserId;
  StreamSubscription<List<dynamic>>? _myWorksSubscription;
  StreamSubscription<offline.SyncStatus>? _syncStatusSubscription;
  offline.SyncStatus _syncStatus = offline.SyncStatus.synced;
  int _pendingCount = 0;

  LiteratureProvider(this._db, offline.OfflineSyncService offlineSyncService) {
    _itemsDao = ItemsDao(_db);
    _chaptersDao = ChaptersDao(_db);
    _syncService = sync.SyncService(_db);
    _offlineSyncService = offlineSyncService;
    _init();
    _loadCurrentUserId();
    _initSyncStatusWatching();
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await _storageService.getUserId();
    if (_currentUserId != null) {
      _watchMyWorks();
    }
    notifyListeners();
  }

  void _watchMyWorks() {
    if (_currentUserId == null) return;
    _myWorksSubscription?.cancel();
    _myWorksSubscription = _itemsDao.watchItemsByAuthorId(_currentUserId!).listen(
      (entities) {
        _myWorks = entities.map((e) => LiteratureItem.fromEntity(e)).toList();
        notifyListeners();
      },
    );
  }

  void _initSyncStatusWatching() {
    // Watch sync status changes
    _syncStatusSubscription = _offlineSyncService.syncStatusStream.listen((status) {
      _syncStatus = status;
      notifyListeners();
    });

    // Watch pending sync count
    _offlineSyncService.watchPendingCount().listen((count) {
      _pendingCount = count;
      notifyListeners();
    });
  }

  // Getters
  List<LiteratureItem> get items => _filterItems();
  List<LiteratureItem> get allItems => _items;
  List<LiteratureItem> get myWorks => _myWorks;
  int? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get totalItems => _items.length;
  int get filteredCount => _filterItems().length;
  
  // Offline sync getters
  offline.SyncStatus get syncStatus => _syncStatus;
  int get pendingCount => _pendingCount;
  bool get hasOfflineChanges => _pendingCount > 0;

  void _init() {
    _isLoading = true;
    notifyListeners();

    _itemsDao.watchAllItems().listen(
      (entities) {
        _items = entities.map((e) => LiteratureItem.fromEntity(e)).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load items: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  List<LiteratureItem> _filterItems() {
    return _items.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || item.type == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedFilter = 'All';
    notifyListeners();
  }

  // ==================== PULL ====================

  /// Pull items from server and process offline queue
  Future<offline.SyncResult> syncWithBackend() async {
    if (_isSyncing) {
      return offline.SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Process pending local operations first so local writes are not
      // overwritten by older server snapshots during pull.
      final queueResult = await _offlineSyncService.processSyncQueue();
      final pendingAfterQueue = await _offlineSyncService.getPendingCount();

      sync.SyncResult pullResult;
      if (!queueResult.success && pendingAfterQueue > 0) {
        pullResult = sync.SyncResult(
          success: false,
          message: 'Skipped pull because local changes are still pending',
          itemCount: 0,
        );
      } else {
        pullResult = await _syncService.pullItems();
      }
      
      if (pullResult.success || queueResult.success) {
        _lastSyncTime = DateTime.now();
        // Clear any previous error messages on successful sync
        _errorMessage = null;
      } else {
        // Set user-friendly error message
        if (pullResult.message.contains('No internet connection') || 
            queueResult.message.contains('No internet connection')) {
          _errorMessage = 'Working offline - your data is available locally';
        } else {
          _errorMessage = 'Sync failed - using local data';
        }
      }
      
      _isSyncing = false;
      notifyListeners();

      final syncedOk =
          pullResult.success && queueResult.success && pendingAfterQueue == 0;
      if (!syncedOk) {
        print(
          '❌ SYNC: Pull=${pullResult.message} | '
          'Queue=${queueResult.message} | Pending=$pendingAfterQueue',
        );
      }
      return offline.SyncResult(
        success: syncedOk,
        message: syncedOk
            ? 'Sync completed successfully'
            : 'Queue: ${queueResult.message}',
        itemCount: (pullResult.itemCount ?? 0) + (queueResult.itemCount ?? 0),
      );
    } catch (e) {
      _errorMessage = 'Sync error: $e';
      _isSyncing = false;
      notifyListeners();
      return offline.SyncResult(success: false, message: 'Sync error: $e');
    }
  }

  /// Process offline queue only (useful for background sync)
  Future<offline.SyncResult> processPendingSync() async {
    if (_isSyncing) {
      return offline.SyncResult(success: false, message: 'Sync already in progress');
    }

    try {
      return await _offlineSyncService.processSyncQueue();
    } catch (e) {
      return offline.SyncResult(success: false, message: 'Queue processing failed: $e');
    }
  }

  /// Download chapters for reading
  Future<sync.SyncResult> downloadChapters(int itemId) async {
    return await _syncService.pullChapters(itemId);
  }

  /// Download a single chapter (lazy loading)
  Future<bool> downloadChapter(int itemId, int chapterNumber) async {
    return await _syncService.downloadChapter(itemId, chapterNumber);
  }

  /// Refresh a single item's data (e.g., after viewing intro page)
  Future<void> refreshItemData(int itemId) async {
    // The provider watches database streams, so just trigger a notification
    // The item data is already up-to-date from database watchers
    notifyListeners();
  }

  // ==================== OFFLINE-FIRST CRUD ====================

  /// Create a new literature piece with chapters (offline-first)
  /// Works with or without internet - queues for sync when offline
  Future<int?> createLiterature({
    required String title,
    required String author,
    required String type,
    required String description,
    required List<ChapterDraft> chapters,
    String? imageUrl,
    String? imageLocalPath,
  }) async {
    _currentUserId = await _storageService.getUserId();
    if (_currentUserId == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return null;
    }

    try {
      final chapterData = chapters.map((c) => {
        'number': c.number,
        'title': c.title,
        'content': c.content,
      }).toList();

      final localId = await _offlineSyncService.createItemOfflineFirst(
        name: title,
        type: type,
        description: description,
        chapters: chapterData,
        imageUrl: imageUrl,
        imageLocalPath: imageLocalPath,
      );

      if (localId != null) {
        await refreshMyWorks();
        
        if (_pendingCount > 0) {
          _errorMessage = 'Created offline - will sync when connected';
        } else {
          _errorMessage = null;
        }
        notifyListeners();
      }

      return localId;
    } catch (e) {
      _errorMessage = 'Failed to create literature: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update an existing literature piece (offline-first)
  /// Works with or without internet - queues for sync when offline
  Future<bool> updateLiterature({
    required int id,
    required String title,
    required String author,
    required String type,
    required String description,
    required List<ChapterDraft> chapters,
    String? imageUrl,
    String? imageLocalPath,
  }) async {
    try {
      final chapterData = chapters.map((c) => {
        'number': c.number,
        'title': c.title,
        'content': c.content,
      }).toList();

      final success = await _offlineSyncService.updateItemOfflineFirst(
        localId: id,
        name: title,
        author: author,
        type: type,
        description: description,
        chapters: chapterData,
        imageUrl: imageUrl,
        imageLocalPath: imageLocalPath,
      );

      if (success) {
        await _storageService.clearChapterDraftsForItem(id);
        if (_pendingCount > 0) {
          _errorMessage = 'Updated offline - will sync when connected';
        } else {
          _errorMessage = null;
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to update literature: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete an item (offline-first)
  /// Works with or without internet - queues for sync when offline
  Future<bool> deleteItem(int id) async {
    try {
      await _storageService.clearChapterDraftsForItem(id);
      final success = await _offlineSyncService.deleteItemOfflineFirst(id);
      
      if (success) {
        if (_pendingCount > 0) {
          _errorMessage = 'Deleted offline - will sync when connected';
        } else {
          _errorMessage = null;
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete item: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle like for an item
  Future<bool> toggleLike(int id) async {
    try {
      final result = await _syncService.toggleLike(id);
      
      if (result != null) {
        final isLiked = result['liked'] as bool;
        final likesCount = result['likes_count'] as int;
        await _itemsDao.updateLikeStatus(id, isLiked, likesCount);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to toggle like: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== LOCAL OPERATIONS ====================

  /// Toggle favorite locally (no sync)
  Future<void> toggleFavorite(int id) async {
    try {
      final item = _items.firstWhere((i) => i.id == id);
      await _itemsDao.toggleFavorite(id, !item.isFavorite);
    } catch (e) {
      _errorMessage = 'Failed to update favorite: $e';
      notifyListeners();
    }
  }

  LiteratureItem? getItemById(int id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  List<LiteratureItem> getFavorites() {
    return _items.where((item) => item.isFavorite).toList();
  }

  List<LiteratureItem> getItemsByType(String type) {
    return _items.where((item) => item.type == type).toList();
  }

  /// Get chapters for an item (from local DB)
  Future<List<Chapter>> getChaptersForItem(int itemId) async {
    try {
      final entities = await _chaptersDao.getChaptersByItemId(itemId);
      return entities.map((e) => Chapter.fromEntity(e)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load chapters: $e';
      notifyListeners();
      return [];
    }
  }

  /// Save chapter changes locally only (draft), without publishing to server.
  Future<bool> saveChapterDraftLocally({
    required int itemId,
    required int chapterNumber,
    required String title,
    required String content,
  }) async {
    try {
      await _storageService.saveChapterDraft(
        itemId: itemId,
        chapterNumber: chapterNumber,
        title: title,
        content: content,
      );

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save local chapter draft: $e';
      notifyListeners();
      return false;
    }
  }

  /// Publish one chapter to server (overwrite if it already exists).
  Future<bool> publishChapter({
    required int itemId,
    required int chapterNumber,
    required String title,
    required String content,
  }) async {
    try {
      final published = await _syncService.publishChapter(
        itemId: itemId,
        chapterNumber: chapterNumber,
        title: title,
        content: content,
      );

      if (!published) {
        _errorMessage = 'Failed to publish chapter (check internet connection)';
        notifyListeners();
        return false;
      }

      final existing = await _chaptersDao.getChapter(itemId, chapterNumber);
      final nextVersion = (existing?.version ?? 0) + 1;

      await _chaptersDao.upsertChapter(
        ChaptersCompanion(
          itemId: Value(itemId),
          number: Value(chapterNumber),
          title: Value(title),
          content: Value(content),
          isDownloaded: const Value(true),
          downloadedAt: Value(DateTime.now()),
          hasChanged: const Value(false),
          version: Value(nextVersion),
        ),
      );

      await _storageService.clearChapterDraft(itemId, chapterNumber);

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to publish chapter: $e';
      notifyListeners();
      return false;
    }
  }

  /// Discard local chapter edits and restore the last published chapter text.
  /// If the chapter does not exist on server, the local chapter is removed.
  Future<bool> discardChapterChanges({
    required int itemId,
    required int chapterNumber,
  }) async {
    try {
      final hasDraft = await _storageService.getChapterDraft(itemId, chapterNumber) != null;
      if (!hasDraft) {
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      final published = await _syncService.fetchPublishedChapter(itemId, chapterNumber);

      if (published == null) {
        await _storageService.clearChapterDraft(itemId, chapterNumber);
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      final existing = await _chaptersDao.getChapter(itemId, chapterNumber);
      final nextVersion = (existing?.version ?? 0) + 1;

      await _chaptersDao.upsertChapter(
        ChaptersCompanion(
          itemId: Value(itemId),
          number: Value(chapterNumber),
          title: Value(published.title),
          content: Value(published.content),
          isDownloaded: const Value(true),
          downloadedAt: Value(DateTime.now()),
          hasChanged: const Value(false),
          version: Value(nextVersion),
        ),
      );

      await _storageService.clearChapterDraft(itemId, chapterNumber);

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to discard chapter changes: $e';
      notifyListeners();
      return false;
    }
  }

  /// Export a whole novel as a local styled text document.
  /// Uses local database chapters only, so it works fully offline.
  /// Export is restricted to the author of the item.
  Future<NovelExportResult> exportNovelDocument(int itemId) async {
    _currentUserId ??= await _storageService.getUserId();
    if (_currentUserId == null) {
      return const NovelExportResult(
        success: false,
        message: 'User not logged in.',
      );
    }

    final item = getItemById(itemId);
    if (item == null) {
      return const NovelExportResult(
        success: false,
        message: 'Item not found locally.',
      );
    }

    if (item.authorId == null || item.authorId != _currentUserId) {
      return const NovelExportResult(
        success: false,
        message: 'Only the author can export this novel offline.',
      );
    }

    final chapters = await getChaptersForItem(itemId);
    if (chapters.isEmpty) {
      return const NovelExportResult(
        success: false,
        message: 'No local chapters found to export.',
      );
    }

    return _novelExportService.exportNovel(item: item, chapters: chapters);
  }

  /// Check if current user owns an item
  bool isOwnedByCurrentUser(int itemId) {
    if (_currentUserId == null) return false;
    final item = getItemById(itemId);
    return item?.authorId == _currentUserId;
  }

  /// Delete a chapter (offline-first)
  /// Works with or without internet - queues for sync when offline
  Future<bool> deleteChapter(int itemId, int chapterNumber) async {
    try {
      await _storageService.clearChapterDraft(itemId, chapterNumber);
      final success = await _offlineSyncService.deleteChapterOfflineFirst(itemId, chapterNumber);
      
      if (success) {
        if (_pendingCount > 0) {
          _errorMessage = 'Chapter deleted offline - will sync when connected';
        } else {
          _errorMessage = null;
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete chapter: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getChapterDraft(int itemId, int chapterNumber) async {
    return _storageService.getChapterDraft(itemId, chapterNumber);
  }

  Future<Map<int, Map<String, dynamic>>> getChapterDraftsForItem(int itemId) async {
    return _storageService.getChapterDraftsForItem(itemId);
  }

  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
    if (userId != null) {
      _watchMyWorks();
    } else {
      _myWorks = [];
    }
    notifyListeners();
  }

  Future<void> refreshMyWorks() async {
    _currentUserId = await _storageService.getUserId();
    if (_currentUserId == null) {
      _myWorks = [];
      notifyListeners();
      return;
    }
    _watchMyWorks();
    final entities = await _itemsDao.getItemsByAuthorId(_currentUserId!);
    _myWorks = entities.map((e) => LiteratureItem.fromEntity(e)).toList();
    notifyListeners();
  }

  Future<void> resetForUserChange() async {
    _myWorksSubscription?.cancel();
    _myWorksSubscription = null;
    _myWorks = [];
    _currentUserId = null;
    _lastSyncTime = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> reloadForNewUser() async {
    _currentUserId = await _storageService.getUserId();
    if (_currentUserId != null) {
      _watchMyWorks();
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _myWorksSubscription?.cancel();
    _syncStatusSubscription?.cancel();
    _offlineSyncService.dispose();
    super.dispose();
  }
}

