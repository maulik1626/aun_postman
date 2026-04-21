class ResponsePerformancePolicy {
  const ResponsePerformancePolicy({
    required this.searchSyncCharsLimit,
    required this.highlightCacheEntries,
  });

  final int searchSyncCharsLimit;
  final int highlightCacheEntries;

  factory ResponsePerformancePolicy.fromViewportWidth(double width) {
    if (width >= 1200) {
      return const ResponsePerformancePolicy(
        searchSyncCharsLimit: 300000,
        highlightCacheEntries: 500,
      );
    }
    if (width >= 700) {
      return const ResponsePerformancePolicy(
        searchSyncCharsLimit: 220000,
        highlightCacheEntries: 380,
      );
    }
    return const ResponsePerformancePolicy(
      searchSyncCharsLimit: 120000,
      highlightCacheEntries: 260,
    );
  }
}
