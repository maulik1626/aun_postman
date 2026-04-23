enum ResponsePrettyState { idle, loading, ready, error }

enum ResponseSearchState { idle, debouncing, indexing, ready }

enum ResponsePayloadTier { small, large, huge, extreme }

enum ResponseJsonPrettyViewMode { text, tree }

class SearchMatch {
  const SearchMatch({required this.lineIndex, required this.start});

  final int lineIndex;
  final int start;
}
