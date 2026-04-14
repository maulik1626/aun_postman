# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Rebranded to **AUN - ReqStudio**; Dart package `aun_reqstudio`; updated Android/iOS identifiers, iCloud container, and user-facing copy (no third-party API client trademarks in the product name).

## [1.0.0] - 2026-04-03

### Added
- Collections and folders with full CRUD and drag-to-reorder
- HTTP request builder: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- Request params, headers, body (raw JSON/XML/text, form-data, URL-encoded, binary)
- Authentication: Bearer token, Basic auth, API Key (header or query param)
- Environments and `{{variable}}` interpolation across URL, headers, and body
- Response viewer: pretty-printed JSON/XML with syntax highlighting, raw, headers, cookies
- Response status/time/size badges
- Request history with full re-run capability
- WebSocket client with connect/disconnect and message log
- Import/export: collection v2.1 JSON and cURL
- Share collections via iOS Files app and AirDrop
- Dark / Light / System theme with persistence
- iOS-native transitions and UI patterns throughout
- JetBrainsMono monospace font for all code/URL surfaces
- Secure storage for API keys and credentials
- Isar local database for offline-first persistence
