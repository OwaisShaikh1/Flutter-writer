import '../services/storage_service.dart';

class ApiConstants {
  // Default URL for initial app launch
  static const String defaultBaseUrl = 'https://pokily-unawaked-amado.ngrok-free.app';
  
  // Dynamic base URL - can be changed at runtime
  static String _baseUrl = defaultBaseUrl;
  
  static String get baseUrl => _baseUrl;
  
  static set baseUrl(String url) {
    _baseUrl = url;
  }
  
  // Initialize from storage (call at app startup)
  static Future<void> init() async {
    final storage = StorageService();
    _baseUrl = await storage.getBaseUrl();
  }
  
  // Update and persist the baseUrl
  static Future<void> updateBaseUrl(String url) async {
    _baseUrl = url;
    final storage = StorageService();
    await storage.saveBaseUrl(url);
  }
  
  // Reset to default
  static Future<void> resetBaseUrl() async {
    _baseUrl = defaultBaseUrl;
    final storage = StorageService();
    await storage.deleteBaseUrl();
  }
  
  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}

class AppConstants {
  static const String appName = 'Literature Dashboard';
  static const String dbName = 'writer_app.db';
  
  // Filter options
  static const List<String> filterOptions = ['All', 'Drama', 'Poems', 'Novel', 'Article'];
  
  // Sync intervals
  static const Duration autoSyncInterval = Duration(hours: 6);
}

class StorageKeys {
  static const String jwtToken = 'jwt_token';
  static const String userId = 'user_id';
  static const String username = 'username';
  static const String lastSyncTime = 'last_sync_time';
}
