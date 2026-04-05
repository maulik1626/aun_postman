# Aun Postman — Product Roadmap & Implementation Tracker

> Last updated: **2026-04-05** (+ **3.6–3.8** OAuth 2.0, Digest, AWS SigV4 auth) · Primary color: #DB952C  
> Status legend: ✅ Done · 🔨 In Progress · ⚠️ Partial · ❌ Not Started · 🐛 Bug

This file is maintained against the **actual repo** (`lib/`). If something drifts, re-audit or update rows here.

### Quick re-audit checklist

1. Run `**flutter analyze`** and `**dart test`** from the repo root (fix or note failures).
2. Skim `**lib/app/router/app_router.dart`** + `**lib/app/router/app_routes.dart`** for screens/routes.
3. Grep `**lib/features/`** for the feature name or open the file cited in the row’s Notes column.
4. Cross-check **request path**: `request_builder_screen.dart`, `request_builder_provider.dart`, `request_execution_provider.dart`, `dio_client.dart`.
5. Cross-check **data path**: `lib/infrastructure/*_repository.dart`, `lib/data/local/daos/*.dart`, `hive_service.dart`.
6. Update **Last updated** date and the **Progress Tracker** counts after any status change.

---

## Phase 1 — Critical Fixes (P0)


| #   | Feature                                             | Status | Notes                                                                           |
| --- | --------------------------------------------------- | ------ | ------------------------------------------------------------------------------- |
| 1.1 | Expandable/collapsible folders in collection detail | ✅      | Done                                                                            |
| 1.2 | Create folder from UI                               | ✅      | Done                                                                            |
| 1.3 | Rename / delete folder from UI                      | ✅      | Done                                                                            |
| 1.4 | Move request between folders/collection             | ✅      | Swipe **Move** + sheet; same/cross-collection (`collection_detail_screen.dart`) |
| 1.5 | saveToCollection respects folderUid                 | ✅      | `request_builder_provider.dart`                                                 |
| 1.6 | WebSocket custom auth/connection headers            | ✅      | `IOWebSocketChannel` + header rows                                              |
| 1.7 | Form-data cURL export                               | ✅      | `-F` flags in `curl_exporter.dart`                                              |
| 1.8 | Request timestamps preserved on save                | ✅      | `createdAt` preserved on update in `saveToCollection`                           |
| 1.9 | Nested sub-folders (recursive)                      | ✅      | Infinite depth via `_updateFolderInTree`                                        |


---

## Phase 2 — Core Postman Features (P1)


| #    | Feature                                                    | Status | Notes                                                                                                                                         |
| ---- | ---------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 2.1  | Syntax highlighting in request body editor                 | ✅      | **Highlight** / **Edit** on raw body — `HighlightView` + Atom theme (`body_tab.dart`)                                                         |
| 2.2  | Dynamic variables (`$timestamp`, `$randomInt`, `$guid`, …) | ✅      | `VariableInterpolator` + `dynamicVariables` list                                                                                              |
| 2.3  | Undefined `{{variable}}` warning (URL)                     | ✅      | Orange chip + `_findUndefinedVars` on builder                                                                                                 |
| 2.4  | Tests tab (assertions after response)                      | ✅      | Assertions stored on `HttpRequest.assertions`; Hive via `collection_dao`; builder load/save (`request_builder_provider`, `http_request.dart`) |
| 2.5  | Pre-request variable overrides                             | ✅      | **Pre-request vars** sheet (`key=value` lines); merged on Send / cURL (`buildInterpolationVariableMap`, `request_builder_screen.dart`)        |
| 2.6  | History grouped by date (Today / Yesterday / Older)        | ✅      | `history_screen.dart`                                                                                                                         |
| 2.7  | History search by URL / method / status                    | ✅      | `CupertinoSearchTextField`                                                                                                                    |
| 2.8  | Response share / save to Files                             | ✅      | `Share.shareXFiles` in `response_viewer_sheet.dart`                                                                                           |
| 2.9  | Nested folders UI (sub-folders)                            | ✅      | Recursive tree + CRUD                                                                                                                         |
| 2.10 | Collection-level auth (inheritable)                        | ✅      | `mergeRequestAndCollectionAuth`; **Collection auth** screen + nav from collection detail (`collection_auth_screen.dart`, `collection_dao`)    |
| 2.11 | Environment import/export                                  | ✅      | Import (Import/Export + collection vars) + **Share** on env detail → `PostmanV2Exporter.exportEnvironment`                                    |
| 2.12 | Duplicate request                                          | ✅      | Swipe in collection detail                                                                                                                    |
| 2.13 | Duplicate collection                                       | ✅      | Swipe **Duplicate** on `collections_screen.dart` → `Collections.duplicate`                                                                    |


---

## Phase 3 — Request Builder Enhancements (P1)


| #    | Feature                                              | Status | Notes                                                                                                                                                                   |
| ---- | ---------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.1  | Form-data file picker per field                      | ✅      | `FormDataFieldsEditor`: Text/File segment + **Choose** per row (`form_data_fields_editor.dart`, `body_tab.dart`)                                                        |
| 3.2  | Request body JSON auto-format / pretty-print         | ✅      | **Pretty Print** in Body tab JSON toolbar (`body_tab.dart`)                                                                                                             |
| 3.3  | URL auto-complete / history suggestions              | ✅      | Focus URL field → suggestions from **history** + **open collection** (deduped, filtered) (`request_builder_screen.dart`)                                                |
| 3.4  | Response body in-view search                         | ✅      | `CupertinoSearchTextField` on Pretty/Raw + match count + highlighted `Text.rich` (`response_viewer_sheet.dart`)                                                         |
| 3.5  | Response timeline (DNS, TCP, TTFB)                   | ✅      | **Timing** in response sheet: total + note that per-phase breakdown is N/A with Dio (`response_viewer_sheet.dart`)                                                      |
| 3.6  | OAuth 2.0 auth type                                  | ✅      | Client credentials + password grant; token URL form POST; **Get token** + auto-fetch on Send (`oauth2_token_client`, `AuthConfig.oauth2`, `request_execution_provider`) |
| 3.7  | Digest auth type                                     | ✅      | RFC 7616 `qop=auth`; 401 + `WWW-Authenticate` → one retry (`digest_auth_header`, `DigestAuthInterceptor`)                                                               |
| 3.8  | AWS Signature auth                                   | ✅      | SigV4 for JSON/text (or byte) body; region + service (`execute-api` default); optional session token (`aws_sigv4_signer`, `AuthConfig.awsSigV4`)                        |
| 3.9  | Content-Type auto-set from body type                 | ✅      | `DioClient._buildBody` when header absent                                                                                                                               |
| 3.10 | Request-level variable preview (all active env keys) | ✅      | List icon + long-press env pill → sheet: env keys/values + dynamic `{{$…}}` list (`request_builder_screen.dart`)                                                        |
| 3.11 | SSL / self-signed / custom certs                     | ✅      | **Verify SSL** switch (Settings); `DioClient` `badCertificateCallback` when off — IO only, not web (`app_settings_provider`, `dio_client.dart`)                         |
| 3.12 | Copy request as cURL (UI)                            | ✅      | Interpolate + **default headers** merged like Send; `-F key=@path` for file rows; apostrophe-safe quoting (`curl_exporter.dart`)                                        |
| 3.13 | Request title from URL + manual rename               | ✅      | `suggestRequestNameFromUrl`; lock after user rename / load / save; empty **Rename** unlocks and follows URL again (`request_builder_provider`, draft codec)             |


---

## Phase 4 — Collection Explorer Overhaul (P1)


| #   | Feature                                                | Status | Notes                                                                                                                                              |
| --- | ------------------------------------------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4.1 | Expandable/collapsible folder tree                     | ✅      |                                                                                                                                                    |
| 4.2 | Add request from collection detail                     | ✅      | Nav + folder context                                                                                                                               |
| 4.3 | Reorder requests within folder                         | ✅      | `ReorderableList` per folder + `SliverReorderableList` at collection root; grip + `ReorderableDragStartListener` (`collection_detail_screen.dart`) |
| 4.4 | Reorder folders within collection                      | ✅      | Nested `ReorderableList` per sibling group; root + sub-folders (`_reorderRootFolders` / `_reorderSubFolders`)                                      |
| 4.5 | Collection description visible                         | ✅      | List row + detail under nav bar (`collections_screen.dart`, `collection_detail_screen.dart`)                                                       |
| 4.6 | Request method badge inline in list                    | ✅      | `MethodBadge`                                                                                                                                      |
| 4.7 | Long-press context menu (rename/delete/duplicate/move) | ✅      | Request row long-press → sheet (same as swipe); folder row long-press → existing folder sheet                                                      |


---

## Phase 5 — WebSocket Enhancements (P2)


| #   | Feature                                 | Status | Notes                                                                                                                                                   |
| --- | --------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5.1 | Custom headers at connect time          | ✅      | `WebSocketScreen` → `IOWebSocketChannel`                                                                                                                |
| 5.2 | JSON pretty-print for received messages | ✅      | `_prettyPrint` when payload parses as JSON                                                                                                              |
| 5.3 | Subprotocol configuration               | ✅      | Comma-separated field → `IOWebSocketChannel.connect` `protocols` (`websocket_screen.dart`, `websocket_provider.dart`)                                   |
| 5.4 | Ping/pong keep-alive                    | ✅      | `IOWebSocketChannel.connect` `pingInterval: 25s` (`websocket_provider.dart`)                                                                            |
| 5.5 | Message search/filter                   | ✅      | `CupertinoSearchTextField` + `_messageMatchesQuery` (`websocket_screen.dart`)                                                                           |
| 5.6 | Save WebSocket session                  | ✅      | Secure storage `WsSessionStorage`; **Save session** / **Clear saved**; restore on open (`ws_session_storage.dart`, `websocket_screen.dart`)             |
| 5.7 | Binary frame display (hex/base64)       | ✅      | Log bubble: hex/base64 toggle (`_MessageBubble`, `websocket_screen.dart`)                                                                               |
| 5.8 | Auto-reconnect on disconnect            | ✅      | Exponential backoff; **Auto-reconnect** switch; `webSocketNotifierProvider` keepAlive (`websocket_provider.dart`, `app_settings_provider`)              |
| 5.9 | Save WebSocket composer payloads        | ✅      | **Saved messages** sheet; text/JSON/binary formats; Hive `ws_saved_compose_`*; included in full backup (`ws_saved_compose_provider`, `app_backup.dart`) |


---

## Phase 6 — Settings & App Polish (P2)


| #    | Feature                                | Status | Notes                                                                                                                                                                                                                                                                                                                                                                |
| ---- | -------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6.1  | Request timeout (global)               | ✅      | `AppSettings` + secure storage; picker 10–300s                                                                                                                                                                                                                                                                                                                       |
| 6.2  | SSL verification toggle (dev)          | ✅      | Same as **3.11** — Settings → Verify SSL                                                                                                                                                                                                                                                                                                                             |
| 6.3  | Follow redirects toggle                | ✅      | `AppSettings` + `DioClient`                                                                                                                                                                                                                                                                                                                                          |
| 6.4  | Default headers (every request)        | ✅      | Settings → **Default Headers**; secure JSON; merged in `DioClient` before request headers                                                                                                                                                                                                                                                                            |
| 6.5  | Proxy configuration                    | ✅      | Settings → **HTTP Proxy**; `httpProxy` in `AppSettings` + `DioClient` (IO)                                                                                                                                                                                                                                                                                           |
| 6.6  | Clear all data / reset app             | ✅      | Settings → Danger Zone                                                                                                                                                                                                                                                                                                                                               |
| 6.7  | iCloud / backup & restore              | ✅      | **Full backup** JSON + file restore (Import/Export). **iOS:** iCloud Documents container `iCloud.com.aunCreations.aunPostman` — **Save/Restore from iCloud** + Settings **iCloud auto-backup** (debounced on background); `AppDelegate` MethodChannel `com.aun_postman/icloud_backup`; enable **iCloud → Cloud Documents** on the App ID in Apple Developer / Xcode. |
| 6.8  | Haptic feedback                        | ✅      | `AppHaptics` — Send, Save, copy cURL, WS Connect (`app_haptics.dart`)                                                                                                                                                                                                                                                                                                |
| 6.9  | Keyboard shortcuts (external keyboard) | ✅      | **⌘/Ctrl+Enter** Send/cancel; **⌘/Ctrl+S** Save; **⌘/Ctrl+1–5** tabs — `request_builder_screen.dart`                                                                                                                                                                                                                                                                 |
| 6.10 | Auto-save request drafts (local)       | ✅      | **On** by default; Hive drafts per route scope; restore when reopening same request; cleared on Save — Settings + `request_builder_draft_`*                                                                                                                                                                                                                          |
| 6.11 | In-app transient notifications         | ✅      | Cupertino-style overlay toasts; `UserNotification.init` in `main.dart` — used on builder, response sheet, WS, import/export, env detail (`user_notification.dart`)                                                                                                                                                                                                   |


---

## Phase 7 — Advanced Features (P3)


| #   | Feature                               | Status | Notes                                                                                                     |
| --- | ------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------- |
| 7.1 | GraphQL (query/mutation/subscription) | ❌      |                                                                                                           |
| 7.2 | gRPC                                  | ❌      |                                                                                                           |
| 7.3 | Mock server (local intercept)         | ❌      |                                                                                                           |
| 7.4 | Request chaining                      | ❌      |                                                                                                           |
| 7.5 | Collection runner                     | ❌      |                                                                                                           |
| 7.6 | CSV data-driven testing               | ❌      |                                                                                                           |
| 7.7 | Team workspaces / cloud sync          | ❌      | Local Hive only                                                                                           |
| 7.8 | HAR export                            | ✅      | Response sheet → archive icon; `HarExporter` + last sent request metadata (`response_viewer_sheet.dart`)  |
| 7.9 | cURL round-trip                       | ✅      | **Paste cURL** on request builder + Import/Export screen; copy cURL in nav; `CurlParser` / `CurlExporter` |


---

## Known Bugs & tech debt


| #       | Item                                           | Severity | Notes                                                                                       |
| ------- | ---------------------------------------------- | -------- | ------------------------------------------------------------------------------------------- |
| ~~B1~~  | ~~History replay uses **current** active env~~ | —        | **Fixed** — `HistoryEntry.variableSnapshot`; replay banner; `buildInterpolationVariableMap` |
| ~~B2~~  | ~~Form-data → cURL: file parts~~               | —        | **Fixed** — `-F 'key=@path'` in `CurlExporter`                                              |
| ~~B3~~  | ~~Collection reorder race~~                    | —        | **Fixed** — serialized `reorder()` via `_reorderQueue` (`collections_provider.dart`)        |
| ~~B4~~  | ~~saveToCollection ignored folderUid~~         | —        | **Fixed** — verify with regression tests if added                                           |
| ~~B5~~  | ~~createdAt lost on save~~                     | —        | **Fixed** in `saveToCollection`                                                             |
| ~~TD1~~ | ~~Tests not in `HttpRequest` JSON~~            | —        | **Fixed** — `assertions` on model + DAO JSON + builder load/save                            |


---

## Implementation Order (suggested)

```
Phase 1  →  Phase 4  →  Phase 2 gaps  →  Phase 3  →  Phase 5  →  Phase 6  →  Phase 7
```

---

## Progress Tracker

- **Total items:** 71 (includes **3.13**, **5.9**, **6.11**)
- ✅ **Done:** 64  
- ⚠️ **Partial:** 0  
- ❌ **Not started:** 7 (GraphQL–workspaces in Phase 7)  
- 🐛 **Open bug rows:** 0

*Partial rows are counted once under Partial, not under Done.*