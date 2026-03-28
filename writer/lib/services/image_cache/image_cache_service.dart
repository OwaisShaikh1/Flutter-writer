import 'image_cache_service_io.dart'
    if (dart.library.html) 'image_cache_service_web.dart';

Future<String?> cacheImageForPlatform(String fullUrl, String fileName) {
  return cacheImageForPlatformImpl(fullUrl, fileName);
}

bool canReadLocalImagePath() => canReadLocalImagePathImpl();
