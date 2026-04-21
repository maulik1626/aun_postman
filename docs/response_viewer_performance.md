# Response Viewer Performance Playbook

This document defines the large-response strategy used by the response viewer across iOS, Android, tablet, web, and desktop targets.

## Runtime policy

- The viewer applies `ResponsePerformancePolicy` from viewport width.
- Policy currently tunes:
  - synchronous pre-index search limit (`searchSyncCharsLimit`)
  - syntax highlight cache size (`highlightCacheEntries`)
- Smaller viewports use lower sync thresholds to protect frame stability.

## Processing architecture

- Pretty formatting and search indexing run through isolate-backed jobs.
- The viewer renders immediately, then progressively refines:
  - initial state: plain/raw readable output
  - enrichment state: pretty/body-search index ready
- Search uses a fast immediate path for smaller bodies and async refinement for larger bodies.

## Telemetry hooks

- `ResponseProcessingController` emits no-op telemetry events by default:
  - `pretty_ready` / `pretty_error`
  - `search_ready`
- Event payload includes operation duration and basic payload/query metadata.
- Integrate a concrete telemetry sink later without changing response viewer UI.

## Operational tuning

- If low-end devices show jank:
  - lower `searchSyncCharsLimit`
  - lower `highlightCacheEntries`
- If desktop/tablet has ample resources:
  - increase both limits to prioritize perceived responsiveness.

## Regression checks

- Run:
  - `flutter test test/widget/response_viewer_find_scroll_test.dart`
  - `flutter test test/widget/response_viewer_material_back_dismiss_test.dart`
  - `flutter test test/unit/core/response_processing_controller_test.dart`
  - `flutter test test/no_material_import_test.dart`
  - `flutter test test/no_cupertino_in_material_test.dart`
