import 'dart:convert';
import 'storage_backend/storage_backend.dart';

class StorageService {
  final StorageBackend _storage = createStorageBackend();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _nameKey = 'user_name';
  static const _pendingDeletesKey = 'pending_deletes';
  static const _chapterDraftIndexKey = 'chapter_draft_index';

  String _chapterDraftKey(int itemId, int chapterNumber) =>
      'chapter_draft_${itemId}_$chapterNumber';

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User ID management
  Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  Future<int?> getUserId() async {
    final idStr = await _storage.read(key: _userIdKey);
    return idStr != null ? int.tryParse(idStr) : null;
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  // Username management
  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<void> deleteUsername() async {
    await _storage.delete(key: _usernameKey);
  }

  // User display name management
  Future<void> saveName(String name) async {
    await _storage.write(key: _nameKey, value: name);
  }

  Future<String?> getName() async {
    return await _storage.read(key: _nameKey);
  }

  Future<void> deleteName() async {
    await _storage.delete(key: _nameKey);
  }

  // Clear all stored data (full reset)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear user-specific data (for logout - keeps base URL)
  Future<void> clearUserData() async {
    await deleteToken();
    await deleteUserId();
    await deleteUsername();
    await deleteName();
    await clearPendingDeletes();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Base URL management
  static const _baseUrlKey = 'base_url';
  static const _defaultBaseUrl = 'https://pokily-unawaked-amado.ngrok-free.app';
  static const _lastSyncServerKey = 'last_sync_server';
  static const _serverInstanceIdKey = 'server_instance_id';

  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _baseUrlKey, value: url);
  }

  Future<String> getBaseUrl() async {
    final url = await _storage.read(key: _baseUrlKey);
    return url ?? _defaultBaseUrl;
  }

  Future<void> deleteBaseUrl() async {
    await _storage.delete(key: _baseUrlKey);
  }
  
  // Track which server we last synced with
  Future<void> saveLastSyncServer(String serverUrl) async {
    await _storage.write(key: _lastSyncServerKey, value: serverUrl);
  }
  
  Future<String?> getLastSyncServer() async {
    return await _storage.read(key: _lastSyncServerKey);
  }
  
  Future<void> deleteLastSyncServer() async {
    await _storage.delete(key: _lastSyncServerKey);
  }
  
  // Track server instance identity
  Future<void> saveServerInstanceId(String instanceId) async {
    await _storage.write(key: _serverInstanceIdKey, value: instanceId);
  }
  
  Future<String?> getServerInstanceId() async {
    return await _storage.read(key: _serverInstanceIdKey);
  }
  
  Future<void> deleteServerInstanceId() async {
    await _storage.delete(key: _serverInstanceIdKey);
  }

  // Pending deletions management (for offline delete sync)
  Future<void> addPendingDelete(int itemId) async {
    final pending = await getPendingDeletes();
    if (!pending.contains(itemId)) {
      pending.add(itemId);
      await _storage.write(key: _pendingDeletesKey, value: jsonEncode(pending));
    }
  }

  Future<List<int>> getPendingDeletes() async {
    final data = await _storage.read(key: _pendingDeletesKey);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e as int).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> removePendingDelete(int itemId) async {
    final pending = await getPendingDeletes();
    pending.remove(itemId);
    await _storage.write(key: _pendingDeletesKey, value: jsonEncode(pending));
  }

  Future<void> clearPendingDeletes() async {
    await _storage.delete(key: _pendingDeletesKey);
  }

  // Chapter draft management (local-only, unpublished chapter edits)
  Future<List<String>> _getChapterDraftIndex() async {
    final data = await _storage.read(key: _chapterDraftIndexKey);
    if (data == null || data.isEmpty) return [];
    try {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _setChapterDraftIndex(List<String> keys) async {
    await _storage.write(key: _chapterDraftIndexKey, value: jsonEncode(keys));
  }

  Future<void> saveChapterDraft({
    required int itemId,
    required int chapterNumber,
    required String title,
    required String content,
  }) async {
    final key = _chapterDraftKey(itemId, chapterNumber);
    await _storage.write(
      key: key,
      value: jsonEncode({
        'itemId': itemId,
        'chapterNumber': chapterNumber,
        'title': title,
        'content': content,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );

    final index = await _getChapterDraftIndex();
    if (!index.contains(key)) {
      index.add(key);
      await _setChapterDraftIndex(index);
    }
  }

  Future<Map<String, dynamic>?> getChapterDraft(int itemId, int chapterNumber) async {
    final key = _chapterDraftKey(itemId, chapterNumber);
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<int, Map<String, dynamic>>> getChapterDraftsForItem(int itemId) async {
    final index = await _getChapterDraftIndex();
    final result = <int, Map<String, dynamic>>{};

    for (final key in index) {
      if (!key.startsWith('chapter_draft_${itemId}_')) continue;
      final raw = await _storage.read(key: key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final number = decoded['chapterNumber'];
          if (number is int) {
            result[number] = decoded;
          }
        } else if (decoded is Map) {
          final map = decoded.cast<String, dynamic>();
          final number = map['chapterNumber'];
          if (number is int) {
            result[number] = map;
          }
        }
      } catch (_) {
        // Ignore malformed draft entries
      }
    }

    return result;
  }

  Future<void> clearChapterDraft(int itemId, int chapterNumber) async {
    final key = _chapterDraftKey(itemId, chapterNumber);
    await _storage.delete(key: key);
    final index = await _getChapterDraftIndex();
    index.removeWhere((k) => k == key);
    await _setChapterDraftIndex(index);
  }

  Future<void> clearChapterDraftsForItem(int itemId) async {
    final index = await _getChapterDraftIndex();
    final toRemove = index.where((k) => k.startsWith('chapter_draft_${itemId}_')).toList();
    for (final key in toRemove) {
      await _storage.delete(key: key);
    }
    index.removeWhere((k) => k.startsWith('chapter_draft_${itemId}_'));
    await _setChapterDraftIndex(index);
  }

  // Last sync timestamp management (for changelog-based sync)
  static const _lastSyncTimestampKey = 'last_sync_timestamp';

  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    await _storage.write(key: _lastSyncTimestampKey, value: timestamp.toIso8601String());
  }

  Future<DateTime?> getLastSyncTimestamp() async {
    final timestampStr = await _storage.read(key: _lastSyncTimestampKey);
    if (timestampStr == null) return null;
    try {
      return DateTime.parse(timestampStr);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteLastSyncTimestamp() async {
    await _storage.delete(key: _lastSyncTimestampKey);
  }
}
