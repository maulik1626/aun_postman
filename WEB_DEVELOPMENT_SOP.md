# AUN ReqStudio Web Development SOP

**Status:** planning standard  
**Last updated:** 2026-04-25  
**Scope:** Flutter web version of AUN ReqStudio, with compact web following the Android product flow and tablet/desktop web using a mature Postman-like panel workspace rendered through a custom AUN SaaS component system.  
**Non-negotiable:** same product flow and same business logic unless browser platform constraints require a platform adapter.  
**UI direction:** web UI is custom, component-first, reusable, and brand-consistent. It is not raw Material 3.

---

## 1. Current App Assessment

### 1.1 Product and architecture facts

- The app is a Flutter API client named `aun_reqstudio`.
- Current product surfaces are iOS and Android.
- State management is Riverpod (`flutter_riverpod`, `riverpod_annotation`).
- Navigation is `go_router` with a `StatefulShellRoute.indexedStack` for the primary tabs.
- Local persistence uses Hive JSON-string boxes opened in `lib/data/local/hive_service.dart`.
- Auth uses Firebase Auth plus an app-level backend session artifact.
- Request execution uses `DioClient` and persists history entries.
- WebSocket flows use `web_socket_channel` and dedicated Riverpod session providers.
- Import/export is JSON based, with Postman-compatible collection/environment flows.
- Existing UI split:
  - iOS uses Cupertino screen files.
  - Android uses Material 3 `*_material.dart` screen/widget files.
  - Web must not inherit Android Material styling as the final UI. It may reuse proven flow/business logic, but must render through custom reusable web components.
  - Router selection currently uses `AppPlatform.isAndroid`, so web would not get its own custom UI until the platform rule and app/router code are updated.

### 1.2 Existing responsive behavior

- `lib/app/platform.dart` already has adaptive breakpoint helpers:
  - tablet: shortest side >= 600dp
  - expanded: width >= 840dp
- `ShellScreenMaterial` already maps:
  - `< 600dp`: bottom `NavigationBar`
  - `600-839dp`: `NavigationRail`
  - `>= 840dp`: extended `NavigationRail`
- `CollectionsScreenMaterial` already has a two-pane collection/detail layout at `>= 840dp`.
- Request builder already has keyboard shortcuts:
  - Cmd/Ctrl + Enter: send/cancel
  - Cmd/Ctrl + S: save
  - Cmd/Ctrl + 1..5: switch request tabs

### 1.3 Current web readiness blockers

Verified command:

```sh
/Users/maulikraja/FlutterDev/flutter/bin/flutter build web --release
```

Current result:

```text
This project is not configured for the web.
To configure this project for the web, run flutter create . --platforms web
```

Before production web work can start, these blockers must be handled:

- No `web/` platform folder exists yet.
- `lib/firebase_options.dart` throws `UnsupportedError` for `kIsWeb`.
- `lib/app/app.dart` and `lib/app/router/app_router.dart` choose Material only for Android, not web.
- `main.dart` currently forces portrait orientation before app start; web must not be orientation locked.
- Many compile paths import `dart:io`, which is not available on web.
- `DioClient` is guarded for IO adapter setup, but still imports `dart:io` and uses file-path based multipart APIs.
- Import/export, response sharing, collection sharing, screenshot feedback, and environment export currently write `File` objects to temporary directories.
- `google_mobile_ads` is Android/iOS only; all ad widgets/services must be excluded or replaced on web.
- `webview_flutter` does not support web; HTML preview and legal document display need web-native alternatives.
- `SystemNavigator.pop`, platform channels, iCloud backup, screenshot event channels, and Android/iOS notification behavior must be no-op or replaced on web.
- Browser HTTP and WebSocket behavior cannot fully match a native Postman-style client without a relay/proxy service because CORS, forbidden headers, TLS behavior, cookie visibility, redirects, and custom WebSocket headers are browser-controlled.

---

## 2. Product Target

### 2.1 Platform behavior

- iOS remains Cupertino.
- Android remains on the existing Material path.
- Web uses a custom AUN SaaS component system, not raw Material 3.
- Compact web widths must behave like the Android product flow while using custom web components.
- Tablet and desktop web must adapt into a panel workspace.
- Web must support keyboard, mouse, trackpad, touch, and browser expectations.
- Mobile-sized web must be responsive and usable, even if tablet and above are the primary web target.
- CTA gradient, brand colors, `Satoshi`, `JetBrainsMono`, method/status colors, spacing rhythm, and interaction tone must remain consistent with the native app UX.

### 2.2 Responsive breakpoints

Use one shared breakpoint vocabulary for all web work:

| Width | Class | Required behavior |
| --- | --- | --- |
| `< 600dp` | compact | Android-like single-column flow, custom bottom/shell navigation, no horizontal overflow |
| `600-839dp` | medium | rail navigation, single primary content column, optional secondary preview |
| `840-1199dp` | expanded | two-pane layouts where natural, rail/side nav, persistent detail pane |
| `>= 1200dp` | desktop | Postman-like workspace with persistent navigation, collection tree, request editor, response panel |
| `>= 1600dp` | wide desktop | same workspace, wider editor/response area, no oversized typography or stretched controls |

Every changed screen must be verified at minimum viewports:

- 390 x 844
- 768 x 1024
- 1024 x 768
- 1280 x 800
- 1440 x 900
- 1920 x 1080

### 2.3 Desktop workspace target

At desktop widths, the main API-client workspace should be:

- a single left explorer pane that owns Import/Export, the section switcher, and the active section explorer,
- exactly four primary explorer sections under Import/Export: Collections, History, Envs, and WebSockets,
- Collections rendered directly as a VS Code-style collection tree in the left pane,
- no desktop middle collection-detail pane between the explorer and request workspace,
- a right-side request workspace with Chrome/Postman-style request tabs,
- each request tab containing its own request editor, response state, tests, request-builder subtab selection, and UI state,
- API requests opened in tabs on the right/workspace area, with close, dirty, sending, response-ready, duplicate, reorder, and restore behavior,
- auto-save and draft restore that never loses user work during route changes, refresh, resize, or sign-in state transitions,
- environment/variables access without leaving the request flow,
- history replay integrated without destroying current request state,
- all panes keyboard reachable and scroll independent,
- route/deep-link aware so refresh and browser back/forward keep the user in a predictable state.

The goal is not a marketing web page. The first screen after auth is the actual working application.

---

## 3. Architecture Standard

### 3.1 Platform decision API

`lib/app/platform.dart` must become the only place for app-level platform decisions.

Required direction:

```dart
abstract final class AppPlatform {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get usesAndroidMaterialUi => isAndroid;
  static bool get usesWebCustomUi => isWeb;
  static bool get usesCupertinoUi => isIOS;
}
```

Feature code must use `usesAndroidMaterialUi`, `usesWebCustomUi`, `usesCupertinoUi`, or form-factor helpers instead of scattered `kIsWeb`, `defaultTargetPlatform`, or `Platform` checks.

### 3.2 UI file ownership

- Cupertino UI remains in non-`*_material.dart` screen files unless a file is explicitly shared and has no Material import.
- Android/mobile Material UI remains in `*_material.dart` files.
- Web UI must be custom component UI. It may reuse Android flow concepts, providers, route state, and business logic, but not raw Android Material screen styling as the final web UI.
- Web screens/components may use `*_web.dart`, `*_web_component.dart`, or `web/` subfolders only if the platform guard tests are updated in the same change.
- No Cupertino imports in Android Material or web UI files.
- No Material imports in iOS feature screen files.
- Flutter Material widgets may be used in web only as wrapped infrastructure inside app-owned components. Feature screens must not directly scatter one-off `ElevatedButton`, `Card`, `TabBar`, `AlertDialog`, `TextField`, table, chip, or menu styling.
- Shared providers, repositories, models, import/export utilities, auth merge logic, assertion runner, and request/response models must stay UI-independent.

### 3.3 Custom web design system

All web UI must be built from a reusable AUN web component system. The component system is a product-quality design system, not a folder of incidental widgets.

Required structure once web implementation begins:

- `lib/app/web_ui/tokens/`
  - colors, gradients, typography, spacing, radius, border, elevation, motion, z-index, and breakpoints.
- `lib/app/web_ui/components/`
  - buttons, icon buttons, inputs, text areas, select/menu, segmented controls, checkboxes/toggles, tabs, tables, chips, badges, tooltips, dialogs, drawers, sheets, command palette, pane headers, splitters, empty states, loading states, banners, toasts, breadcrumbs, tree rows, request tabs, response panels, code blocks, and virtualized lists.
- `lib/app/web_ui/layout/`
  - responsive shell, workspace grid, resizable panes, scroll regions, focus scopes, keyboard shortcut scopes, and browser-safe overlays.
- `lib/app/web_ui/patterns/`
  - request editor, response viewer, collection tree, history table, environment editor, auth form, import/export flow, settings sections, and WebSocket console patterns.

Component-first rule for every web UI task:

1. Search the web component library first.
2. Reuse the existing component if it satisfies the behavior.
3. Extend the component with token-driven variants if the behavior is generally reusable.
4. Create a new reusable component if it does not exist.
5. Use the component in the feature only after it has its states, accessibility, responsive behavior, and tests.

Never create a one-off styled control in a feature screen when it could become a reusable component.

Component quality requirements:

- Every component uses shared tokens for visual decisions.
- Every component has explicit hover, focus, pressed, disabled, loading, empty, selected, error, warning, and success states where applicable.
- Every icon-only component has a tooltip and semantic label.
- Components expose narrow, typed APIs and do not leak feature-specific models unless they live in `patterns/`.
- Components must be small enough to test and reason about.
- Components must be responsive by construction, not patched per screen.
- Components must preserve the brand CTA gradient (`#FFBD59` to `#DB952C`) and brand color language.
- `Satoshi` remains the interface font and `JetBrainsMono` remains the code/request/response font.
- Letter spacing, density, and typography must be consistent across screens.
- Motion must be subtle, fast, and purposeful. Do not animate large response rendering or core editor operations in ways that hurt performance.

### 3.4 Platform adapters

Browser-only and IO-only behavior must sit behind adapters. Do not put `dart:io`, `dart:html`, `package:web`, method channels, or plugin-specific platform behavior directly inside feature screens.

Required adapter areas:

- `RequestTransport`
  - mobile IO transport using current Dio behavior,
  - web browser direct transport for CORS-compatible targets,
  - web relay transport for production-grade arbitrary API calls.
- `FileImportExportService`
  - mobile path/file implementation,
  - web bytes/blob/download implementation.
- `ShareExportService`
  - mobile share sheet implementation,
  - web download/Web Share API implementation using in-memory bytes.
- `HtmlPreviewService`
  - mobile `webview_flutter`,
  - web sandboxed iframe/new-tab/blob preview with sanitization and clear origin boundaries.
- `CrashReportingService`
  - mobile Firebase Crashlytics,
  - web-compatible analytics/error reporting path or no-op until selected.
- `AdsService`
  - mobile AdMob only,
  - web disabled or replaced by a separate web monetization decision.
- `SystemServices`
  - orientation lock, system navigation, screenshot events, notifications, iCloud, haptics, and platform channels.

### 3.5 HTTP and WebSocket production requirement

A browser cannot be a full native API client by itself. For production parity with mobile and Postman-like behavior, web must use a backend relay for requests that need any of the following:

- endpoints without CORS headers,
- custom forbidden headers,
- custom TLS or ignoring invalid TLS,
- proxy settings,
- full cookie/header inspection,
- request bodies/files that require server-side normalization,
- redirects and response metadata beyond browser exposure,
- WebSocket custom headers or behavior the browser WebSocket API blocks.

The request builder, history, collections, variables, auth merge, and assertion logic remain shared. Only the final transport changes.

Minimum production transport contract:

- authenticated relay calls using Firebase/backend session,
- request payload matches existing `HttpRequest` model,
- response payload matches existing `HttpResponse` model,
- timeout/cancel support,
- streaming-safe limits and size caps,
- audit logging without secrets,
- per-user rate limiting,
- SSRF protection, private-network restrictions, and allow/block policy,
- file upload/download support,
- clear user-facing error messages for CORS/direct-browser limitations.

### 3.6 Postman-like workspace state model

The desktop web app must behave like a mature API workspace, not a sequence of mobile pages.

Required workspace model:

- `openTabs`: ordered request/API tabs.
- `activeTabId`: currently focused request tab.
- `selectedCollectionUid` and selected tree item.
- left explorer section state for Collections, History, Envs, and WebSockets.
- per-tab request draft state.
- per-tab saved request identity, if attached to a collection request.
- per-tab provider/container scope or equivalent isolation boundary.
- per-tab dirty flag, last saved time, auto-save status, and conflict state.
- per-tab response reference and response render state.
- per-tab history replay metadata when opened from history.
- persisted pane layout preferences.
- persisted tab restore snapshot scoped to the authenticated user/session policy.

Request tab requirements:

- Open request from collection, history, import, or command palette.
- Create new unsaved request tab.
- Duplicate tab/request.
- Close tab, close others, close saved tabs, and confirm close for risky unsaved state.
- Reorder tabs where supported.
- Restore tabs after browser refresh when account/session policy allows it.
- Show dirty, saving, saved, failed-save, sending, cancelled, and response-ready states.
- Keep request editor, response panel, test results, search state, and scroll positions scoped to the correct tab.
- Keep inactive request tabs mounted so switching tabs preserves draft text, response data, tests, selected request-builder subtab, focus-recoverable UI state, and scroll-ish widget state.
- Dispose closed tabs by removing their isolated subtree/container.
- Opening a saved request already represented by an open tab must focus the existing tab instead of creating a duplicate.
- Dirty, new unsaved, or sending tabs must require explicit confirmation before close.
- Do not let one tab's response processing block editing or shortcuts in another tab.

Auto-save requirements:

- Auto-save must be debounce-based, serialized, and resilient to rapid edits.
- Auto-save must never overwrite newer user edits with stale async completions.
- Draft persistence must be scoped by user/session, collection, folder, request, and tab identity.
- Save failures must keep local drafts and show quiet but discoverable recovery UI.
- Explicit Save must flush pending auto-save first.
- Browser refresh, route changes, pane resize, and auth token refresh must not lose edits.

### 3.7 Response scale policy

Responses are first-class product data and must be handled carefully at every size.

Required response tiers:

- small: full syntax highlight, pretty, tree, search, tests, copy, and preview where safe.
- medium: full render with background processing for expensive parsing/search.
- large: progressive rendering, virtualized body, cancellable pretty/search/tree work, and clear processing states.
- extra-large: bounded memory, no duplicate full copies, safe truncation metadata, download-first fallback, raw streaming/preview where supported, and explicit UI explaining disabled expensive features.

Response implementation requirements:

- Keep raw bytes/string, formatted text, search index, JSON tree, and preview data as separate lifecycle-managed artifacts.
- Avoid keeping more full-size copies than necessary.
- All expensive parsing/search/pretty operations must be cancellable or safely ignorable when the active tab changes.
- Response panel must keep the app interactive during processing.
- Failed parsing, invalid JSON, binary data, unsupported previews, huge HTML, and unsafe HTML must have clear states.
- HAR export and body download must work even when inline render is limited.

---

## 4. Mandatory Engineering Standards For Every Web Change

Every web task must satisfy all applicable items below before it is considered done.

### 4.1 Behavior and business logic

- Preserve existing mobile business behavior unless the task explicitly changes product behavior.
- Put web differences in adapters, app shell, router, design-system components, or layout primitives.
- Do not fork business logic into web-specific copies.
- Keep route semantics stable and browser back/forward predictable.
- Preserve unsaved request drafts, auto-save behavior, selected environment, request state, history replay, and response state across layout changes.
- Every new user-visible error path must be typed, testable, and actionable.
- Mature SaaS quality is required: predictable workflows, strong state recovery, clear empty/error/loading states, consistent density, and no "demo-quality" UI.

### 4.2 Component-first UI standard

- Before adding any web UI, search the custom component library first.
- Reuse existing components whenever possible.
- If a component almost fits, extend it through variants/tokens instead of copying styles into a feature.
- If no component exists, create a reusable component first and then build the feature with it.
- Feature screens compose components and patterns; they do not invent visual styling locally.
- The same CTA gradient, fonts, method/status color system, border/radius language, focus rings, spacing, and panel density must be used everywhere.
- Web UI must feel like one mature SaaS product: consistent command placement, consistent toolbar hierarchy, consistent tab behavior, consistent keyboard shortcuts, and consistent feedback.
- UX is a first-class requirement and must not be sacrificed for speed of implementation. Performance is also non-negotiable, so UX decisions must be efficient and testable.
- Any new component must include:
  - all relevant states,
  - keyboard and mouse behavior,
  - semantics/accessibility labels,
  - responsive constraints,
  - tests or screenshot coverage,
  - documentation through examples or usage notes when the API is not obvious.

### 4.3 Compile safety

- Web compile paths must not import `dart:io`.
- IO compile paths must not import browser-only libraries.
- Use conditional imports or platform interface packages for platform services.
- Unsupported plugins must be gated before import or moved behind platform-specific implementations.
- `flutter build web --release` must pass before a web feature is merged.

### 4.4 Responsive UI

- No overflow errors at required viewports.
- No clipped text inside buttons, tabs, chips, table cells, or panels.
- No desktop screen may be a stretched phone layout.
- No panel may depend on fixed full-screen heights without min/max constraints.
- Use `LayoutBuilder`, stable pane constraints, and scrollable regions deliberately.
- Maintain independent scroll for collection tree, editor tabs, response body, and logs.
- Use resizable panes only with persisted user preference and sane reset behavior.
- Touch targets must remain at least 44dp where touch is expected.
- Mouse targets can be denser on desktop but must keep tooltips and focus states.
- All responsive behavior must be smooth across intermediate widths, not only at named breakpoints.
- Pane collapse/expand behavior must preserve selection, scroll position, active tabs, response state, and dirty request state.

### 4.5 Native web interaction

- Keyboard-only use must complete the main request flow.
- Every icon-only button must have a tooltip.
- Focus order must be logical.
- Hover, active, disabled, loading, empty, and error states are mandatory.
- Browser refresh must not corrupt persisted state.
- Browser back/forward must navigate app routes, not lose in-progress edits without confirmation.
- Text selection, copying, downloads, drag/drop, paste, and context menus must feel native.
- Do not override browser shortcuts unless the app behavior is clearly superior and discoverable.
- Request tabs must behave like a professional web app: dirty indicator, close confirmation when needed, restore after refresh, duplicate, reorder where supported, and keyboard traversal.
- Auto-save must be visible enough to trust but quiet enough not to distract.

### 4.6 Accessibility

- Use semantic labels for icon-only controls and status chips.
- Ensure keyboard focus indicators are visible.
- Validate color contrast in light and dark themes.
- Dialogs, sheets, command palette, and menus must trap/release focus correctly.
- Dynamic request/response status changes must be announced where appropriate.
- E2E checks must include keyboard-only smoke coverage for core flows.

### 4.7 Session, auth, and account state

- Auth bootstrap must have explicit loading, setup-error, signed-out, signed-in, token-refresh, and sign-out states.
- Login must be resilient to popup blockers, provider cancellation, network failure, and refresh during auth.
- Session persistence must be tested across refresh, new tab, browser restart where supported, sign-out, token expiry, and offline transitions.
- Backend session artifacts must be validated before protected data or relay access is trusted.
- Logout must clear user-scoped providers, local user data that should not survive logout, relay session state, active tabs if policy requires it, and sensitive in-memory response/request data.
- Multi-tab browser behavior must be defined: auth state, logout, active session invalidation, and local persistence cannot drift silently.
- Route guards must never expose protected screens before auth readiness is known.
- Import/export, history, collections, environments, WebSocket sessions, and request drafts must have a clear account ownership policy before sync or relay features are added.

### 4.8 Security and privacy

- No secrets in logs, URLs, analytics, screenshots, exported filenames, or error reports.
- Never render arbitrary HTML responses in the app origin without sandboxing.
- Web relay must enforce authentication, rate limits, request size limits, timeout limits, private IP protections, and response size caps.
- Downloads must use safe filenames and correct MIME types.
- Token storage must be reviewed for web. Prefer Firebase Auth persistence plus backend-managed secure session strategy over long-lived client-stored secrets.
- CSP, HSTS, frame restrictions, and hosting headers must be part of release readiness.

### 4.9 Performance and large response handling

- Large and extra-large response viewing must stay responsive.
- Pretty formatting, search indexing, JSON tree building, syntax highlighting, and test assertion evaluation must not block the UI thread for large payloads.
- Keep response virtualization and progressive rendering policies in sync with `docs/response_viewer_performance.md`.
- Track app start, first interactive, route transition time, send-to-response render time, and large response scroll performance.
- Build size budget must be set once the first web release build exists.
- Test both default CanvasKit build and, after package audit, WebAssembly/Skwasm builds.
- Define payload thresholds for inline render, progressive render, plain-text fallback, download-only fallback, search indexing, JSON tree availability, and syntax highlighting.
- Extra-large response actions must be cancellable where possible.
- The response pane must not freeze request tabs, URL editing, collection tree scrolling, or shortcut handling.
- Memory use must be bounded. Avoid keeping multiple full copies of the same large response in formatted/raw/search/tree state.
- Show clear UX for truncation, streaming, parsing failure, unsupported preview, and download fallback.

### 4.10 Testing

- Every behavior change gets unit and/or widget tests.
- Every layout change gets responsive widget or screenshot coverage for compact, tablet, and desktop.
- Every core web flow gets integration/E2E coverage.
- Platform guard tests must be updated whenever file naming or platform UI rules change.
- No test may depend on live third-party APIs unless it is explicitly marked external/manual.
- Component changes require component-level tests before feature-level E2E tests.
- Response performance changes require tests with large and extra-large fixtures.
- Auth/session changes require refresh, logout, token failure, and route-guard tests.

### 4.11 Engineering workflow and code quality

Every web task must follow this workflow:

1. Read the existing feature/provider/state/component code before designing the change.
2. Identify which existing component or pattern should own the UI.
3. If no component exists, create or extend the component first.
4. Define the state model before wiring UI events.
5. Implement the smallest coherent slice with tests.
6. Verify compact, tablet, desktop, keyboard, mouse, and large-data behavior.
7. Update docs/rules when the pattern becomes reusable.

Code quality requirements:

- No large feature files that mix platform branching, business logic, layout, styling, and IO.
- Keep screen files as composition layers. Put reusable behavior in components, patterns, providers, services, or adapters.
- Use typed state objects for workspace tabs, auto-save, response rendering, and session status.
- Avoid boolean soup. Prefer explicit enums/sealed states for loading, saving, sending, parsing, auth, and error states.
- Avoid duplicated layout constants. Use tokens.
- Avoid duplicated strings for actions, shortcuts, and common status labels. Centralize where practical.
- No silent catch blocks for production behavior. Errors must be logged or mapped to typed user-facing states.
- No feature may introduce performance work on the UI thread without a size threshold and fallback plan.
- No "temporary" one-off UI styling in production code.
- Each new reusable component must have a clear owner, API, examples/tests, and responsive behavior.

### 4.12 Documentation

- Update this SOP when standards change.
- Update feature docs when a web limitation, relay requirement, or shortcut changes.
- Add QA notes for any platform-specific behavior.
- Keep `.cursor/rules/flutter-platform-ui.mdc` aligned with the actual code and tests.

---

## 5. Web Implementation Plan

### Phase 0 - Product decisions and branch setup

Exit criteria:

- Product decisions in section 11 are answered or accepted with recommended defaults.
- Branch created for web foundation work.
- Current mobile behavior is protected by existing tests.
- Baseline `flutter analyze` and targeted tests are recorded.

Recommended defaults:

- Web compact is supported and follows the Android product flow through custom web components.
- Tablet/desktop is the primary web product target.
- Direct browser HTTP is allowed only where browser policy allows it.
- Production arbitrary API execution uses a backend relay.
- Default release renderer starts with standard Flutter web build; evaluate `--wasm` after compatibility gates pass.

### Phase 1 - Enable the Flutter web platform

Tasks:

- Run `flutter create . --platforms web` and review generated files.
- Add `web/` assets, app metadata, favicon/icons, manifest, and deployment config.
- Re-run FlutterFire configuration with web app support.
- Add web Firebase options to `lib/firebase_options.dart`.
- Gate orientation lock to Android/iOS only.
- Update `AppPlatform` with `isWeb`, `usesAndroidMaterialUi`, `usesWebCustomUi`, and form-factor helpers.
- Update `App` so web can use the correct Flutter app host while rendering app-owned custom web UI.
- Update router page selection to choose Android Material screens, web custom screens, or iOS Cupertino screens explicitly.
- Gate iCloud, native screenshots, native notifications, Android system nav color, AdMob, and mobile-only platform channels.

Exit criteria:

- `flutter build web --release` reaches Dart compilation.
- Existing Android/iOS tests still pass.
- Web starts to auth/bootstrap without platform unsupported exceptions.

### Phase 2 - Make shared code web-compilable

Tasks:

- Move `dart:io` usages behind conditional adapters.
- Replace temporary-file export paths on web with `Uint8List`/Blob/download flows.
- Replace file imports on web with `FilePickerResult.files.single.bytes` or `xFiles`.
- Replace `MultipartFile.fromFileSync` on web with bytes-based multipart construction.
- Move `SocketException`, `HttpException`, and IO-specific error handling behind platform-safe error mapping.
- Replace `webview_flutter` web compile paths with web HTML/legal preview implementations.
- Disable or replace ad surfaces on web.
- Ensure screenshot feedback and feedback email flows have web-safe behavior.

Exit criteria:

- `flutter build web --release` succeeds.
- Unit tests for import/export, request body construction, and error handling cover web adapters.
- No web compile path imports `dart:io`.

### Phase 3 - Custom component web shell and design system

Tasks:

- Build the initial `lib/app/web_ui/` token, component, layout, and pattern structure.
- Migrate web shell work onto custom components instead of raw Material 3 widgets.
- Use `ShellScreenMaterial` only as a flow/reference point for compact navigation behavior.
- Add reusable custom adaptive shell components for:
  - compact body + custom bottom nav,
  - rail body,
  - desktop app shell with persistent sidebar.
- Add shared pane primitives:
  - constrained pane,
  - resizable splitter,
  - empty panel,
  - toolbar row,
  - keyboard-focusable list/tree row.
- Add custom request tab strip component with dirty, close, duplicate, reorder, overflow, restore, and keyboard traversal states.
- Add custom toolbar, icon button, input, select, menu, tooltip, modal, toast, empty state, and status badge components before feature screens use them.
- Add keyboard shortcut registry and shortcuts help surface.
- Keep Android behavior unchanged at phone widths.

Exit criteria:

- Shell has no overflow at all required viewports.
- Web shell uses reusable custom components, not feature-local Material styling.
- Keyboard navigation reaches every top-level route.
- Browser back/forward works across shell tabs and nested routes.

### Phase 4 - Postman-like API workspace

Tasks:

- Convert desktop collections/request flow into a persistent workspace:
  - collection tree pane,
  - tabbed request workspace on the right,
  - request editor pane per tab,
  - response pane per active tab,
  - environment/variables access.
- Support multiple open API tabs with:
  - open from collection/history,
  - new request,
  - close and close others,
  - duplicate tab/request,
  - dirty indicator,
  - persisted active tab,
  - tab restore after refresh,
  - keyboard traversal,
  - safe close confirmation for unsaved state.
- Preserve existing mobile navigation flow at compact widths.
- Use route state for selected collection/request where possible.
- Keep unsaved request state during pane resize, route changes, auth refresh, browser refresh, and layout class changes.
- Maintain auto-save and draft state with clear conflict policy between local tab draft, saved collection request, and history replay.
- Make response viewer desktop-native:
  - resizable right/bottom panel,
  - search within response,
  - copy/download HAR/body,
  - raw/pretty/preview/tree modes where safe,
  - streaming/progressive states where supported,
  - stable large-response performance.
- Add desktop empty states that guide action without marketing copy.

Exit criteria:

- User can create collection, create/open multiple request tabs, send, inspect response, save, replay from history, and export without leaving the desktop workspace.
- Compact web still uses the Android-like flow.
- Required viewport tests pass.

### Phase 5 - Feature parity surfaces

Tasks:

- Auth:
  - Google web sign-in.
  - Apple web sign-in decision.
  - session persistence and logout.
  - refresh/token-expiry behavior.
  - multi-tab logout/session invalidation behavior.
  - route guards that do not flash protected UI before auth readiness.
- History:
  - desktop table/list with search/filter, replay, delete, export.
- Environments:
  - desktop list/detail pane, active environment selector, variable editing.
- WebSocket:
  - desktop connection tabs, composer/log split, saved compose, reconnect behavior.
  - document browser limitations for headers and relay requirements.
- Settings:
  - web-safe settings only.
  - hide or explain mobile-only settings like iCloud, system notification behavior, mobile ads, invalid TLS direct client behavior.
- Import/export:
  - JSON file picker, drag/drop, save-as/download.
- Legal/support:
  - web-native legal document display.
- Feedback:
  - browser screenshot/feedback path or form-based fallback.

Exit criteria:

- Each top-level route has compact, tablet, and desktop behavior.
- Mobile-only settings do not appear as broken web controls.
- Import/export round trip works on web.
- Auth/session behavior survives refresh, logout, and token failure tests.

### Phase 6 - Production request relay

Tasks:

- Define relay API contract for HTTP execution.
- Implement auth and per-user session validation.
- Add timeout/cancel semantics.
- Add SSRF and private network protections.
- Add request/response size caps and streaming strategy.
- Add logs and metrics without secrets.
- Support multipart, binary, raw, form data, URL encoded, default headers, auth merge, variables, redirects, cookies, and HAR generation.
- Add extra-large response handling strategy for relay and client, including byte limits, truncation metadata, download fallback, and safe preview modes.
- Add relay-backed tests using local fake targets.
- Add UI messaging for direct-browser vs relay execution mode.

Exit criteria:

- Web can execute arbitrary API requests with production-safe relay semantics.
- CORS-limited direct requests show clear messages and alternatives.
- E2E request flow passes against controlled test endpoints.

### Phase 7 - E2E, visual, and CI gates

Tasks:

- Add `integration_test` for web.
- Add browser E2E smoke for:
  - auth bootstrap/mock auth,
  - create collection,
  - create request tab,
  - open multiple request tabs,
  - send request through test transport,
  - inspect response,
  - auto-save and restore after refresh,
  - save and replay history,
  - import/export,
  - environment variables,
  - extra-large response fallback,
  - WebSocket echo flow.
- Add screenshot/visual checks at required viewports.
- Add component screenshot/interaction checks for the custom web component library.
- Add keyboard-only E2E for request flow.
- Add CI commands for analyze, unit/widget tests, guard tests, web build, and web E2E.

Exit criteria:

- CI is required for every web PR.
- The web app can be tested from a production release build, not only debug mode.

### Phase 8 - Release readiness

Tasks:

- Add deployment target, preferably Firebase Hosting or another static host with correct headers.
- Add release build command and environment config.
- Configure CSP, cache headers, COOP/COEP if `--wasm`/Skwasm multi-threading is adopted, HSTS, and asset caching.
- Add monitoring for app errors, relay errors, request latency, and release health.
- Add manual QA checklist for Chrome, Edge, Safari, and Firefox.
- Add rollback process.

Exit criteria:

- Production build deployed to staging.
- Staging E2E passes.
- Manual QA sign-off completed.
- Known browser limitations are documented in product copy or support docs.

---

## 6. Required Test Matrix

### 6.1 Always-run local gate for web changes

Use the repo's Flutter binary until `flutter` is available on PATH:

```sh
/Users/maulikraja/FlutterDev/flutter/bin/flutter analyze
/Users/maulikraja/FlutterDev/flutter/bin/flutter test
/Users/maulikraja/FlutterDev/flutter/bin/flutter test test/no_material_import_test.dart test/no_cupertino_in_material_test.dart
/Users/maulikraja/FlutterDev/flutter/bin/flutter build web --release
```

For targeted work, run the smallest relevant subset first, then the full gate before final handoff.

### 6.2 Unit tests

Required areas:

- web component tokens and component variants.
- URL/query sync.
- cURL import/export.
- collection import/export.
- variable interpolation.
- auth merge.
- assertion runner.
- request body construction for all body types.
- web file import/export adapters.
- web request transport mapping.
- response performance policies.
- extra-large response thresholds and fallback decisions.
- request tab state, dirty tracking, and restore serialization.
- auth/session bootstrap, logout, token failure, and multi-tab invalidation policy.
- router redirects.
- settings persistence and web-safe settings.

### 6.3 Widget tests

Required areas:

- custom web component states and responsive constraints.
- shell layout at compact, medium, expanded, desktop, and wide desktop sizes.
- collections tree and detail pane selection.
- request tab strip behavior, dirty state, close confirmation, reorder/overflow, and shortcuts.
- request builder tab switching and shortcuts.
- response viewer search, copy/download actions, large payload display, and extra-large fallback.
- history replay.
- environment editor.
- WebSocket composer/log split.
- auth/login/session screens and protected-route loading states.
- web-only disabled/hidden mobile settings.
- no overflow assertions at required viewports.

### 6.4 Integration and E2E tests

Required core flow:

1. Open app on web.
2. Complete auth bootstrap with test auth/emulator/mock.
3. Create a collection.
4. Create a request tab.
5. Set method, URL, params, headers, body, auth, and tests.
6. Send request through controlled test transport.
7. Validate status, headers, body, cookies, timing, size, and tests output.
8. Open a second request tab and verify the first tab state remains intact.
9. Save request.
10. Confirm auto-save/draft restore after refresh.
11. Confirm history entry.
12. Replay from history.
13. Export collection and re-import it.
14. Verify auth/session state survives refresh and sign-out clears protected state.

Required keyboard flow:

1. Navigate to collections using keyboard.
2. Create/open request.
3. Focus URL bar.
4. Send with Cmd/Ctrl + Enter.
5. Save with Cmd/Ctrl + S.
6. Switch tabs with Cmd/Ctrl + 1..5.
7. Open response search.
8. Close modal/panel with Escape.

### 6.5 Visual QA

Required screenshots:

- auth screen light/dark,
- desktop workspace empty state,
- desktop workspace with multiple request tabs, selected request, and response,
- compact request builder,
- collection tree with nested folders,
- response viewer large JSON,
- response viewer extra-large fallback/truncation/download state,
- custom component states sheet,
- import/export screen,
- settings screen,
- WebSocket screen.

Every screenshot set must include at least:

- 390 x 844
- 768 x 1024
- 1280 x 800
- 1440 x 900

### 6.6 Manual QA

Required browsers:

- Chrome stable.
- Edge stable.
- Safari current.
- Firefox current.

Manual checks:

- refresh safety,
- browser back/forward,
- download/import,
- copy/paste,
- drag/drop where supported,
- keyboard-only request flow,
- multi-tab request workflow,
- auto-save/restore workflow,
- touch use on tablet,
- dark/light/system theme,
- offline/poor-network behavior,
- large response behavior,
- extra-large response behavior,
- login/logout/session expiry behavior,
- relay unavailable behavior.

---

## 7. Shortcut Standard

Existing shortcuts remain:

| Shortcut | Action |
| --- | --- |
| Cmd/Ctrl + Enter | Send request or cancel active send |
| Cmd/Ctrl + S | Save request |
| Cmd/Ctrl + 1..5 | Switch request tabs |

Required web additions:

| Shortcut | Action |
| --- | --- |
| Cmd/Ctrl + K | Command palette or global quick switcher |
| Cmd/Ctrl + N | New request |
| Cmd/Ctrl + Shift + N | New collection/folder, depending on focus context |
| Cmd/Ctrl + O | Import |
| Cmd/Ctrl + F | Find in active response/editor context when focus is inside app panel |
| Cmd/Ctrl + W | Close active request tab when focus is inside the app workspace, with unsaved confirmation |
| Cmd/Ctrl + Shift + ] | Next request tab |
| Cmd/Ctrl + Shift + [ | Previous request tab |
| Cmd/Ctrl + Alt/Option + Right | Move active request tab right where supported |
| Cmd/Ctrl + Alt/Option + Left | Move active request tab left where supported |
| Escape | Close active menu/dialog/sheet/palette or blur transient search |
| Delete/Backspace | Delete selected tree/history item after confirmation |
| F2 | Rename selected tree item |
| ? | Shortcuts help |

All shortcuts must be implemented through Flutter `Shortcuts`/`Actions` or `CallbackShortcuts` with focus-aware behavior. Do not fire destructive shortcuts while text fields are editing unless the shortcut is explicitly text-editor safe.

---

## 8. Release and Hosting Standard

### 8.1 Build modes

- Default release build must pass first: `flutter build web --release`.
- Evaluate `flutter build web --wasm` after plugin compatibility is known.
- Use profile builds for performance profiling.
- Serve release builds from a real web server during QA; do not validate production behavior only through debug `flutter run`.

### 8.2 Hosting headers

Release hosting must define:

- HTTPS only.
- HSTS.
- CSP that allows required Flutter/Firebase assets and disallows unsafe app-origin HTML rendering.
- cache rules for `flutter_bootstrap.js`, service worker, and hashed assets.
- COOP/COEP only if required for selected renderer/threading strategy and all third-party dependencies support it.

### 8.3 Environment configuration

- No production secrets in web assets.
- Firebase web config is allowed as public client config, but privileged secrets are not.
- Relay base URL must be environment-driven.
- Build should support development, staging, and production.

---

## 9. Definition Of Done For Any Web PR

A web PR is not done until:

- implementation follows this SOP,
- `.cursor/rules/flutter-platform-ui.mdc` remains accurate,
- all new/changed web UI is built from reusable custom components,
- existing components were searched before new components were created,
- component tests or screenshot coverage exist for new/changed components,
- platform guard tests pass,
- `flutter analyze` passes,
- relevant unit/widget tests pass,
- web release build passes,
- responsive verification covers required sizes for touched UI,
- E2E coverage exists for changed user flow,
- no web compile path imports unsupported libraries,
- no mobile behavior is regressed,
- accessibility and keyboard behavior are verified,
- auth/session and auto-save behavior are verified when touched,
- large/extra-large response behavior is verified when touched,
- docs are updated for user-visible behavior or limitations,
- known gaps are explicitly tracked.

---

## 10. Current Risk Register

| Risk | Severity | Plan |
| --- | --- | --- |
| Browser CORS prevents arbitrary API calls | High | Implement production relay transport |
| `dart:io` imports block web compilation | High | Move IO behind conditional adapters |
| Firebase web config missing | High | Re-run FlutterFire config with web |
| AdMob plugin unsupported on web | High | Gate ads off or choose web ad strategy |
| WebView plugin unsupported on web | High | Replace with sandboxed web preview |
| Large or extra-large response rendering jank | High | Preserve response performance policy, offload work, test large and extra-large payloads |
| Component inconsistency over time | High | Enforce custom component-first rule, token usage, component tests, and screenshot gates |
| Request tab state loss | High | Persist tab model, dirty state, active tab, and drafts; test refresh and resize |
| Auth/session drift across browser tabs | High | Define multi-tab session policy and test logout/token invalidation |
| Browser refresh loses unsaved state | Medium | Persist drafts and route state deliberately |
| Desktop becomes stretched mobile UI | Medium | Use custom desktop workspace components and screenshot gates |
| Shortcut conflicts with browser/text editing | Medium | Focus-aware shortcuts and shortcut help |
| Web token storage is weaker than native secure storage | Medium | Prefer backend session/cookie strategy and short-lived tokens |

---

## 11. Decisions To Confirm

These are product/architecture choices. Items marked **Selected** are fixed by the current product direction; items marked **Recommended** can proceed unless a different choice is selected.

### 11.1 Web request execution

1. **Backend relay for production parity (Recommended)**  
   Most Postman-like capability; solves CORS and browser limitations with server-side safeguards.
2. Direct browser requests only  
   Fastest but cannot support arbitrary APIs and will feel broken for many real endpoints.
3. Hybrid direct-first plus optional relay  
   Good long-term UX, but still needs the relay for production readiness.

### 11.2 Compact web behavior

1. **Fully responsive compact flow using custom web components (Selected)**  
   Matches the stated requirement, keeps mobile browser usable, and avoids raw Material 3 styling on web.
2. Show a "tablet and desktop recommended" blocker below 600dp  
   Simpler QA, but conflicts with the request for mobile-size responsiveness.
3. Build a separate unrelated mobile web UI  
   More maintenance and risks drifting from the existing app flow.

### 11.3 Desktop workspace layout

1. **Tabbed three-pane default at >= 1200dp (Selected)**  
   Collection tree + tabbed request workspace + response panel, closest to a mature API client.
2. Two-pane default at >= 840dp, response bottom sheet  
   Easier first milestone but less desktop-native.
3. Four-pane with inspector/sidebar always visible  
   Powerful but should come after the three-pane workspace is stable.

### 11.4 Renderer/release mode

1. **Default Flutter web release first, evaluate WebAssembly after package audit (Recommended)**  
   Safest compatibility path.
2. WebAssembly/Skwasm first  
   Better potential performance, but package compatibility and hosting headers need deeper validation.

### 11.5 Web auth providers

1. **Google web sign-in first, Apple web as a follow-up decision (Recommended)**  
   Fastest path because Google already exists across mobile.
2. Google and Apple web sign-in in the first web milestone  
   Better parity, more setup/testing.
3. Email/link auth for web first  
   Useful for SaaS, but changes the auth product surface.

### 11.6 Web UI system

1. **Custom AUN SaaS component system (Selected)**  
   All web feature UI is composed from reusable app components and tokens.
2. Raw Material 3 widgets  
   Rejected for web because it will not deliver the required mature SaaS consistency.
3. Per-feature custom styling  
   Rejected because it creates inconsistency and maintenance debt.

---

## 12. References Used

- Flutter web build/release: https://docs.flutter.dev/deployment/web
- Flutter web build and debugging: https://docs.flutter.dev/platform-integration/web/building
- Flutter web renderers and WebAssembly: https://docs.flutter.dev/platform-integration/web/renderers
- Flutter adaptive and responsive design: https://docs.flutter.dev/ui/adaptive-responsive
- Flutter integration testing: https://docs.flutter.dev/testing/integration-tests
- Firebase Crashlytics for Flutter: https://firebase.google.com/docs/crashlytics/flutter/get-started
- `google_mobile_ads` platform support: https://pub.dev/packages/google_mobile_ads
- `webview_flutter` platform support: https://pub.dev/packages/webview_flutter
- `file_picker` web support: https://pub.dev/packages/file_picker
- `share_plus` web support: https://pub.dev/packages/share_plus
- `flutter_secure_storage` platform support: https://pub.dev/packages/flutter_secure_storage
