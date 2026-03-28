# Flutter Web Migration (File-by-File)

This document lists the exact code changes needed to make the `writer` Flutter app available as a website, while introducing a **global platform flag** for web/android/future targets.

## 1) Add a global platform flag (single source of truth)

### New file: `lib/config/app_platform.dart`

Create a platform enum + helper so the app has one canonical platform definition:

```dart
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
  static bool get isMobile =>
      current == AppPlatform.android || current == AppPlatform.ios;
  static bool get isDesktop =>
      current == AppPlatform.windows ||
      current == AppPlatform.macos ||
      current == AppPlatform.linux;
}
```

Use this flag everywhere instead of scattered `kIsWeb`, `dart:io` checks, or platform literals.

## 2) Core blockers and required file-by-file changes

### `lib/database/database.dart` (Required)

Current issue:
- Uses `dart:io`, `drift/native.dart`, `File`, and `getApplicationDocumentsDirectory()`.

Required change:
- Split database connection by platform via conditional imports.

Suggested structure:
- `lib/database/connection/connection.dart` (export `openConnection()`)
- `lib/database/connection/connection_io.dart` (NativeDatabase + File path)
- `lib/database/connection/connection_web.dart` (WebDatabase/IndexedDB strategy)

Then in `database.dart`:
- Remove direct `dart:io` and native-only opening logic.
- Use `AppDatabase() : super(openConnection());`

---

### `lib/services/api_service.dart` (Required)

Current issue:
- Imports `dart:io` and `path_provider`.
- `downloadImage()` saves files locally with `Directory`/`File`.

Required change:
- Make `downloadImage()` platform-aware:
  - Web: return remote URL (no local file write)
  - Native: keep existing local cache behavior
- Remove unconditional `dart:io` usage from the main service file.
- Move file-specific logic to a platform-specific image cache helper:
  - `lib/services/image_cache/image_cache_service.dart`
  - `image_cache_service_io.dart`
  - `image_cache_service_web.dart`

---

### `lib/widgets/literature_list.dart` (Required)

Current issue:
- Imports `dart:io`
- Reads `item.imageLocalPath` using `File(...).existsSync()`

Required change:
- Remove direct file checks from widget layer.
- Resolve display image with a helper method that returns:
  - a local file path only on native,
  - otherwise network URL / placeholder.
- Keep widget UI platform-agnostic.

---

### `lib/services/enhanced_api_service.dart` (Required cleanup)

Current issue:
- Imports `dart:io` but does not use it meaningfully.

Required change:
- Remove `dart:io` import to keep web compile clean.

---

### `lib/services/storage_service.dart` (Recommended)

Current state:
- Uses `flutter_secure_storage` for token/base URL persistence.

Action:
- Verify web behavior for `flutter_secure_storage` in your target browser.
- If stability is inconsistent, introduce platform storage adapter:
  - Web fallback: `shared_preferences`
  - Native: `flutter_secure_storage`

Suggested new files:
- `lib/services/platform_storage/platform_storage.dart`
- `platform_storage_secure.dart`
- `platform_storage_web.dart`

---

### `lib/pages/settings_page.dart` (Required UX adjustment)

Current issue:
- Presets include `http://10.0.2.2:3000` and `http://localhost:3000` (mobile/emulator-centric).

Required change:
- Gate presets by `AppPlatformConfig.current`.
- For web, default to public HTTPS backend.
- Keep emulator preset only for Android development.

---

### `lib/utils/constants.dart` (Required)

Current issue:
- Single default base URL only.

Required change:
- Keep `defaultBaseUrl`, but optionally add per-platform defaults:
  - `defaultWebBaseUrl`
  - `defaultMobileBaseUrl`
- Choose at init using global platform flag.

## 3) Dependency updates

### `pubspec.yaml` (Required)

For web DB support, add one supported Drift web stack. Prefer Drift web runtime:

- `drift` (already present)
- `drift_web` or current Drift web-recommended package/runtime for your version

If using sqlite wasm approach, add required wasm/web database dependencies per Drift docs.

Also run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 4) Web host/deploy files

### `web/index.html` (Check)

Current file is fine for standard Flutter web bootstrap.

If deploying under subpath, build with:

```bash
flutter build web --release --base-href /YOUR_SUBPATH/
```

If deploying at domain root:

```bash
flutter build web --release
```

## 5) Backend requirement for website availability

Your frontend can only work publicly if backend is publicly reachable.

### Backend changes (outside `writer` app code but required)

- Deploy API to a public HTTPS host.
- Enable CORS for your web domain(s).
- Replace temporary ngrok URL with stable API domain in app settings/defaults.

## 6) Suggested implementation sequence

1. Add `AppPlatformConfig` global flag file.
2. Refactor DB connection with conditional imports.
3. Refactor image caching/file I/O into platform adapters.
4. Remove `dart:io` imports from shared files.
5. Update settings presets and platform-aware defaults.
6. Build and test:
   - `flutter run -d chrome`
   - `flutter build web --release`
7. Deploy `build/web` to hosting.

## 7) Validation checklist

- [ ] `flutter run -d chrome` starts without compile errors
- [ ] Login/register works from browser
- [ ] Item list/chapters/comments load from backend
- [ ] No browser console CORS errors
- [ ] Offline/local behavior degrades gracefully on web
- [ ] `flutter build web --release` succeeds
- [ ] Hosted URL loads and refreshes correctly

## 8) Notes on future platforms

The new `AppPlatformConfig` keeps platform branching centralized.  
When you add desktop or other targets later, you only extend:

- enum values in `AppPlatform`
- platform-specific adapters (DB/storage/files)
- optional UI presets in settings

without rewriting business logic or UI pages.

