import 'package:shared_preferences/shared_preferences.dart';
import 'storage_backend.dart';

class SharedPrefsStorageBackend implements StorageBackend {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<void> write({required String key, required String value}) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  @override
  Future<String?> read({required String key}) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  @override
  Future<void> delete({required String key}) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}

StorageBackend createStorageBackendImpl() => SharedPrefsStorageBackend();
