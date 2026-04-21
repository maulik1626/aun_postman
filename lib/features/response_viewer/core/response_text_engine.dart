class ResponseTextEngine {
  ResponseTextEngine(String text)
      : _text = text,
        _lineStartOffsets = _buildLineStartOffsets(text);

  final String _text;
  final List<int> _lineStartOffsets;

  static List<int> _buildLineStartOffsets(String text) {
    final offsets = <int>[0];
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 10) {
        offsets.add(i + 1);
      }
    }
    return offsets;
  }

  int get lineCount => _lineStartOffsets.length;

  String lineAt(int index) {
    if (index < 0 || index >= lineCount) return '';
    final start = _lineStartOffsets[index];
    final end = index == lineCount - 1 ? _text.length : _lineStartOffsets[index + 1] - 1;
    if (end < start) return '';
    return _text.substring(start, end);
  }

  List<String> toLineList() {
    return List<String>.generate(lineCount, lineAt, growable: false);
  }
}
