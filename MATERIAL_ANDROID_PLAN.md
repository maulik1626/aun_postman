# Material Android UI — Implementation Plan

**Branch:** `feature/material-android`  
**Goal:** Android devices render Material 3 UI. iOS devices remain on Cupertino, untouched.  
**Constraint:** Zero business logic changes. Same brand fonts (Satoshi, JetBrainsMono), same CTA gradient (`#FFBD59 → #DB952C`), same brand colors.

**Live status / checklist:** `[MATERIAL_ANDROID_TRACKER.md](MATERIAL_ANDROID_TRACKER.md)` (Done · In progress · audit steps; **Android = Material only**, **iOS = Cupertino only**).

---

## Phase 0 — Platform Detection Foundation

**New file: `lib/app/platform.dart`**

- Single `bool isAndroid` / `bool isIOS` getter wrapping `Platform.isAndroid` / `defaultTargetPlatform`
- One import location, used everywhere — no scattered `Platform.isAndroid` checks inline

---

## Phase 1 — App Entry Point

`**lib/main.dart**`

- Current: `CupertinoApp.router` always
- Change: branch on platform → Android gets `MaterialApp.router`, iOS keeps `CupertinoApp.router`
- Notification init stays iOS-only (unchanged)
- iCloud backup observer stays iOS-only (unchanged)

`**lib/app/app.dart**`

- Extract to `CupertinoAppShell` (existing logic, untouched) and new `MaterialAppShell`
- `MaterialAppShell` uses `MaterialApp.router` with:
  - `ThemeData` seeded from `AppColors.seedColor` (`#DB952C`) using `ColorScheme.fromSeed`
  - `fontFamily: 'Satoshi'` (same custom font)
  - Dark theme via `ThemeData.dark(useMaterial3: true)` with same seed
  - Watches the same `appThemeNotifierProvider` for light/dark/system

---

## Phase 2 — Router

`**lib/app/router/app_router.dart**`

- Current: all routes wrapped in `CupertinoPage`
- Change: on Android, wrap in `MaterialPage` instead
- Navigation transitions: Android gets default Material push/slide, iOS keeps Cupertino right-edge swipe
- Tab shell route stays identical — only the page wrapper changes

---

## Phase 3 — Theme

`**lib/app/theme/app_theme.dart**`

Add `materialThemeLight()` and `materialThemeDark()` builders:


| Property               | Value                                                                   |
| ---------------------- | ----------------------------------------------------------------------- |
| `useMaterial3`         | `true`                                                                  |
| `colorScheme`          | Seeded from `#DB952C`                                                   |
| `fontFamily`           | Satoshi                                                                 |
| `appBarTheme`          | Satoshi titles, brand gold on primary actions                           |
| `navigationBarTheme`   | Material 3 NavigationBar, Satoshi labels, brand gold selected indicator |
| `elevatedButtonTheme`  | Gradient CTA — same `#FFBD59 → #DB952C` via `ShaderMask`                |
| `inputDecorationTheme` | `OutlineInputBorder` with brand gold focus color                        |
| `switchTheme`          | Thumb uses brand gold when active                                       |
| `cardTheme`            | `surfaceVariant` background, small radius                               |
| `dialogTheme`          | Material `AlertDialog` style                                            |


`**lib/app/widgets/app_gradient_button.dart**`

- Current: Cupertino-specific only
- Add `AppGradientButton.material()` factory — `ElevatedButton` wrapped in `ShaderMask` with same `#FFBD59 → #DB952C` gradient, identical visual brand feel

---

## Phase 4 — Shell / Tab Navigation

**New file: `lib/features/shell/shell_screen_material.dart`**

Uses `NavigationBar` (Material 3) with same 4 tabs. Platform switch in router: iOS → existing shell, Android → material shell.


| Tab          | CupertinoIcon (iOS)                 | Material Icon (Android)                  |
| ------------ | ----------------------------------- | ---------------------------------------- |
| Collections  | `folder`                            | `Icons.folder_outlined` / `Icons.folder` |
| History      | `clock`                             | `Icons.history`                          |
| Environments | `list_bullet`                       | `Icons.tune_outlined`                    |
| WebSocket    | `antenna_radiowaves_left_and_right` | `Icons.compare_arrows`                   |


- Satoshi label font, brand gold selected indicator
- Same 4-tab indexed stack behaviour as iOS shell

---

## Phase 5 — Screen by Screen

### 5.1 Collections Screen

**New file: `lib/features/collections/collections_screen_material.dart`**


| Element       | Cupertino (iOS)                            | Material (Android)                                 |
| ------------- | ------------------------------------------ | -------------------------------------------------- |
| Scaffold      | `CupertinoPageScaffold`                    | `Scaffold`                                         |
| App bar       | `CupertinoSliverNavigationBar` large title | `SliverAppBar.large` (M3, collapses)               |
| Title font    | Satoshi 34px bold, brand gold              | Satoshi 32px bold, brand gold (same)               |
| Add button    | `CupertinoButton` with `+` icon in nav bar | `FloatingActionButton.extended` ("New Collection") |
| Search        | `CupertinoSearchTextField` inline          | `SearchBar` (M3) in app bar                        |
| List items    | `Slidable` with cupertino swipe            | `Slidable` with Material swipe-to-reveal           |
| Swipe actions | Red delete / Edit                          | Same, rendered as Material cards                   |
| Drag handle   | Custom drag icon                           | `ReorderableListView` drag handle icon             |
| Empty state   | Centered Cupertino text                    | Centered Material `Card` with brand illustration   |
| Context menu  | `CupertinoActionSheet`                     | `showModalBottomSheet` with `ListTile` actions     |


---

### 5.2 Collection Detail Screen

**New file: `lib/features/collections/collection_detail_screen_material.dart`**


| Element            | Cupertino (iOS)                   | Material (Android)                                 |
| ------------------ | --------------------------------- | -------------------------------------------------- |
| Scaffold           | `CupertinoPageScaffold`           | `Scaffold`                                         |
| App bar            | `CupertinoNavigationBar`          | `AppBar` (Satoshi title, brand gold actions)       |
| Folder tree        | Slidable rows, cupertino style    | `ExpansionTile` with `ListTile` children, slidable |
| Method badge       | `MethodBadge` (shared, no change) | Same `MethodBadge`                                 |
| New request button | Cupertino text button             | `FilledButton.tonal`                               |
| Delete/rename      | `CupertinoAlertDialog`            | `AlertDialog`                                      |


---

### 5.3 Collection Auth Screen

**New file: `lib/features/collections/collection_auth_screen_material.dart`**


| Element          | Cupertino (iOS)          | Material (Android)                        |
| ---------------- | ------------------------ | ----------------------------------------- |
| Scaffold         | `CupertinoPageScaffold`  | `Scaffold`                                |
| Fields           | `CupertinoTextField`     | `TextFormField` with `OutlineInputBorder` |
| Auth type picker | `CupertinoActionSheet`   | `DropdownButtonFormField` (M3)            |
| Save             | `CupertinoButton` filled | `FilledButton` brand gold                 |


---

### 5.4 Request Builder Screen (largest — 1,827 lines)

**New file: `lib/features/request_builder/request_builder_screen_material.dart`**


| Element                                  | Cupertino (iOS)                 | Material (Android)                                        |
| ---------------------------------------- | ------------------------------- | --------------------------------------------------------- |
| Scaffold                                 | `CupertinoPageScaffold`         | `Scaffold`                                                |
| URL bar                                  | `CupertinoTextField`            | `TextField` with prefix method badge dropdown             |
| Method picker                            | `CupertinoActionSheet`          | `DropdownButton<HttpMethod>` with colored items           |
| Send button                              | `AppGradientButton` (Cupertino) | `AppGradientButton.material()`                            |
| Tab bar (Params/Headers/Body/Auth/Tests) | Custom cupertino segment        | `TabBar` (M3, scrollable, brand gold underline indicator) |
| Tab views                                | Custom page view                | `TabBarView`                                              |
| Response area                            | Bottom sheet / inline           | `DraggableScrollableSheet`                                |
| Keyboard dismiss                         | Cupertino idiom                 | `GestureDetector` + `FocusScope.unfocus()`                |
| Action sheet                             | `CupertinoActionSheet`          | `showModalBottomSheet`                                    |
| Save dialog                              | `CupertinoAlertDialog`          | `AlertDialog`                                             |


**Tabs — each gets a material counterpart:**


| Tab     | New File                    | Key Changes                                                                       |
| ------- | --------------------------- | --------------------------------------------------------------------------------- |
| Params  | `params_tab_material.dart`  | `TextFormField` pairs in `ListView`                                               |
| Headers | `headers_tab_material.dart` | Same pattern as Params                                                            |
| Body    | `body_tab_material.dart`    | Body type → `SegmentedButton` (M3); raw → `TextField`; form-data → `ListView`     |
| Auth    | `auth_tab_material.dart`    | Auth type → `DropdownButtonFormField`; fields → `TextFormField`                   |
| Tests   | `tests_tab_material.dart`   | Script editor → `TextField` monospace (JetBrains Mono); results → `ExpansionTile` |


**Shared key-value widgets:**


| Widget                         | Change                                                                                           |
| ------------------------------ | ------------------------------------------------------------------------------------------------ |
| `key_value_editor.dart`        | Add Material variant: `OutlineInputBorder` fields, `Checkbox` enable toggle, `IconButton` delete |
| `form_data_fields_editor.dart` | Same pattern                                                                                     |


---

### 5.5 Response Viewer Sheet

**New file: `lib/features/response_viewer/response_viewer_sheet_material.dart`**


| Element          | Cupertino (iOS)                         | Material (Android)                                       |
| ---------------- | --------------------------------------- | -------------------------------------------------------- |
| Bottom sheet     | `CupertinoModalPopup`                   | `DraggableScrollableSheet` inside `showModalBottomSheet` |
| Status chip      | Cupertino container                     | `Chip` with status color                                 |
| Tab bar          | Custom cupertino segment                | `TabBar` (M3)                                            |
| Syntax highlight | `flutter_highlight` (shared, unchanged) | Same                                                     |
| Copy button      | Cupertino icon button                   | `IconButton`                                             |


---

### 5.6 History Screen

**New file: `lib/features/history/history_screen_material.dart`**


| Element            | Cupertino (iOS)                | Material (Android)                       |
| ------------------ | ------------------------------ | ---------------------------------------- |
| Scaffold           | `CupertinoPageScaffold`        | `Scaffold`                               |
| Nav bar            | `CupertinoSliverNavigationBar` | `SliverAppBar.large`                     |
| Search             | `CupertinoSearchTextField`     | `SearchAnchor` / `SearchBar` (M3)        |
| Date group headers | Cupertino section header style | `ListSubheader` with Satoshi font        |
| History items      | Slidable cupertino rows        | `Slidable` Material rows with `ListTile` |
| Delete             | `CupertinoAlertDialog`         | `AlertDialog`                            |
| Empty state        | Centered text                  | Material `Card` empty state              |


---

### 5.7 Environments Screen

**New file: `lib/features/environments/environments_screen_material.dart`**


| Element             | Cupertino (iOS)                | Material (Android)                         |
| ------------------- | ------------------------------ | ------------------------------------------ |
| Scaffold            | `CupertinoPageScaffold`        | `Scaffold`                                 |
| Nav bar             | `CupertinoSliverNavigationBar` | `SliverAppBar.large`                       |
| Add button          | Nav bar trailing               | `FloatingActionButton`                     |
| Active env selector | Custom cupertino row           | `RadioListTile` (M3) with brand gold radio |
| List items          | Slidable cupertino rows        | `Slidable` Material rows                   |


---

### 5.8 Environment Detail Screen

**New file: `lib/features/environments/environment_detail_screen_material.dart`**


| Element        | Cupertino (iOS)            | Material (Android)                              |
| -------------- | -------------------------- | ----------------------------------------------- |
| Scaffold       | `CupertinoPageScaffold`    | `Scaffold`                                      |
| Key-value rows | `CupertinoTextField` pairs | `TextFormField` pairs with `OutlineInputBorder` |
| Add row button | Cupertino text button      | `TextButton` with `+` icon                      |
| Save           | Nav bar trailing button    | `AppBar` action `IconButton`                    |


---

### 5.9 WebSocket Screen

**New file: `lib/features/websocket/websocket_screen_material.dart`**


| Element                   | Cupertino (iOS)               | Material (Android)                              |
| ------------------------- | ----------------------------- | ----------------------------------------------- |
| Scaffold                  | `CupertinoPageScaffold`       | `Scaffold`                                      |
| Tab bar (up to 8 WS tabs) | Custom cupertino tab strip    | `TabBar` scrollable (M3)                        |
| URL + connect bar         | `CupertinoTextField` + button | `TextField` + `FilledButton` (brand gold)       |
| Message list              | Custom cupertino list         | `ListView` with `Card` per message              |
| Compose bar               | `CupertinoTextField`          | `TextField` with `InputDecoration`              |
| Send button               | Cupertino icon button         | `IconButton` (brand gold)                       |
| Status badge              | Custom cupertino              | `Chip` (connected = green, disconnected = gray) |
| Format picker             | `CupertinoActionSheet`        | `showModalBottomSheet`                          |
| Disconnect                | `CupertinoAlertDialog`        | `AlertDialog`                                   |


---

### 5.10 Settings Screen

**New file: `lib/features/settings/settings_screen_material.dart`**


| Element                        | Cupertino (iOS)              | Material (Android)                           |
| ------------------------------ | ---------------------------- | -------------------------------------------- |
| Scaffold                       | `CupertinoPageScaffold`      | `Scaffold`                                   |
| Nav bar                        | `CupertinoNavigationBar`     | `AppBar`                                     |
| Section groups                 | Cupertino grouped list style | `Card` per section with `ListTile` rows      |
| Toggle (SSL verify, redirects) | `ScaledCupertinoSwitch`      | `Switch` (M3, brand gold thumb)              |
| Theme picker                   | `CupertinoActionSheet`       | `SegmentedButton<ThemePreference>` (M3)      |
| Timeout input                  | `CupertinoTextField`         | `TextFormField`                              |
| iCloud backup toggle           | `CupertinoSwitch` (iOS-only) | Hidden — not shown on Android                |
| Legal links                    | Cupertino rows with chevron  | `ListTile` with trailing `Icons.open_in_new` |
| App version                    | Footer text                  | Same                                         |


---

### 5.11 Default Headers Settings

**New file: `lib/features/settings/default_headers_settings_screen_material.dart`**


| Element     | Cupertino (iOS)            | Material (Android)           |
| ----------- | -------------------------- | ---------------------------- |
| Scaffold    | `CupertinoPageScaffold`    | `Scaffold`                   |
| Header rows | `CupertinoTextField` pairs | `TextFormField` pairs        |
| Add button  | Nav bar button             | `FloatingActionButton.small` |
| Delete      | Swipe action               | `Dismissible` or `Slidable`  |


---

### 5.12 Proxy Settings

**New file: `lib/features/settings/proxy_settings_screen_material.dart`**


| Element       | Cupertino (iOS)      | Material (Android)                        |
| ------------- | -------------------- | ----------------------------------------- |
| Fields        | `CupertinoTextField` | `TextFormField` with `OutlineInputBorder` |
| Enable toggle | `CupertinoSwitch`    | `Switch` (M3)                             |
| Save          | Cupertino button     | `FilledButton`                            |


---

### 5.13 Import / Export Screen

**New file: `lib/features/import_export/import_export_screen_material.dart`**


| Element               | Cupertino (iOS)               | Material (Android)                        |
| --------------------- | ----------------------------- | ----------------------------------------- |
| Scaffold              | `CupertinoPageScaffold`       | `Scaffold`                                |
| Section cards         | Cupertino grouped             | `Card` per section                        |
| Action buttons        | `CupertinoButton`             | `FilledButton.tonal`                      |
| iCloud backup section | Shown only on iOS             | Completely hidden on Android              |
| Progress              | Cupertino indicator           | `CircularProgressIndicator` (M3)          |
| Share position origin | `_shareAnchorRect` (iOS-only) | `null` (Android share sheet is automatic) |


---

## Phase 6 — Shared / Platform-Aware Widgets


| Widget                        | Current                                         | Plan                                                             |
| ----------------------------- | ----------------------------------------------- | ---------------------------------------------------------------- |
| `AppGradientButton`           | Cupertino only                                  | Add `.material()` factory; screen picks correct one              |
| `MethodBadge`                 | Pure color + text — **no change needed**        | Shared as-is                                                     |
| `ScaledCupertinoSwitch`       | iOS only                                        | Keep as-is; Android uses `Switch`                                |
| `GlassContainer` / `GlassBar` | iOS 26 Liquid Glass                             | Android: standard `Card` or `Container` with brand surface color |
| `AuthConfigEditor`            | Uses `CupertinoTextField` internally            | Add Material variant or make it platform-aware                   |
| Dialogs (103 instances)       | `CupertinoAlertDialog` / `CupertinoActionSheet` | Wrap in a platform dialog utility (see below)                    |


**New file: `lib/app/utils/platform_dialogs.dart`**

Replaces 103 scattered Cupertino dialog instances cleanly:

```dart
// iOS → CupertinoAlertDialog
// Android → AlertDialog (M3)
Future<void> showAppAlert(context, title, content, actions)

// iOS → CupertinoActionSheet
// Android → showModalBottomSheet with ListTiles
Future<T?> showAppActionSheet(context, actions)
```

---

## Phase 7 — No-Touch Zones (guaranteed untouched)

The following files require **zero changes**:

- All providers (`*_provider.dart`)
- All domain models (`domain/models/*.dart`, `domain/enums/*.dart`)
- All core utilities (`core/utils/*.dart`, `core/errors/`, `core/constants/`)
- Data layer (`data/local/hive_service.dart`)
- Infrastructure layer
- iCloud backup channel (`core/platform/icloud_backup_channel.dart`)
- Notification service (`core/notifications/user_notification.dart`)
- All existing Cupertino screens — **not modified, not deleted**

---

## Phase 8 — Test Update

`**test/no_material_import_test.dart`**

- Update to allow `material` imports in `*_material.dart` files and `app/app.dart`

**New file: `test/no_cupertino_in_material_test.dart`**

- Verifies `_material.dart` files don't accidentally import Cupertino widgets

---

## Summary


|                                   | Count                                                                                                                        |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| New `_material.dart` screen files | ~25                                                                                                                          |
| New utility files                 | 2 (`platform.dart`, `platform_dialogs.dart`)                                                                                 |
| Theme builders added              | 2 (`materialThemeLight`, `materialThemeDark`)                                                                                |
| Files modified                    | 6 (`main.dart`, `app.dart`, `app_router.dart`, `app_theme.dart`, `app_gradient_button.dart`, `no_material_import_test.dart`) |
| Files untouched                   | Every provider, model, utility, data layer, and all existing Cupertino screens                                               |


---

## Implementation Order (after approval)


| Step | Phase           | Description                                                                                                                      |
| ---- | --------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Phase 0         | Platform utility                                                                                                                 |
| 2    | Phase 1 + 2 + 3 | App shell, router, theme (foundation)                                                                                            |
| 3    | Phase 6         | Dialog utility + `AppGradientButton.material()`                                                                                  |
| 4    | Phase 4         | Shell / tab bar (makes app launchable on Android)                                                                                |
| 5    | Phase 5         | Screens: Shell → Collections → Request Builder → History → Environments → WebSocket → Settings → Import/Export → Response Viewer |
| 6    | Phase 7         | Verify no-touch zones untouched                                                                                                  |
| 7    | Phase 8         | Test update                                                                                                                      |


