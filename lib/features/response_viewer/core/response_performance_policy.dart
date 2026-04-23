import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';

class ResponsePerformancePolicy {
  const ResponsePerformancePolicy({
    required this.payloadTier,
    required this.searchSyncCharsLimit,
    required this.highlightCacheEntries,
    required this.syntaxHighlightCharsLimit,
    required this.prettyFormatCharsLimit,
    required this.jsonUnwrapCharsLimit,
    required this.jsonTreeCharsLimit,
    required this.searchDebounceMs,
  });

  final ResponsePayloadTier payloadTier;
  final int searchSyncCharsLimit;
  final int highlightCacheEntries;
  final int syntaxHighlightCharsLimit;
  final int prettyFormatCharsLimit;
  final int jsonUnwrapCharsLimit;
  final int jsonTreeCharsLimit;
  final int searchDebounceMs;

  factory ResponsePerformancePolicy.fromViewportWidth({
    required double width,
    required int bodyChars,
  }) {
    final isDesktopWide = width >= 1200;
    final isTablet = width >= 700;

    final smallLimit = isDesktopWide
        ? 450000
        : isTablet
        ? 300000
        : 180000;
    final largeLimit = isDesktopWide
        ? 1200000
        : isTablet
        ? 800000
        : 450000;
    final hugeLimit = isDesktopWide
        ? 2600000
        : isTablet
        ? 1800000
        : 1000000;

    if (bodyChars <= smallLimit) {
      return ResponsePerformancePolicy(
        payloadTier: ResponsePayloadTier.small,
        searchSyncCharsLimit: isDesktopWide
            ? 300000
            : isTablet
            ? 220000
            : 120000,
        highlightCacheEntries: isDesktopWide
            ? 500
            : isTablet
            ? 380
            : 260,
        syntaxHighlightCharsLimit: isDesktopWide
            ? 500000
            : isTablet
            ? 300000
            : 180000,
        prettyFormatCharsLimit: isDesktopWide
            ? 650000
            : isTablet
            ? 420000
            : 260000,
        jsonUnwrapCharsLimit: isDesktopWide
            ? 16000000
            : isTablet
            ? 12000000
            : 8000000,
        jsonTreeCharsLimit: isDesktopWide
            ? 10000000
            : isTablet
            ? 7000000
            : 5000000,
        searchDebounceMs: 180,
      );
    }

    if (bodyChars <= largeLimit) {
      return ResponsePerformancePolicy(
        payloadTier: ResponsePayloadTier.large,
        searchSyncCharsLimit: isDesktopWide ? 140000 : 80000,
        highlightCacheEntries: isDesktopWide ? 320 : 180,
        syntaxHighlightCharsLimit: isDesktopWide ? 260000 : 0,
        prettyFormatCharsLimit: isDesktopWide ? 360000 : 220000,
        jsonUnwrapCharsLimit: isDesktopWide ? 20000000 : 10000000,
        jsonTreeCharsLimit: isDesktopWide ? 8000000 : 5000000,
        searchDebounceMs: 280,
      );
    }

    if (bodyChars <= hugeLimit) {
      return ResponsePerformancePolicy(
        payloadTier: ResponsePayloadTier.huge,
        searchSyncCharsLimit: 0,
        highlightCacheEntries: 0,
        syntaxHighlightCharsLimit: 0,
        prettyFormatCharsLimit: isDesktopWide
            ? 5000000
            : isTablet
            ? 3000000
            : 1500000,
        jsonUnwrapCharsLimit: isDesktopWide
            ? 24000000
            : isTablet
            ? 16000000
            : 10000000,
        jsonTreeCharsLimit: isDesktopWide
            ? 6000000
            : isTablet
            ? 4500000
            : 3000000,
        searchDebounceMs: 360,
      );
    }

    return ResponsePerformancePolicy(
      payloadTier: ResponsePayloadTier.extreme,
      searchSyncCharsLimit: 0,
      highlightCacheEntries: 0,
      syntaxHighlightCharsLimit: 0,
      prettyFormatCharsLimit: 0,
      jsonUnwrapCharsLimit: isDesktopWide
          ? 24000000
          : isTablet
          ? 16000000
          : 10000000,
      jsonTreeCharsLimit: isDesktopWide
          ? 5000000
          : isTablet
          ? 3500000
          : 2200000,
      searchDebounceMs: 420,
    );
  }
}
