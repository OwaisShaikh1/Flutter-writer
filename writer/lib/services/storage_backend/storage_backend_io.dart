import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_backend.dart';

class SecureStorageBackend implements StorageBackend {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

StorageBackend createStorageBackendImpl() => SecureStorageBackend();
