import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'auth_service.dart';
import '../models/literature_item.dart';
import '../models/chapter.dart';
import '../models/comment.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';

/// Custom exception to distinguish between network errors and server errors
class ApiException implements Exception {
  final String message;
  final bool isNetworkError;
  
  ApiException(this.message, {required this.isNetworkError});
  
  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  final AuthService _authService = AuthService();

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all items from backend with timeout
  Future<List<LiteratureItem>> fetchItems() async {
    try {
      print('📡 API: Fetching all items from ${ApiConstants.baseUrl}/items');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ API: Received ${data.length} items from server');
        return data.map((json) => LiteratureItem.fromJson(json)).toList();
      } else {
        print('❌ API: Failed to load items: ${response.statusCode} - ${response.body}');
        throw ApiException('Server returned ${response.statusCode}', isNetworkError: false);
      }
    } on SocketException {
      print('❌ API: No internet connection');
      throw ApiException('No internet connection', isNetworkError: true);
    } on TimeoutException {
      print('❌ API: Request timeout');
      throw ApiException('Request timeout', isNetworkError: true);
    } catch (e) {
      print('❌ API: Network error: $e');
      throw ApiException('Network error: $e', isNetworkError: true);
    }
  }

  // Get specific item by ID
  Future<LiteratureItem?> fetchItem(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LiteratureItem.fromJson(data);
      } else {
        print('⚠️ fetchItem($id) returned status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ fetchItem($id) exception: $e');
      throw Exception('Failed to fetch item: $e');
    }
  }

  // Get specific item by ID as raw JSON for conflict detection
  Future<Map<String, dynamic>?> getItem(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('⚠️ getItem($id) returned status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ getItem($id) exception: $e');
      throw Exception('Failed to get item: $e');
    }
  }

  // Get items by list of IDs
  Future<List<LiteratureItem>> fetchItemsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items?ids=${ids.join(',')}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LiteratureItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load items by IDs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get items by author
  Future<List<LiteratureItem>> fetchUserItems(int authorId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items?authorId=$authorId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LiteratureItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get all chapters for an item
  Future<List<Chapter>> fetchChapters(int itemId) async {
    try {
      print('📡 API: Fetching chapters for item $itemId');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chapters?bookId=$itemId'),
        headers: await _getHeaders(),
      );

      print('📡 API: Response status: ${response.statusCode}');
      print('📡 API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📡 API: Parsed ${data.length} chapters');
        return data.map((json) {
          print('📡 API: Parsing chapter JSON: $json');
          return Chapter.fromJson(json);
        }).toList();
      }
      return [];
    } catch (e, stack) {
      print('📡 API: Error fetching chapters: $e');
      print('📡 API: Stack trace: $stack');
      throw Exception('Failed to fetch chapters: $e');
    }
  }

  // Get chapter metadata only (without content) for lazy loading
  Future<List<Chapter>> fetchChaptersMetadata(int itemId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chapters?bookId=$itemId&metadataOnly=true'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Map with empty content since metadata doesn't include it
        return data.map((json) => Chapter.fromJson({
          ...json,
          'Text': '', // Empty content for metadata-only
        })).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch chapter metadata: $e');
    }
  }

  // Get specific chapter
  Future<Chapter?> fetchChapter(int bookId, int chapterNumber) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chapters?bookId=$bookId&chapterNumber=$chapterNumber'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return Chapter.fromJson(data[0]);
        } else if (data is Map) {
          return Chapter.fromJson(data as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch chapter: $e');
    }
  }

  // Get user profile
  Future<UserProfile?> fetchUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Toggle follow status
  Future<Map<String, dynamic>?> toggleFollow(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/follow'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to toggle follow: $e');
    }
  }

  // Update own profile
  Future<bool> updateUserProfile({String? name, String? bio, List<int>? library}) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/users/profile'),
        headers: await _getHeaders(),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (library != null) 'library': library,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Library management helpers
  Future<bool> addToLibrary(int itemId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) return false;
      
      final profile = await fetchUserProfile(currentUserId);
      if (profile == null) return false;
      
      final newLibrary = List<int>.from(profile.library);
      if (!newLibrary.contains(itemId)) {
        newLibrary.add(itemId);
        return await updateUserProfile(library: newLibrary);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromLibrary(int itemId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) return false;
      
      final profile = await fetchUserProfile(currentUserId);
      if (profile == null) return false;
      
      final newLibrary = List<int>.from(profile.library);
      if (newLibrary.contains(itemId)) {
        newLibrary.remove(itemId);
        return await updateUserProfile(library: newLibrary);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkLibraryStatus(int itemId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) return false;
      
      final profile = await fetchUserProfile(currentUserId);
      if (profile == null) return false;
      
      return profile.library.contains(itemId);
    } catch (e) {
      return false;
    }
  }

  // Download image and save locally
  Future<String?> downloadImage(String imageUrl, String fileName) async {
    try {
      final fullUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '${ApiConstants.baseUrl}/$imageUrl';
      
      final response = await http.get(Uri.parse(fullUrl));
      
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(directory.path, 'images'));
        
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        
        final file = File(p.join(imagesDir.path, fileName));
        await file.writeAsBytes(response.bodyBytes);
        
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Submit a rating
  Future<bool> submitRating(int itemId, double rating) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId/rate'),
        headers: await _getHeaders(),
        body: jsonEncode({'rating': rating}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Create a new literature item on the backend
  // Note: author is automatically set from JWT token on backend
  Future<int?> createItem({
    required String name,
    required String type,
    required String description,
    double review = 0,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/items'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'type': type,
          'description': description,
          'review': review,
          'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['itemId'] as int?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  // Create chapters for an item on the backend
  Future<bool> createChapters(int itemId, List<Map<String, dynamic>> chapters) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chapters'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'itemId': itemId,
          'chapters': chapters,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to create chapters: $e');
    }
  }

  // Update an existing item on the backend
  Future<bool> updateItem({
    required int itemId,
    required String name,
    required String type,
    required String description,
    double review = 0,
    String? imageUrl,
    int? version,
  }) async {
    try {
      final body = jsonEncode({
        'name': name,
        'type': type,
        'description': description,
        'review': review,
        'imageUrl': imageUrl,
        if (version != null) 'version': version,
      });
      
      print('📡 API: Updating item $itemId with data: $body');
      
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId'),
        headers: await _getHeaders(),
        body: body,
      );
      
      if (response.statusCode == 200) {
        print('✅ API: Successfully updated item $itemId');
        return true;
      } else {
        print('❌ API: Update failed for item $itemId - Status: ${response.statusCode}, Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ API: Update exception for item $itemId: $e');
      throw Exception('Failed to update item: $e');
    }
  }

  // Update chapters for an item on the backend
  Future<bool> updateChapters(int itemId, List<Map<String, dynamic>> chapters) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/chapters/$itemId'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'chapters': chapters,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update chapters: $e');
    }
  }

  // Update a single chapter on the backend
  Future<bool> updateChapter(int itemId, int chapterNumber, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/chapters/$itemId/$chapterNumber'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update chapter: $e');
    }
  }

  // Delete a single chapter from the backend
  Future<bool> deleteChapter(int itemId, int chapterNumber) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/chapters/$itemId/$chapterNumber'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete chapter: $e');
    }
  }

  // Delete an item from the backend
  Future<bool> deleteItem(int itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Get user's own items from the backend
  Future<List<LiteratureItem>> fetchMyItems() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/my-items'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LiteratureItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ==================== COMMENTS API ====================

  // Get all comments for an item
  Future<List<Comment>> fetchComments(int itemId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId/comments'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  // Add a comment to an item
  Future<Comment?> addComment(int itemId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId/comments'),
        headers: await _getHeaders(),
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['comment'] != null) {
          return Comment.fromJson(data['comment']);
        }
        return null;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/comments/$commentId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== LIKES API ====================

  // Check if user liked an item
  Future<bool> checkLikeStatus(int itemId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId/like'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['liked'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Fetch changelog since a specific timestamp
  Future<Map<String, dynamic>> fetchChangelog(DateTime since) async {
    try {
      final sinceStr = since.toUtc().toIso8601String();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/changelog?since=$sinceStr'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'changes': data['changes'] as List,
          'count': data['count'] as int,
          'hasMore': data['hasMore'] as bool,
        };
      }
      throw Exception('Failed to fetch changelog: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch changelog: $e');
    }
  }

  // Toggle like for an item
  Future<Map<String, dynamic>?> toggleLike(int itemId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId/like'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'liked': data['liked'] ?? false,
          'likes_count': data['likes_count'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get likes count for an item
  Future<int> getLikesCount(int itemId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId/likes-count'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['likes_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Ping server to check actual connectivity
  /// Returns true if server is reachable, false otherwise
  Future<bool> ping({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/ping'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('📡 API: Ping failed - $e');
      return false;
    }
  }

  /// Check if server is reachable with cached result
  static DateTime? _lastPingTime;
  static bool _lastPingResult = false;
  static const Duration _pingCacheTimeout = Duration(seconds: 30);

  Future<bool> isServerReachable() async {
    final now = DateTime.now();
    
    // Use cached result if recent
    if (_lastPingTime != null && 
        now.difference(_lastPingTime!).compareTo(_pingCacheTimeout) < 0) {
      return _lastPingResult;
    }

    // Perform new ping
    _lastPingResult = await ping();
    _lastPingTime = now;
    return _lastPingResult;
  }
}
