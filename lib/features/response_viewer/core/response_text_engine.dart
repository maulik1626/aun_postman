class ResponseTextEngine {
  ResponseTextEngine(String text)
    : _text = text,
      _metadata = _buildMetadata(text);

  final String _text;
  final ({List<int> lineStartOffsets, int maxLineLength}) _metadata;

  List<int> get _lineStartOffsets => _metadata.lineStartOffsets;

  static ({List<int> lineStartOffsets, int maxLineLength}) _buildMetadata(
    String text,
  ) {
    final offsets = <int>[0];
    var lineStart = 0;
    var maxLineLength = 0;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 10) {
        final lineLength = i - lineStart;
        if (lineLength > maxLineLength) {
          maxLineLength = lineLength;
        }
        offsets.add(i + 1);
        lineStart = i + 1;
      }
    }
    final trailingLineLength = text.length - lineStart;
    if (trailingLineLength > maxLineLength) {
      maxLineLength = trailingLineLength;
    }
    if (text.isEmpty) {
      maxLineLength = 0;
    }
    return (lineStartOffsets: offsets, maxLineLength: maxLineLength);
  }

  int get lineCount => _lineStartOffsets.length;
  int get maxLineLength => _metadata.maxLineLength;

  String lineAt(int index) {
    if (index < 0 || index >= lineCount) return '';
    final start = _lineStartOffsets[index];
    final end = index == lineCount - 1
        ? _text.length
        : _lineStartOffsets[index + 1] - 1;
    if (end < start) return '';
    return _text.substring(start, end);
  }

  List<String> toLineList() {
    return List<String>.generate(lineCount, lineAt, growable: false);
  }
}
