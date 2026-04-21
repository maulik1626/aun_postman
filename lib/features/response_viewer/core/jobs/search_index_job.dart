import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';

List<SearchMatch> runSearchIndexJob(({String text, String query}) input) {
  final q = input.query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final lowerText = input.text.toLowerCase();
  final out = <SearchMatch>[];
  var scanIndex = 0;
  var lineIndex = 0;
  var lineStart = 0;

  while (true) {
    final at = lowerText.indexOf(q, scanIndex);
    if (at < 0) break;
    while (scanIndex < at) {
      if (input.text.codeUnitAt(scanIndex) == 10) {
        lineIndex++;
        lineStart = scanIndex + 1;
      }
      scanIndex++;
    }
    out.add(SearchMatch(lineIndex: lineIndex, start: at - lineStart));
    scanIndex = at + q.length;
  }
  return out;
}
