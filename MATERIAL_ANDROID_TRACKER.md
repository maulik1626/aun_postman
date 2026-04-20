# Material Android UI — Implementation Tracker

> Last updated: **2026-04-06** · Branch: `feature/material-android`  
> Status legend: ✅ Done · 🔨 In Progress · ⚠️ Partial · ❌ Not Started · 🐛 Bug

## Non-negotiable rules

1. **Android:** UI is **Material 3 only** (`package:flutter/material.dart`, Material widgets). No `Cupertino*` widgets on Android user flows.
2. **iOS:** UI is **Cupertino only** for screens (`package:flutter/cupertino.dart`). No `Material*` scaffolds/app bars on iOS user flows.
3. **Routing:** `AppPlatform.isAndroid` / `AppPlatform.isIOS` (`lib/app/platform.dart`) choose the correct screen widget — **no** mixing inside one screen file.
4. **Business logic:** Providers, models, DAOs, execution — **unchanged** (shared).

This file is maintained against `**lib/`**. Re-audit after substantive UI work.

---

### Quick re-audit checklist

1. `flutter analyze` and `dart test` from repo root.
2. `lib/app/app.dart` — `_MaterialAppShell` only when `AppPlatform.isAndroid`, `_CupertinoAppShell` only when iOS.
3. `lib/app/router/app_router.dart` — every **pushed route** uses `*Material` on Android and Cupertino screen on iOS.
4. `rg 'Cupertino' lib --glob '*_material.dart'` — must be **empty** (no Cupertino imports in Material files).
5. `rg 'material.dart' lib/features --glob '*.dart' | grep -v _material` — only router/app/theme/gradient allowlist (see `test/no_material_import_test.dart`).
6. **`flutter build apk --release`** — confirms the Android Gradle project and release APK (output: `build/app/outputs/flutter-apk/app-release.apk`).

---

## Android native project (`android/`)

| # | Item | Status | Notes |
| --- | ---- | ------ | ----- |
| N.1 | `android/` present (Flutter template) | ✅ | Add with `flutter create . --platforms=android` if missing |
| N.2 | Core library **desugaring** enabled | ✅ | Required by `flutter_local_notifications` — `isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs` in `android/app/build.gradle.kts` |
| N.3 | Release APK builds | ✅ | `flutter build apk --release` |
| N.4 | **Permissions & queries** in `android/app/src/main/AndroidManifest.xml` | ✅ | `INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `VIBRATE`; `usesCleartextTraffic` for HTTP/ws dev; `<queries>` for `url_launcher`, `share_plus`, `file_picker`, Flutter text processing |
| N.5 | **Launcher icons** match iOS | ✅ | Source: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` → `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`; adaptive (`mipmap-anydpi-v26/`) + `@color/ic_launcher_background` `#DB952C`; `ic_launcher_foreground` + legacy `ic_launcher_round.png` |

---

## Phase A — Foundation


| #   | Item                                                                                                            | Status | Notes                                      |
| --- | --------------------------------------------------------------------------------------------------------------- | ------ | ------------------------------------------ |
| A.1 | `lib/app/platform.dart` (`AppPlatform.isAndroid` / `isIOS`)                                                     | ✅      | Single source for branching                |
| A.2 | `main.dart` — `ProviderScope`, Hive init; iOS-only notification + iCloud wrapper                                | ✅      | No platform UI here                        |
| A.3 | `lib/app/app.dart` — `MaterialApp.router` vs `CupertinoApp.router`                                              | ✅      | `_MaterialAppShell` / `_CupertinoAppShell` |
| A.4 | `lib/app/router/app_router.dart` — `MaterialPage` vs `CupertinoPage` + **Material vs Cupertino screen widgets** | ✅      | See imports in router                      |
| A.5 | `lib/app/theme/app_theme.dart` — `materialThemeLight` / `materialThemeDark`                                     | ✅      | Brand seed `#DB952C`                       |
| A.6 | `AppGradientButton.material()`                                                                                  | ✅      | `lib/app/widgets/app_gradient_button.dart` |
| A.7 | `lib/app/utils/platform_dialogs.dart`                                                                           | 🔨     | Present; optional wider adoption           |


---

## Phase B — Shell


| #   | Item                           | Status | Notes              |
| --- | ------------------------------ | ------ | ------------------ |
| B.1 | Android: `ShellScreenMaterial` | ✅      | `NavigationBar` M3 |
| B.2 | iOS: `ShellScreen` (Cupertino) | ✅      | Unchanged          |


---

## Phase C — Feature screens (router-mapped)


| #    | Feature            | Android (`*_material.dart`)            | iOS (existing)                 | Status |
| ---- | ------------------ | -------------------------------------- | ------------------------------ | ------ |
| C.1  | Collections list   | `CollectionsScreenMaterial`            | `CollectionsScreen`            | ✅      |
| C.2  | Collection detail  | `CollectionDetailScreenMaterial`       | `CollectionDetailScreen`       | ✅      |
| C.3  | Collection auth    | `CollectionAuthScreenMaterial`         | `CollectionAuthScreen`         | ✅      |
| C.4  | Request builder    | `RequestBuilderScreenMaterial`         | `RequestBuilderScreen`         | ✅      |
| C.5  | History            | `HistoryScreenMaterial`                | `HistoryScreen`                | ✅      |
| C.6  | Environments list  | `EnvironmentsScreenMaterial`           | `EnvironmentsScreen`           | ✅      |
| C.7  | Environment detail | `EnvironmentDetailScreenMaterial`      | `EnvironmentDetailScreen`      | ✅      |
| C.8  | WebSocket          | `WebSocketScreenMaterial`              | `WebSocketScreen`              | ✅      |
| C.9  | Settings           | `SettingsScreenMaterial`               | `SettingsScreen`               | ✅      |
| C.10 | Default headers    | `DefaultHeadersSettingsScreenMaterial` | `DefaultHeadersSettingsScreen` | ✅      |
| C.11 | Proxy              | `ProxySettingsScreenMaterial`          | `ProxySettingsScreen`          | ✅      |
| C.12 | Import / export    | `ImportExportScreenMaterial`           | `ImportExportScreen`           | ✅      |


Nested UI (e.g. response viewer) is embedded inside request builder per platform — Material builder uses `ResponseViewerSheetMaterial`.

---

## Phase D — Tests & guards


| #   | Item                                                                                                                | Status | Notes                             |
| --- | ------------------------------------------------------------------------------------------------------------------- | ------ | --------------------------------- |
| D.1 | `test/no_material_import_test.dart` — non-`*_material` lib files must not import `material.dart` (except allowlist) | ✅      | Protects iOS Cupertino codebase   |
| D.2 | `test/no_cupertino_in_material_test.dart` — `*_material.dart` must not import `cupertino.dart`                      | ✅      | Protects Android Material screens |


---

## Progress tracker


| Metric                           | Count                                                            |
| -------------------------------- | ---------------------------------------------------------------- |
| Foundation phases (A–B)          | 9 / 9 items ✅                                                    |
| Router-mapped screens (C.1–C.12) | 12 / 12 ✅                                                        |
| Test guards (D)                  | 2 / 2 ✅                                                          |
| **Open follow-ups**              | Wider `platform_dialogs` adoption; tablet/two-pane QA on Android |


---

## Implementation order (reference)

1. Platform + app shell + router page wrappers + theme
2. Shell Material
3. Per-screen `*_material.dart` + router wiring
4. Tests

---

## Related doc

See `**MATERIAL_ANDROID_PLAN.md`** for the original detailed UI mapping tables (widgets per screen).