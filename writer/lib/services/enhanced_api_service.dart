import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/items_dao.dart';
import '../database/dao/chapters_dao.dart';
import '../services/storage_service.dart';
import '../models/literature_item.dart';
import '../models/chapter.dart';
import '../models/comment.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

/// Enhanced API Service with Local Database Fallback
/// 
/// Features:
/// 1. Always try server first
/// 2. Fall back to local database on failure
/// 3. Graceful timeout handling
/// 4. Connection awareness
class ApiServiceWithFallback {
  final AuthService _authService = AuthService();
  final AppDatabase _db;
  late final ItemsDao _itemsDao;
  late final ChaptersDao _chaptersDao;
  final StorageService _storage = StorageService();
  
  // Request timeout configuration
  static const Duration _requestTimeout = Duration(seconds: 10);
  
  ApiServiceWithFallback(this._db) {
    _itemsDao = ItemsDao(_db);
    _chaptersDao = ChaptersDao(_db);
  }

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Check if we have network connectivity and server is reachable
  Future<bool> _isServerReachable() async {
    try {
      // Quick connectivity check
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        print('📡 No network connectivity');
        return false;
      }

      // Test actual server reachability with timeout
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/health'),
        headers: await _getHeaders(),
      ).timeout(_requestTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      print('📡 Server unreachable: $e');
      return false;
    }
  }

  /// Enhanced fetchItems with local fallback
  Future<List<LiteratureItem>> fetchItems({bool forceLocal = false}) async {
    // If forced to use local or server is unreachable, load from local DB
    if (forceLocal || !await _isServerReachable()) {
      print('📱 Loading items from local database');
      return await _loadItemsFromLocal();
    }

    // Try server first
    try {
      print('📡 Fetching items from server...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items'),
        headers: await _getHeaders(),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final items = data.map((json) => LiteratureItem.fromJson(json)).toList();
        
        // Cache items locally for future offline use
        await _cacheItemsLocally(items);
        
        print('✅ Loaded ${items.length} items from server');
        return items;
      } else {
        print('⚠️ Server returned ${response.statusCode}, falling back to local');
        return await _loadItemsFromLocal();
      }
    } catch (e) {
      print('❌ Server request failed: $e, falling back to local');
      return await _loadItemsFromLocal();
    }
  }

  /// Enhanced fetchItem with local fallback
  Future<LiteratureItem?> fetchItem(int id, {bool forceLocal = false}) async {
    // If forced to use local or server is unreachable, load from local DB
    if (forceLocal || !await _isServerReachable()) {
      print('📱 Loading item $id from local database');
      return await _loadItemFromLocal(id);
    }

    // Try server first
    try {
      print('📡 Fetching item $id from server...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items/$id'),
        headers: await _getHeaders(),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final item = LiteratureItem.fromJson(data);
        
        // Cache item locally
        await _cacheItemLocally(item);
        
        return item;
      } else {
        print('⚠️ Server returned ${response.statusCode} for item $id, checking local');
        return await _loadItemFromLocal(id);
      }
    } catch (e) {
      print('❌ Server request failed for item $id: $e, checking local');
      return await _loadItemFromLocal(id);
    }
  }

  /// Enhanced fetchChapters with local fallback
  Future<List<Chapter>> fetchChapters(int itemId, {bool forceLocal = false}) async {
    // If forced to use local or server is unreachable, load from local DB
    if (forceLocal || !await _isServerReachable()) {
      print('📱 Loading chapters for item $itemId from local database');
      return await _loadChaptersFromLocal(itemId);
    }

    // Try server first
    try {
      print('📡 Fetching chapters for item $itemId from server...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chapters?bookId=$itemId'),
        headers: await _getHeaders(),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final chapters = data.map((json) => Chapter.fromJson(json)).toList();
        
        // Cache chapters locally
        await _cacheChaptersLocally(itemId, chapters);
        
        print('✅ Loaded ${chapters.length} chapters from server');
        return chapters;
      } else {
        print('⚠️ Server returned ${response.statusCode} for chapters, checking local');
        return await _loadChaptersFromLocal(itemId);
      }
    } catch (e) {
      print('❌ Server request failed for chapters: $e, checking local');
      return await _loadChaptersFromLocal(itemId);
    }
  }

  /// Enhanced fetchUserItems with local fallback
  Future<List<LiteratureItem>> fetchUserItems(int authorId, {bool forceLocal = false}) async {
    // If forced to use local or server is unreachable, load from local DB  
    if (forceLocal || !await _isServerReachable()) {
      print('📱 Loading user $authorId items from local database');
      return await _loadUserItemsFromLocal(authorId);
    }

    // Try server first
    try {
      print('📡 Fetching items for user $authorId from server...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items?authorId=$authorId'),
        headers: await _getHeaders(),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final items = data.map((json) => LiteratureItem.fromJson(json)).toList();
        
        // Cache items locally
        await _cacheItemsLocally(items);
        
        print('✅ Loaded ${items.length} user items from server');
        return items;
      } else {
        print('⚠️ Server returned ${response.statusCode} for user items, checking local');
        return await _loadUserItemsFromLocal(authorId);
      }
    } catch (e) {
      print('❌ Server request failed for user items: $e, checking local');
      return await _loadUserItemsFromLocal(authorId);
    }
  }

  // ==================== LOCAL DATABASE METHODS ====================

  Future<List<LiteratureItem>> _loadItemsFromLocal() async {
    final entities = await _itemsDao.getAllItems();
    return entities.map((e) => LiteratureItem.fromEntity(e)).toList();
  }

  Future<LiteratureItem?> _loadItemFromLocal(int id) async {
    final entity = await _itemsDao.getItemById(id);
    return entity != null ? LiteratureItem.fromEntity(entity) : null;
  }

  Future<List<Chapter>> _loadChaptersFromLocal(int itemId) async {
    final entities = await _chaptersDao.getChaptersByItemId(itemId);
    return entities.map((e) => Chapter.fromEntity(e)).toList();
  }

  Future<List<LiteratureItem>> _loadUserItemsFromLocal(int authorId) async {
    final entities = await _itemsDao.getItemsByAuthorId(authorId);
    return entities.map((e) => LiteratureItem.fromEntity(e)).toList();
  }

  // ==================== CACHING METHODS ====================

  Future<void> _cacheItemsLocally(List<LiteratureItem> items) async {
    for (final item in items) {
      await _cacheItemLocally(item);
    }
  }

  Future<void> _cacheItemLocally(LiteratureItem item) async {
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
    ));
  }

  Future<void> _cacheChaptersLocally(int itemId, List<Chapter> chapters) async {
    for (final chapter in chapters) {
      await _chaptersDao.upsertChapter(ChaptersCompanion(
        id: Value(chapter.id),
        itemId: Value(itemId),
        number: Value(chapter.number),
        title: Value(chapter.title),
        content: Value(chapter.content),
        isDownloaded: const Value(true),
        version: const Value(1),
      ));
    }
  }

  // ==================== WRITE OPERATIONS ====================
  // Keep existing write operations unchanged - they should use offline-first approach from OfflineSyncService

  // Check if server is reachable (public method)
  Future<bool> isServerReachable() => _isServerReachable();
}
