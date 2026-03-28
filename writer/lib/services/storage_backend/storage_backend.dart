import 'storage_backend_io.dart'
    if (dart.library.html) 'storage_backend_web.dart';

abstract class StorageBackend {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> deleteAll();
}

StorageBackend createStorageBackend() => createStorageBackendImpl();
