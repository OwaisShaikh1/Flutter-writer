import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _nameKey = 'user_name';
  static const _pendingDeletesKey = 'pending_deletes';

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

  // Clear all stored data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Base URL management
  static const _baseUrlKey = 'base_url';
  static const _defaultBaseUrl = 'https://pokily-unawaked-amado.ngrok-free.app';

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
}
