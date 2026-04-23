import 'package:flutter/widgets.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

class _HighlightSpanCache {
  static int _maxEntries = 300;
  static final _cache = <String, List<TextSpan>>{};
  static final _keys = <String>[];

  static List<TextSpan>? get(String key) => _cache[key];

  static void put(String key, List<TextSpan> value) {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
    }
    _cache[key] = value;
    _keys.add(key);
    while (_keys.length > _maxEntries) {
      final oldest = _keys.removeAt(0);
      _cache.remove(oldest);
    }
  }

  static void updateLimit(int entries) {
    _maxEntries = entries;
    while (_keys.length > _maxEntries) {
      final oldest = _keys.removeAt(0);
      _cache.remove(oldest);
    }
  }
}

/// Converts highlight.js [Node] tree to [TextSpan]s using [theme].
List<TextSpan> highlightNodesToTextSpans(
  List<Node> nodes,
  Map<String, TextStyle> theme,
) {
  final spans = <TextSpan>[];
  var currentSpans = spans;
  final stack = <List<TextSpan>>[];

  void traverse(Node node) {
    if (node.value != null) {
      currentSpans.add(
        node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className!]),
      );
    } else if (node.children != null) {
      final tmp = <TextSpan>[];
      currentSpans.add(TextSpan(children: tmp, style: theme[node.className!]));
      stack.add(currentSpans);
      currentSpans = tmp;

      for (final n in node.children!) {
        traverse(n);
        if (n == node.children!.last) {
          currentSpans = stack.isEmpty ? spans : stack.removeLast();
        }
      }
    }
  }

  for (final node in nodes) {
    traverse(node);
  }
  return spans;
}

/// Syntax highlighting for a **single line** (virtualized response bodies).
class HighlightedLineWidget extends StatelessWidget {
  const HighlightedLineWidget({
    super.key,
    required this.line,
    required this.language,
    required this.theme,
    this.textStyle,
    required this.softWrap,
    this.tabSize = 8,
  });

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);

  final String line;
  final String? language;
  final Map<String, TextStyle> theme;
  final TextStyle? textStyle;
  final bool softWrap;
  final int tabSize;

  static void configureCacheLimit(int entries) {
    _HighlightSpanCache.updateLimit(entries);
  }

  @override
  Widget build(BuildContext context) {
    var merged = TextStyle(
      fontFamily: 'monospace',
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    if (textStyle != null) {
      merged = merged.merge(textStyle!);
    }

    final normalized = line.replaceAll('\t', ' ' * tabSize);
    final cacheKey =
        '${language ?? 'plain'}|${theme.hashCode}|${merged.hashCode}|$normalized';
    var children = _HighlightSpanCache.get(cacheKey) ?? <TextSpan>[];
    if (children.isEmpty) {
      if (language == 'json') {
        children = _JsonLineHighlighter.highlight(
          normalized,
          baseStyle: merged,
          theme: theme,
        );
      } else {
        final parsed = highlight.parse(normalized, language: language);
        final nodes = parsed.nodes;
        children = nodes == null
            ? <TextSpan>[]
            : highlightNodesToTextSpans(nodes, theme);
      }
      _HighlightSpanCache.put(cacheKey, children);
    }
    if (children.isEmpty) {
      children = [TextSpan(text: normalized, style: merged)];
    }

    return ColoredBox(
      color: theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      child: Text.rich(
        TextSpan(style: merged, children: children),
        softWrap: softWrap,
        overflow: softWrap ? TextOverflow.clip : TextOverflow.visible,
      ),
    );
  }
}

class _JsonLineHighlighter {
  static List<TextSpan> highlight(
    String source, {
    required TextStyle baseStyle,
    required Map<String, TextStyle> theme,
  }) {
    if (source.isEmpty) {
      return const <TextSpan>[];
    }

    final spans = <TextSpan>[];
    var index = 0;

    while (index < source.length) {
      final char = source[index];

      if (_isWhitespace(char)) {
        final start = index;
        do {
          index++;
        } while (index < source.length && _isWhitespace(source[index]));
        spans.add(_span(source.substring(start, index), baseStyle, theme));
        continue;
      }

      if (char == '"') {
        final end = _consumeString(source, index);
        final text = source.substring(index, end);
        final tokenClass = _isObjectKey(source, end) ? 'attr' : 'string';
        spans.add(_span(text, baseStyle, theme, tokenClass));
        index = end;
        continue;
      }

      if (_startsNumber(source, index)) {
        final end = _consumeNumber(source, index);
        spans.add(
          _span(source.substring(index, end), baseStyle, theme, 'number'),
        );
        index = end;
        continue;
      }

      if (source.startsWith('true', index)) {
        spans.add(_span('true', baseStyle, theme, 'literal'));
        index += 4;
        continue;
      }

      if (source.startsWith('false', index)) {
        spans.add(_span('false', baseStyle, theme, 'literal'));
        index += 5;
        continue;
      }

      if (source.startsWith('null', index)) {
        spans.add(_span('null', baseStyle, theme, 'literal'));
        index += 4;
        continue;
      }

      if (_isPunctuation(char)) {
        spans.add(_span(char, baseStyle, theme, 'punctuation'));
        index++;
        continue;
      }

      spans.add(_span(char, baseStyle, theme));
      index++;
    }

    return spans;
  }

  static TextSpan _span(
    String text,
    TextStyle baseStyle,
    Map<String, TextStyle> theme, [
    String? tokenClass,
  ]) {
    return TextSpan(
      text: text,
      style: tokenClass == null ? null : baseStyle.merge(theme[tokenClass]),
    );
  }

  static bool _isWhitespace(String char) =>
      char == ' ' || char == '\n' || char == '\r' || char == '\t';

  static bool _isPunctuation(String char) =>
      char == '{' ||
      char == '}' ||
      char == '[' ||
      char == ']' ||
      char == ':' ||
      char == ',';

  static int _consumeString(String source, int start) {
    var index = start + 1;
    while (index < source.length) {
      final char = source[index];
      if (char == r'\') {
        index += 2;
        continue;
      }
      index++;
      if (char == '"') {
        break;
      }
    }
    return index.clamp(start + 1, source.length);
  }

  static bool _isObjectKey(String source, int stringEnd) {
    var index = stringEnd;
    while (index < source.length && _isWhitespace(source[index])) {
      index++;
    }
    return index < source.length && source[index] == ':';
  }

  static bool _startsNumber(String source, int index) {
    final char = source[index];
    if (char == '-') {
      return index + 1 < source.length &&
          _isDigit(source.codeUnitAt(index + 1));
    }
    return _isDigit(source.codeUnitAt(index));
  }

  static int _consumeNumber(String source, int start) {
    var index = start;
    if (source[index] == '-') {
      index++;
    }
    while (index < source.length && _isDigit(source.codeUnitAt(index))) {
      index++;
    }
    if (index < source.length && source[index] == '.') {
      index++;
      while (index < source.length && _isDigit(source.codeUnitAt(index))) {
        index++;
      }
    }
    if (index < source.length &&
        (source[index] == 'e' || source[index] == 'E')) {
      index++;
      if (index < source.length &&
          (source[index] == '+' || source[index] == '-')) {
        index++;
      }
      while (index < source.length && _isDigit(source.codeUnitAt(index))) {
        index++;
      }
    }
    return index;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
