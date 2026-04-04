# Aun Postman — Product Roadmap & Implementation Tracker

> Last updated: 2026-04-04 · Primary color updated to #DB952C
> Status legend: ✅ Done · 🔨 In Progress · ⚠️ Partial · ❌ Not Started · 🐛 Bug

---

## Phase 1 — Critical Fixes (P0)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 1.1 | Expandable/collapsible folders in collection detail | ✅ | Done |
| 1.2 | Create folder from UI | ✅ | Done |
| 1.3 | Rename / delete folder from UI | ✅ | Done |
| 1.4 | Move request between folders/collection | ❌ | Drag-drop or move dialog |
| 1.5 | saveToCollection respects folderUid | ✅ | Fixed |
| 1.6 | WebSocket custom auth/connection headers | ✅ | Uses IOWebSocketChannel |
| 1.7 | Form-data cURL export broken | ✅ | Fixed |
| 1.8 | Request timestamps preserved on load | ✅ | Fixed |
| 1.9 | Nested sub-folders (recursive) | ✅ | Infinite depth via _updateFolderInTree |

---

## Phase 2 — Core Postman Features (P1)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 2.1 | Syntax highlighting in request body editor | ❌ | Plain TextField; response has highlighting |
| 2.2 | Dynamic variables ($timestamp, $randomInt, $guid, $uuid) | ❌ | Postman built-in dynamic vars |
| 2.3 | Undefined variable warning in URL bar | ❌ | Silently leaves {{var}} unreplaced |
| 2.4 | Tests tab (assertions after response) | ❌ | Status code, body, header assertions |
| 2.5 | Pre-request variable overrides | ❌ | Set/override variables before send |
| 2.6 | History grouped by date (Today / Yesterday / Older) | ❌ | Flat list only |
| 2.7 | History search by URL / method / status | ❌ | No search |
| 2.8 | Response save to Files / share | ❌ | Can only copy to clipboard |
| 2.9 | Nested folders (sub-folders) UI rendering | ✅ | Recursive rendering + CRUD at any depth |
| 2.10 | Collection-level auth (inheritable) | ❌ | Postman allows auth at collection level |
| 2.11 | Environment import/export alongside collections | ❌ | Only collections exported |
| 2.12 | Duplicate request | ✅ | Swipe action in collection detail |
| 2.13 | Duplicate collection | ❌ | No clone action |

---

## Phase 3 — Request Builder Enhancements (P1)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 3.1 | Form-data file picker per field | ⚠️ | Key-value only; no file field type toggle |
| 3.2 | Request body JSON auto-format / pretty-print | ❌ | No format button |
| 3.3 | URL auto-complete / history suggestions | ❌ | Cold typing only |
| 3.4 | Response body search (Ctrl+F equivalent) | ❌ | No in-response search |
| 3.5 | Response timeline breakdown (DNS, TCP, TTFB) | ❌ | Only total duration shown |
| 3.6 | OAuth 2.0 auth type | ❌ | Bearer/Basic/API Key only |
| 3.7 | Digest auth type | ❌ | Not implemented |
| 3.8 | AWS Signature auth | ❌ | Not implemented |
| 3.9 | Content-Type auto-set based on body type | ⚠️ | May need to verify |
| 3.10 | Request-level variable display (active env vars shown) | ❌ | No variable preview |
| 3.11 | SSL / certificate handling (self-signed accept) | ❌ | Rejects self-signed certs |

---

## Phase 4 — Collection Explorer Overhaul (P1)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 4.1 | Expandable/collapsible folder tree | ✅ | P0 done |
| 4.2 | Add request directly from collection detail | ✅ | Nav bar + folder context menu |
| 4.3 | Reorder requests within folder | ❌ | No drag-drop inside folder |
| 4.4 | Reorder folders within collection | ❌ | No drag-drop for folders |
| 4.5 | Collection description visible | ❌ | Description field stored but not shown |
| 4.6 | Request method badge inline in list | ✅ | Done |
| 4.7 | Long-press context menu (rename/delete/duplicate/move) | ❌ | Only swipe-to-delete |

---

## Phase 5 — WebSocket Enhancements (P2)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 5.1 | Custom headers at connect time | ❌ | Critical for auth |
| 5.2 | JSON pretty-print for received messages | ❌ | Raw string only |
| 5.3 | Subprotocol configuration | ❌ | |
| 5.4 | Ping/pong keep-alive | ❌ | |
| 5.5 | Message search/filter | ❌ | |
| 5.6 | Save WebSocket session | ❌ | |
| 5.7 | Binary frame display (hex/base64) | ❌ | |
| 5.8 | Auto-reconnect on disconnect | ❌ | |

---

## Phase 6 — Settings & App Polish (P2)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 6.1 | Request timeout setting (global) | ❌ | Hardcoded 30s |
| 6.2 | SSL verification toggle (for dev/testing) | ❌ | |
| 6.3 | Follow redirects toggle | ❌ | |
| 6.4 | Default headers (applied to every request) | ❌ | e.g. User-Agent |
| 6.5 | Proxy configuration | ❌ | Corporate environments |
| 6.6 | Clear all data / reset app | ❌ | |
| 6.7 | iCloud / local backup & restore | ❌ | |
| 6.8 | Haptic feedback | ❌ | |
| 6.9 | Keyboard shortcuts (external keyboard) | ❌ | |

---

## Phase 7 — Advanced Features (P3)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 7.1 | GraphQL support (query/mutation/subscription) | ❌ | Separate body type + schema explorer |
| 7.2 | gRPC support | ❌ | |
| 7.3 | Mock server (intercept & respond locally) | ❌ | |
| 7.4 | Request chaining (use response value as next request input) | ❌ | |
| 7.5 | Collection runner (run all requests in order) | ❌ | |
| 7.6 | CSV data-driven testing | ❌ | |
| 7.7 | Team workspaces / cloud sync | ❌ | |
| 7.8 | HAR export | ❌ | |
| 7.9 | cURL improvements (cookies, proxies, certificates) | ⚠️ | |

---

## Known Bugs

| # | Bug | Severity | File |
|---|-----|----------|------|
| B1 | Environment variables not applied — environment must be set active AND linked; no UI guidance | High | environments_screen, request_execution_provider |
| B2 | saveToCollection ignores folderUid — request always saved to root | High | request_builder_provider.dart |
| B3 | createdAt/updatedAt overwritten on loadFromRequest | Medium | request_builder_provider.dart |
| B4 | Form-data cURL export outputs comment instead of -F flags | Medium | curl_exporter.dart |
| B5 | History replay re-interpolates with current env, not original env | Low | history_screen |
| B6 | Collection reorder saves UIDs only — requests could be reordered incorrectly if DAO is slow | Low | collections_provider |

---

## Implementation Order

```
Phase 1  →  Phase 4 (collection explorer)  →  Phase 2  →  Phase 3  →  Phase 5  →  Phase 6  →  Phase 7
```

---

## Progress Tracker

- Total items: 61
- ✅ Done: 2
- 🔨 In Progress: 0
- ⚠️ Partial: 3
- ❌ Not Started: 50
- 🐛 Bugs: 6
