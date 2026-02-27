import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../utils/constants.dart';

class AuthService {
  final StorageService _storage = StorageService();

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save JWT token securely
        if (data['token'] != null) {
          await _storage.saveToken(data['token']);
        }
        
        // Save user info
        if (data['user'] != null) {
          if (data['user']['id'] != null) {
            await _storage.saveUserId(data['user']['id']);
          }
          if (data['user']['username'] != null) {
            await _storage.saveUsername(data['user']['username']);
          }
          if (data['user']['name'] != null) {
            await _storage.saveName(data['user']['name']);
          }
        }
        
        return {'success': true, 'user': data['user']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Login failed'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out. Server may be offline.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String password,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Name': name,
          'username': username,
          'password': password,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _storage.saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Registration failed'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out. Server may be offline.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Verify token
  Future<bool> verifyToken() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verify-token'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      // On timeout or error, return false to allow offline mode
      return false;
    }
  }

  // Verify token with detailed response for background checks
  Future<Map<String, dynamic>> verifyTokenWithResponse() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return {'valid': false, 'status': 401, 'message': 'No token'};

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verify-token'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      return {
        'valid': response.statusCode == 200,
        'status': response.statusCode,
        'message': response.statusCode == 200 ? 'Token valid' : 'Token invalid',
      };
    } catch (e) {
      // Network error - not an explicit token rejection
      return {'valid': null, 'status': 0, 'message': 'Network error: $e'};
    }
  }

  // Logout - clears user credentials but keeps cached data
  Future<void> logout() async {
    await _storage.clearUserData();
  }

  // Get current token
  Future<String?> getToken() => _storage.getToken();

  // Check if logged in
  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  // Get current user ID
  Future<int?> getCurrentUserId() => _storage.getUserId();
}
