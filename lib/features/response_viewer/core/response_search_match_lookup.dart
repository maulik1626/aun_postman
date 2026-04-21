import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';

class ResponseSearchMatchLookup {
  ResponseSearchMatchLookup._({
    required this.startsByLine,
    required this.activeLineIndex,
    required this.activeStart,
  });

  final Map<int, Set<int>> startsByLine;
  final int? activeLineIndex;
  final int? activeStart;

  factory ResponseSearchMatchLookup.fromMatches(
    List<SearchMatch> matches,
    int activeMatchIndex,
  ) {
    final startsByLine = <int, Set<int>>{};
    for (final match in matches) {
      startsByLine.putIfAbsent(match.lineIndex, () => <int>{}).add(match.start);
    }

    final activeMatch =
        activeMatchIndex >= 0 && activeMatchIndex < matches.length
        ? matches[activeMatchIndex]
        : null;

    return ResponseSearchMatchLookup._(
      startsByLine: startsByLine,
      activeLineIndex: activeMatch?.lineIndex,
      activeStart: activeMatch?.start,
    );
  }

  bool isMatchStart(int lineIndex, int start) {
    return startsByLine[lineIndex]?.contains(start) ?? false;
  }

  bool isActiveMatch(int lineIndex, int start) {
    return activeLineIndex == lineIndex && activeStart == start;
  }
}
