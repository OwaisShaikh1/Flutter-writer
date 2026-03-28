import 'package:flutter/foundation.dart';

enum AppPlatform {
  web,
  android,
  ios,
  windows,
  macos,
  linux,
  unknown,
}

class AppPlatformConfig {
  static AppPlatform get current {
    if (kIsWeb) return AppPlatform.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AppPlatform.android;
      case TargetPlatform.iOS:
        return AppPlatform.ios;
      case TargetPlatform.windows:
        return AppPlatform.windows;
      case TargetPlatform.macOS:
        return AppPlatform.macos;
      case TargetPlatform.linux:
        return AppPlatform.linux;
      default:
        return AppPlatform.unknown;
    }
  }

  static bool get isWeb => current == AppPlatform.web;
  static bool get isAndroid => current == AppPlatform.android;
  static bool get isMobile =>
      current == AppPlatform.android || current == AppPlatform.ios;
  static bool get isDesktop =>
      current == AppPlatform.windows ||
      current == AppPlatform.macos ||
      current == AppPlatform.linux;
}
