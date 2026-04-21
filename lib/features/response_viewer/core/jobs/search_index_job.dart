class SearchMatch {
  const SearchMatch({required this.lineIndex, required this.start});

  final int lineIndex;
  final int start;
}

List<SearchMatch> runSearchIndexJob(({String text, String query}) input) {
  final q = input.query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final out = <SearchMatch>[];
  final lines = input.text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final lineLower = lines[i].toLowerCase();
    var from = 0;
    while (true) {
      final at = lineLower.indexOf(q, from);
      if (at < 0) break;
      out.add(SearchMatch(lineIndex: i, start: at));
      from = at + q.length;
    }
  }
  return out;
}
