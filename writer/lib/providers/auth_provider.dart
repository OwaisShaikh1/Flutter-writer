import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.initial;
  UserProfile? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserProfile? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isLoggedIn = await _storageService.isLoggedIn();
      
      if (isLoggedIn) {
        // Load user info from storage first
        final userId = await _storageService.getUserId();
        final username = await _storageService.getUsername();
        final name = await _storageService.getName();
        
        if (userId != null && username != null) {
          _currentUser = UserProfile(
            id: userId,
            name: name ?? username,
            username: username,
            email: '',
          );
          // User has stored credentials - allow access
          _status = AuthStatus.authenticated;
          
          // Verify token in background - don't block on it
          // Only logout if explicitly invalid (403), not on network errors
          _verifyTokenInBackground();
        } else {
          // No stored user info, force login
          await _authService.logout();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      // On error, if we have stored credentials, stay logged in
      final isLoggedIn = await _storageService.isLoggedIn();
      if (isLoggedIn) {
        final userId = await _storageService.getUserId();
        final username = await _storageService.getUsername();
        if (userId != null && username != null) {
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    }
    
    notifyListeners();
  }

  // Verify token in background without blocking UI
  Future<void> _verifyTokenInBackground() async {
    try {
      final result = await _authService.verifyTokenWithResponse();
      if (result['valid'] == false && result['status'] == 403) {
        // Token explicitly invalid (not just network error)
        await _authService.logout();
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (e) {
      // Network error - stay logged in for offline access
    }
  }

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);
      
      if (result['success']) {
        if (result['user'] != null) {
          _currentUser = UserProfile.fromJson(result['user']);
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String password,
    required String email,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        username: username,
        password: password,
        email: email,
      );
      
      if (result['success']) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registration failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
