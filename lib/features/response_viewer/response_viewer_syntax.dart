import 'package:flutter/widgets.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

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
            : TextSpan(
                text: node.value,
                style: theme[node.className!],
              ),
      );
    } else if (node.children != null) {
      final tmp = <TextSpan>[];
      currentSpans.add(
        TextSpan(
          children: tmp,
          style: theme[node.className!],
        ),
      );
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
    final parsed = highlight.parse(normalized, language: language);
    final nodes = parsed.nodes;
    var children = nodes == null
        ? <TextSpan>[]
        : highlightNodesToTextSpans(nodes, theme);
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
