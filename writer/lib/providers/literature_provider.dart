import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/items_dao.dart';
import '../database/dao/chapters_dao.dart';
import '../services/sync_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/literature_item.dart';
import '../models/chapter.dart';
import '../pages/create_literature_page.dart';

class LiteratureProvider with ChangeNotifier {
  final AppDatabase _db;
  late final ItemsDao _itemsDao;
  late final ChaptersDao _chaptersDao;
  late final SyncService _syncService;
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  List<LiteratureItem> _items = [];
  List<LiteratureItem> _myWorks = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String? _errorMessage;
  DateTime? _lastSyncTime;
  int? _currentUserId;

  LiteratureProvider(this._db) {
    _itemsDao = ItemsDao(_db);
    _chaptersDao = ChaptersDao(_db);
    _syncService = SyncService(_db);
    _init();
    _loadCurrentUserId();
  }

  // Load current user ID from storage
  Future<void> _loadCurrentUserId() async {
    _currentUserId = await _storageService.getUserId();
    if (_currentUserId != null) {
      _watchMyWorks();
    }
    notifyListeners();
  }

  // Watch items created by current user
  void _watchMyWorks() {
    if (_currentUserId == null) return;
    
    _itemsDao.watchItemsByAuthorId(_currentUserId!).listen(
      (entities) {
        _myWorks = entities.map((e) => LiteratureItem.fromEntity(e)).toList();
        notifyListeners();
      },
      onError: (error) {
        // Silently ignore errors for my works
      },
    );
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

  void _init() {
    _isLoading = true;
    notifyListeners();

    // Watch database changes - reactive updates
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

  Future<SyncResult> syncWithBackend() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Full bidirectional sync: push local changes, then pull remote
      final result = await _syncService.fullSync();
      
      if (result.success) {
        _lastSyncTime = DateTime.now();
      } else {
        _errorMessage = result.message;
      }
      
      _isSyncing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Sync failed: $e';
      _isSyncing = false;
      notifyListeners();
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  Future<void> toggleFavorite(int id) async {
    try {
      final item = _items.firstWhere((i) => i.id == id);
      await _itemsDao.toggleFavorite(id, !item.isFavorite);
    } catch (e) {
      _errorMessage = 'Failed to update favorite: $e';
      notifyListeners();
    }
  }

  /// Toggle like for an item (calls API and updates local DB)
  Future<bool> toggleLike(int id) async {
    try {
      // Try to push to server first
      final result = await _syncService.autoPushToggleLike(id);
      
      if (result != null) {
        // Update local database with server response
        final isLiked = result['liked'] as bool;
        final likesCount = result['likes_count'] as int;
        await _itemsDao.updateLikeStatus(id, isLiked, likesCount);
        return true;
      } else {
        // Offline - toggle locally only
        await _itemsDao.toggleLike(id);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to toggle like: $e';
      notifyListeners();
      return false;
    }
  }

  /// Refresh item data from API (used after returning from detail page)
  Future<void> refreshItemData(int id) async {
    try {
      final item = await _apiService.fetchItem(id);
      if (item != null) {
        await _itemsDao.updateItem(id, ItemsCompanion(
          likesCount: Value(item.likes),
          isLikedByUser: Value(item.isLikedByUser),
          commentsCount: Value(item.comments),
        ));
      }
    } catch (e) {
      // Silent fail - not critical
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      // Auto-push delete: try server immediately, fallback to sync log
      await _syncService.autoPushItemDelete(id);
      
      // Delete locally (chapters cascade due to foreign key)
      await _chaptersDao.deleteChaptersByItemId(id);
      await _itemsDao.deleteItem(id);
    } catch (e) {
      _errorMessage = 'Failed to delete item: $e';
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

  // Create a new literature piece with chapters
  Future<int> createLiterature({
    required String title,
    required String author,
    required String type,
    required String description,
    required List<ChapterDraft> chapters,
    String? imageUrl,
  }) async {
    try {
      // Always fetch fresh user ID from storage
      _currentUserId = await _storageService.getUserId();
      
      print('DEBUG createLiterature: currentUserId = $_currentUserId');
      
      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }
      
      // Create the literature item locally
      final localItemId = await _itemsDao.upsertItem(ItemsCompanion(
        name: Value(title),
        author: Value(author),
        authorId: Value(_currentUserId),
        type: Value(type),
        description: Value(description),
        chaptersCount: Value(chapters.length),
        rating: const Value(0.0),
        commentsCount: const Value(0),
        likesCount: const Value(0),
        isLikedByUser: const Value(false),
        imageUrl: Value(imageUrl),
        isFavorite: const Value(false),
        isSynced: const Value(false),
      ));

      // Auto-push item: try server immediately, fallback to sync log
      final itemId = await _syncService.autoPushItemCreate(localItemId,
        name: title,
        type: type,
        description: description,
        author: author,
        authorId: _currentUserId,
        imageUrl: imageUrl,
      );

      // Create all chapters locally and auto-push
      for (final draft in chapters) {
        final chapterId = await _chaptersDao.upsertChapter(ChaptersCompanion(
          itemId: Value(itemId),
          number: Value(draft.number),
          title: Value(draft.title),
          content: Value(draft.content),
          isDownloaded: const Value(true),
          createdAt: Value(DateTime.now()),
        ));
        
        // Auto-push chapter: try server immediately, fallback to sync log
        await _syncService.autoPushChapterCreate(chapterId, itemId,
          number: draft.number,
          title: draft.title,
          content: draft.content,
        );
      }

      print('DEBUG createLiterature: Created item with id=$itemId, authorId=$_currentUserId');

      // Refresh my works list immediately
      await refreshMyWorks();

      return itemId;
    } catch (e) {
      _errorMessage = 'Failed to create literature: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update an existing literature piece
  Future<void> updateLiterature({
    required int id,
    required String title,
    required String author,
    required String type,
    required String description,
    required List<ChapterDraft> chapters,
    String? imageUrl,
  }) async {
    try {
      // Get existing chapters to compare
      final existingChapters = await _chaptersDao.getChaptersByItemId(id);
      final existingNumbers = existingChapters.map((c) => c.number).toSet();
      final newNumbers = chapters.map((c) => c.number).toSet();
      
      // Update the literature item locally
      await _itemsDao.upsertItem(ItemsCompanion(
        id: Value(id),
        name: Value(title),
        author: Value(author),
        type: Value(type),
        description: Value(description),
        chaptersCount: Value(chapters.length),
        imageUrl: Value(imageUrl),
        isSynced: const Value(false),
      ));

      // Auto-push item update: try server immediately, fallback to sync log
      await _syncService.autoPushItemUpdate(id, {
        'name': title,
        'type': type,
        'description': description,
        'imageUrl': imageUrl,
      });

      // Handle chapters: create new, update existing, delete removed
      for (final draft in chapters) {
        final existing = existingChapters.where((c) => c.number == draft.number).firstOrNull;
        
        final chapterId = await _chaptersDao.upsertChapter(ChaptersCompanion(
          itemId: Value(id),
          number: Value(draft.number),
          title: Value(draft.title),
          content: Value(draft.content),
          isDownloaded: const Value(true),
        ));

        if (existing == null) {
          // New chapter - auto-push
          await _syncService.autoPushChapterCreate(chapterId, id,
            number: draft.number,
            title: draft.title,
            content: draft.content,
          );
        } else if (existing.title != draft.title || existing.content != draft.content) {
          // Updated chapter - auto-push
          await _syncService.autoPushChapterUpdate(existing.id, id, {
            'number': draft.number,
            'title': draft.title,
            'content': draft.content,
          });
        }
      }

      // Delete removed chapters
      for (final existing in existingChapters) {
        if (!newNumbers.contains(existing.number)) {
          await _chaptersDao.deleteChaptersByItemId(id); // Will be recreated
          await _syncService.autoPushChapterDelete(existing.id, id, existing.number);
        }
      }

      // Recreate remaining chapters (simpler than individual deletes)
      await _chaptersDao.deleteChaptersByItemId(id);
      for (final draft in chapters) {
        await _chaptersDao.upsertChapter(ChaptersCompanion(
          itemId: Value(id),
          number: Value(draft.number),
          title: Value(draft.title),
          content: Value(draft.content),
          isDownloaded: const Value(true),
          createdAt: Value(DateTime.now()),
        ));
      }
    } catch (e) {
      _errorMessage = 'Failed to update literature: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Check if current user owns an item
  bool isOwnedByCurrentUser(int itemId) {
    if (_currentUserId == null) return false;
    final item = getItemById(itemId);
    return item?.authorId == _currentUserId;
  }

  // Get chapters for an item (for editing)
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

  // Set current user ID (called when user logs in)
  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
    if (userId != null) {
      _watchMyWorks();
    } else {
      _myWorks = [];
    }
    notifyListeners();
  }

  // Reload my works when returning to the app
  Future<void> refreshMyWorks() async {
    // Always fetch fresh user ID from storage
    _currentUserId = await _storageService.getUserId();
    
    print('DEBUG refreshMyWorks: currentUserId = $_currentUserId');
    
    if (_currentUserId == null) {
      _myWorks = [];
      notifyListeners();
      return;
    }
    
    // Re-watch for reactive updates
    _watchMyWorks();
    
    // Also do an immediate fetch
    final entities = await _itemsDao.getItemsByAuthorId(_currentUserId!);
    print('DEBUG refreshMyWorks: found ${entities.length} items for authorId $_currentUserId');
    
    // Also fetch all items to see what authorIds exist
    final allItems = await _itemsDao.getAllItems();
    for (var item in allItems) {
      print('DEBUG Item: id=${item.id}, name=${item.name}, authorId=${item.authorId}');
    }
    
    _myWorks = entities.map((e) => LiteratureItem.fromEntity(e)).toList();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Claim orphan items (items with null authorId) for the current user
  // Useful for migrating old data
  Future<int> claimOrphanItems() async {
    _currentUserId = await _storageService.getUserId();
    if (_currentUserId == null) return 0;
    
    final allItems = await _itemsDao.getAllItems();
    int claimed = 0;
    
    for (var item in allItems) {
      if (item.authorId == null) {
        await _itemsDao.updateItem(
          item.id,
          ItemsCompanion(authorId: Value(_currentUserId)),
        );
        claimed++;
      }
    }
    
    if (claimed > 0) {
      await refreshMyWorks();
    }
    
    return claimed;
  }
}
