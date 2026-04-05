import 'dart:convert';
import 'dart:io';

import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:aun_postman/app/widgets/scaled_cupertino_switch.dart';
import 'package:aun_postman/core/notifications/user_notification.dart';
import 'package:aun_postman/core/utils/har_exporter.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/http_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

/// Shared by [ResponseViewerSheet] search and [_PrettyTab] highlighting.
(String, String) prettifyResponseBody(
  String raw, {
  bool unwrapJson = false,
}) {
  try {
    final decoded = jsonDecode(raw);
    return (
      unwrapJson
          ? const JsonEncoder().convert(decoded)
          : const JsonEncoder.withIndent('  ').convert(decoded),
      'json',
    );
  } catch (_) {}

  try {
    final doc = XmlDocument.parse(raw);
    return (doc.toXmlString(pretty: true, indent: '  '), 'xml');
  } catch (_) {}

  return (raw, 'plaintext');
}

int _lineCountForDisplay(String text) {
  if (text.isEmpty) return 1;
  return text.split('\n').length;
}

double _lineNumberGutterWidth(int lineCount) {
  final digits = lineCount.toString().length;
  return (digits * 8.5 + 12).clamp(30.0, 56.0);
}

/// Converts highlight [Node] tree to a flat list of [TextSpan]s using [theme].
List<TextSpan> _buildHighlightSpans(
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

/// Flattens a [TextSpan] tree and splits it into per-logical-line span lists.
///
/// Leaf styles are resolved against [baseStyle] so each returned span is
/// self-contained (no implicit inheritance needed from a parent TextSpan).
List<List<TextSpan>> _splitSpansByNewline(
  List<TextSpan> spans,
  TextStyle baseStyle,
) {
  final lines = <List<TextSpan>>[[]];

  void visit(TextSpan span, TextStyle inherited) {
    final effective =
        span.style == null ? inherited : inherited.merge(span.style!);
    final children = span.children;
    if (children != null && children.isNotEmpty) {
      for (final child in children) {
        if (child is TextSpan) visit(child, effective);
      }
    } else if (span.text != null) {
      final parts = span.text!.split('\n');
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) lines.add([]);
        if (parts[i].isNotEmpty) {
          lines.last.add(TextSpan(text: parts[i], style: effective));
        }
      }
    }
  }

  for (final span in spans) {
    visit(span, baseStyle);
  }
  return lines;
}

/// Pretty / raw body: monospace line index column + bordered content.
///
/// When [softWrap] is true and [lineWidgets] is provided, each logical line is
/// rendered as its own Row so that wrapped lines keep their line number
/// aligned. When [softWrap] is false, [child] is used with a horizontal
/// scroll view (the gutter stays aligned because nothing wraps).
class _LineNumberedBody extends StatelessWidget {
  const _LineNumberedBody({
    required this.sourceText,
    required this.scrollController,
    required this.softWrap,
    this.child,
    this.lineWidgets,
    this.softWrapLineContentBackground,
  });

  final String sourceText;
  final ScrollController scrollController;
  final bool softWrap;

  /// Used when [softWrap] is false (or as fallback).
  final Widget? child;

  /// One widget per logical line of [sourceText]; used when [softWrap] is true.
  final List<Widget>? lineWidgets;

  /// When [softWrap] and [lineWidgets] are used, fills only the content column
  /// (not the line-number gutter) — matches non-soft-wrap pretty view where
  /// the gutter sits on the sheet and the code block has its own background.
  final Color? softWrapLineContentBackground;

  @override
  Widget build(BuildContext context) {
    final lineCount = _lineCountForDisplay(sourceText);
    final gutterW = _lineNumberGutterWidth(lineCount);
    final sep = CupertinoColors.separator.resolveFrom(context);
    final numStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 12,
      height: 1.5,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // Soft-wrap per-row mode: each logical line gets its own Row so that
    // wrapped lines expand the row height and keep the number aligned.
    if (softWrap && lineWidgets != null) {
      const outerPad = 12.0;
      const gap = 8.0;
      final widgets = lineWidgets!;
      return SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(outerPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(widgets.length, (i) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectionContainer.disabled(
                  child: SizedBox(
                    width: gutterW,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.right,
                      style: numStyle,
                    ),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: sep, width: 1),
                      ),
                    ),
                    child: softWrapLineContentBackground != null
                        ? ColoredBox(
                            color: softWrapLineContentBackground!,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: widgets[i],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: widgets[i],
                          ),
                  ),
                ),
              ],
            );
          }),
        ),
      );
    }

    // Non-soft-wrap: single content widget with horizontal scroll; the gutter
    // stays aligned because no line ever wraps visually.
    return LayoutBuilder(
      builder: (context, constraints) {
        const outerPad = 12.0;
        const gap = 8.0;
        final innerMaxW = constraints.maxWidth - outerPad * 2;
        final contentW = (innerMaxW - gutterW - gap).clamp(0.0, double.infinity);

        final innerMinW = (contentW - 10).clamp(0.0, double.infinity);
        final content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: innerMinW),
            child: child!,
          ),
        );

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(outerPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: gutterW,
                child: Text(
                  List.generate(lineCount, (i) => '${i + 1}').join('\n'),
                  textAlign: TextAlign.right,
                  style: numStyle,
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: contentW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: sep, width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Like [HighlightView] but exposes [softWrap] for JSON body viewing.
///
/// Uses [Text.rich] (not [RichText]) so a parent [SelectableRegion] can make
/// the content selectable.
class _SoftWrapHighlightView extends StatelessWidget {
  const _SoftWrapHighlightView({
    required this.source,
    required this.language,
    required this.theme,
    required this.softWrap,
    this.textStyle,
  });

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);
  static const _tabSize = 8;

  final String source;
  final String? language;
  final Map<String, TextStyle> theme;
  final TextStyle? textStyle;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    var merged = TextStyle(
      fontFamily: 'monospace',
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    if (textStyle != null) {
      merged = merged.merge(textStyle!);
    }

    final normalized = source.replaceAll('\t', ' ' * _tabSize);
    final parsed = highlight.parse(normalized, language: language);
    final nodes = parsed.nodes;
    var children = nodes == null ? <TextSpan>[] : _buildHighlightSpans(nodes, theme);
    if (children.isEmpty) {
      children = [TextSpan(text: normalized, style: merged)];
    }

    return Container(
      color: theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      child: Text.rich(
        TextSpan(
          style: merged,
          children: children,
        ),
        softWrap: softWrap,
        overflow: softWrap ? TextOverflow.clip : TextOverflow.visible,
      ),
    );
  }
}

int _countCaseInsensitive(String haystack, String needle) {
  final n = needle.trim().toLowerCase();
  if (n.isEmpty) return 0;
  final h = haystack.toLowerCase();
  var count = 0;
  var i = h.indexOf(n);
  while (i >= 0) {
    count++;
    i = h.indexOf(n, i + n.length);
  }
  return count;
}

class ResponseViewerSheet extends StatefulWidget {
  const ResponseViewerSheet({
    super.key,
    required this.response,
    this.harRequest,
    this.harStartedAt,
  });

  final HttpResponse response;
  final HttpRequest? harRequest;
  final DateTime? harStartedAt;

  @override
  State<ResponseViewerSheet> createState() => _ResponseViewerSheetState();
}

class _ResponseViewerSheetState extends State<ResponseViewerSheet> {
  int _selectedTab = 0;
  bool _timingExpanded = false;
  /// Pretty JSON: wrap long lines within the viewport.
  bool _jsonSoftWrap = true;
  /// Pretty JSON: single-line minified JSON (vs indented).
  bool _jsonUnwrap = false;
  late final ScrollController _scrollController;
  late final TextEditingController _bodySearchController;

  bool get _prettyBodyIsJson {
    try {
      jsonDecode(widget.response.body);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _bodySearchController = TextEditingController();
  }

  @override
  void dispose() {
    _bodySearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _bodySearchHaystack {
    final raw = widget.response.body;
    if (_selectedTab == 0) {
      return prettifyResponseBody(
        raw,
        unwrapJson: _prettyBodyIsJson && _jsonUnwrap,
      ).$1;
    }
    return raw;
  }

  int get _bodyMatchCount =>
      _countCaseInsensitive(_bodySearchHaystack, _bodySearchController.text);

  Future<void> _shareResponse(
      BuildContext context, HttpResponse response) async {
    try {
      final ext = _detectContentType(response) == 'JSON' ? 'json' : 'txt';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/response.$ext');
      await file.writeAsString(response.body);
      // sharePositionOrigin is required on iOS for the share sheet anchor.
      // Use the centre of the screen as the origin.
      final size = MediaQuery.of(context).size;
      final origin = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 1,
        height: 1,
      );
      await Share.shareXFiles(
        [XFile(file.path, mimeType: ext == 'json' ? 'application/json' : 'text/plain')],
        subject: 'Response ${response.statusCode}',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (context.mounted) {
        UserNotification.show(
          context: context,
          title: 'Share failed',
          body: e.toString(),
        );
      }
    }
  }

  Future<void> _shareHar(BuildContext context) async {
    final req = widget.harRequest;
    final started = widget.harStartedAt;
    if (req == null || started == null) return;
    try {
      final har = HarExporter.buildEntry(
        request: req,
        response: widget.response,
        startedAt: started,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/request.har');
      await file.writeAsString(har);
      final size = MediaQuery.of(context).size;
      final origin = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 1,
        height: 1,
      );
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'HAR ${widget.response.statusCode}',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (context.mounted) {
        UserNotification.show(
          context: context,
          title: 'HAR export failed',
          body: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.response;
    final canExportHar =
        widget.harRequest != null && widget.harStartedAt != null;
    final isDark =
        CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final statusColor = AppColors.statusColor(response.statusCode);

    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.separator.resolveFrom(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Status bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _StatusChip(
                label: '${response.statusCode} ${response.statusMessage}',
                color: statusColor,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: response.durationMs < 1000
                    ? '${response.durationMs}ms'
                    : '${(response.durationMs / 1000).toStringAsFixed(2)}s',
                color: CupertinoTheme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: _formatSize(response.sizeBytes),
                color: CupertinoColors.systemIndigo,
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 44,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: response.body));
                  UserNotification.show(
                    context: context,
                    title: 'Aun Postman',
                    body: 'Response copied',
                  );
                },
                child: const Icon(CupertinoIcons.doc_on_clipboard, size: 18),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 44,
                onPressed: () => _shareResponse(context, response),
                child: const Icon(CupertinoIcons.share, size: 18),
              ),
              if (canExportHar)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 44,
                  onPressed: () => _shareHar(context),
                  child: const Icon(CupertinoIcons.archivebox, size: 18),
                ),
            ],
          ),
        ),

        // Request timing (total measured client-side; phases N/A with Dio)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _timingExpanded = !_timingExpanded),
            child: Row(
              children: [
                Icon(
                  _timingExpanded
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_right,
                  size: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'Timing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const Spacer(),
                Text(
                  response.durationMs < 1000
                      ? '${response.durationMs} ms total'
                      : '${(response.durationMs / 1000).toStringAsFixed(2)} s total',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_timingExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'End-to-end time from sending the request until the full '
                'response body was received. Finer phases (DNS lookup, TCP connect, '
                'TLS handshake, time to first byte) are not available with the '
                'current HTTP stack.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),

        // Tab bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _selectedTab,
            onValueChanged: (v) => setState(() => _selectedTab = v ?? 0),
            children: {
              0: Text('Pretty · ${_detectContentType(response)}'),
              1: const Text('Raw'),
              2: Text('Headers (${response.headers.length})'),
              3: Text('Cookies (${response.cookies.length})'),
            },
          ),
        ),

        if (_selectedTab == 0 && _prettyBodyIsJson)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Soft wrap',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScaledCupertinoSwitch(
                        value: _jsonSoftWrap,
                        onChanged: (v) => setState(() => _jsonSoftWrap = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Unwrap',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScaledCupertinoSwitch(
                        value: _jsonUnwrap,
                        onChanged: (v) => setState(() => _jsonUnwrap = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (_selectedTab == 0 || _selectedTab == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSearchTextField(
                    controller: _bodySearchController,
                    placeholder: 'Find in body',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_bodySearchController.text.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$_bodyMatchCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ],
            ),
          ),

        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _PrettyTab(
                body: response.body,
                isDark: isDark,
                scrollController: _scrollController,
                searchQuery: _bodySearchController.text,
                softWrap: _prettyBodyIsJson ? _jsonSoftWrap : true,
                unwrapJson: _prettyBodyIsJson && _jsonUnwrap,
              ),
              _RawTab(
                body: response.body,
                scrollController: _scrollController,
                searchQuery: _bodySearchController.text,
              ),
              _HeadersTab(
                headers: response.headers,
                scrollController: _scrollController,
              ),
              _CookiesTab(
                cookies: response.cookies,
                scrollController: _scrollController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _detectContentType(HttpResponse response) {
    final ct = response.headers['content-type'] ??
        response.headers['Content-Type'] ??
        '';
    if (ct.contains('json')) return 'JSON';
    if (ct.contains('xml')) return 'XML';
    if (ct.contains('html')) return 'HTML';
    return 'TEXT';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _PrettyTab extends StatelessWidget {
  const _PrettyTab({
    required this.body,
    required this.isDark,
    required this.scrollController,
    required this.searchQuery,
    required this.softWrap,
    required this.unwrapJson,
  });
  final String body;
  final bool isDark;
  final ScrollController scrollController;
  final String searchQuery;
  final bool softWrap;
  final bool unwrapJson;

  static const _mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    final (prettyBody, language) =
        prettifyResponseBody(body, unwrapJson: unwrapJson);
    final theme = isDark ? atomOneDarkTheme : atomOneLightTheme;

    if (searchQuery.trim().isEmpty) {
      if (softWrap) {
        final normalized =
            prettyBody.replaceAll('\t', ' ' * _SoftWrapHighlightView._tabSize);
        final parsed = highlight.parse(normalized, language: language);
        final nodes = parsed.nodes;
        var rootSpans =
            nodes == null ? <TextSpan>[] : _buildHighlightSpans(nodes, theme);

        final baseStyle = TextStyle(
          fontFamily: 'monospace',
          color: theme[_SoftWrapHighlightView._rootKey]?.color ??
              _SoftWrapHighlightView._defaultFontColor,
        ).merge(_mono);

        if (rootSpans.isEmpty) {
          rootSpans = [TextSpan(text: normalized, style: baseStyle)];
        }

        final perLineSpans = _splitSpansByNewline(rootSpans, baseStyle);

        final lineWidgets = perLineSpans.map((spans) {
          return Text.rich(
            TextSpan(
              children: spans.isEmpty
                  ? [TextSpan(text: '', style: baseStyle)]
                  : spans,
            ),
            softWrap: true,
          );
        }).toList();

        return SelectableRegion(
          selectionControls: cupertinoTextSelectionControls,
          child: _LineNumberedBody(
            sourceText: normalized,
            scrollController: scrollController,
            softWrap: true,
            lineWidgets: lineWidgets,
            softWrapLineContentBackground:
                theme[_SoftWrapHighlightView._rootKey]?.backgroundColor ??
                    _SoftWrapHighlightView._defaultBackgroundColor,
          ),
        );
      }

      return _LineNumberedBody(
        sourceText: prettyBody,
        scrollController: scrollController,
        softWrap: false,
        child: SelectableRegion(
          selectionControls: cupertinoTextSelectionControls,
          child: _SoftWrapHighlightView(
            source: prettyBody,
            language: language,
            theme: theme,
            softWrap: false,
            textStyle: _mono,
          ),
        ),
      );
    }
    return _SearchHighlightedScrollBody(
      text: prettyBody,
      searchQuery: searchQuery,
      scrollController: scrollController,
      softWrap: softWrap,
    );
  }
}

class _RawTab extends StatelessWidget {
  const _RawTab({
    required this.body,
    required this.scrollController,
    required this.searchQuery,
  });
  final String body;
  final ScrollController scrollController;
  final String searchQuery;

  static const _textStyle = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    if (searchQuery.trim().isEmpty) {
      final lines = body.split('\n');
      final lineWidgets =
          lines.map((l) => Text(l, style: _textStyle)).toList();
      return SelectableRegion(
        selectionControls: cupertinoTextSelectionControls,
        child: _LineNumberedBody(
          sourceText: body,
          scrollController: scrollController,
          softWrap: true,
          lineWidgets: lineWidgets,
        ),
      );
    }
    return _SearchHighlightedScrollBody(
      text: body,
      searchQuery: searchQuery,
      scrollController: scrollController,
      softWrap: true,
    );
  }
}

class _SearchHighlightedScrollBody extends StatelessWidget {
  const _SearchHighlightedScrollBody({
    required this.text,
    required this.searchQuery,
    required this.scrollController,
    required this.softWrap,
  });

  final String text;
  final String searchQuery;
  final ScrollController scrollController;
  final bool softWrap;

  static const TextStyle _base = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  /// Builds search-highlight spans for a single [line] of text.
  static List<InlineSpan> _spansForLine(
    String line,
    String q,
    Color highlightBg,
  ) {
    if (q.isEmpty) return [TextSpan(text: line, style: _base)];
    final spans = <InlineSpan>[];
    final lower = line.toLowerCase();
    final nq = q.toLowerCase();
    var start = 0;
    var i = lower.indexOf(nq);
    while (i >= 0) {
      if (i > start) {
        spans.add(TextSpan(text: line.substring(start, i), style: _base));
      }
      spans.add(
        TextSpan(
          text: line.substring(i, i + q.length),
          style: _base.copyWith(
            backgroundColor: highlightBg.withValues(alpha: 0.45),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = i + q.length;
      i = lower.indexOf(nq, start);
    }
    if (start < line.length) {
      spans.add(TextSpan(text: line.substring(start), style: _base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim();
    final highlightBg = CupertinoColors.systemYellow.resolveFrom(context);

    if (softWrap) {
      final lines = text.split('\n');
      final lineWidgets = lines.map((line) {
        return Text.rich(
          TextSpan(children: _spansForLine(line, q, highlightBg)),
          softWrap: true,
        );
      }).toList();

      return SelectableRegion(
        selectionControls: cupertinoTextSelectionControls,
        child: _LineNumberedBody(
          sourceText: text,
          scrollController: scrollController,
          softWrap: true,
          lineWidgets: lineWidgets,
        ),
      );
    }

    final spans = <InlineSpan>[];
    if (q.isEmpty) {
      spans.add(TextSpan(text: text, style: _base));
    } else {
      final lower = text.toLowerCase();
      final nq = q.toLowerCase();
      var start = 0;
      var i = lower.indexOf(nq);
      while (i >= 0) {
        if (i > start) {
          spans.add(TextSpan(text: text.substring(start, i), style: _base));
        }
        spans.add(
          TextSpan(
            text: text.substring(i, i + q.length),
            style: _base.copyWith(
              backgroundColor: highlightBg.withValues(alpha: 0.45),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        start = i + q.length;
        i = lower.indexOf(nq, start);
      }
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: _base));
      }
    }

    return _LineNumberedBody(
      sourceText: text,
      scrollController: scrollController,
      softWrap: false,
      child: SelectableRegion(
        selectionControls: cupertinoTextSelectionControls,
        child: Text.rich(
          TextSpan(children: spans),
          softWrap: false,
        ),
      ),
    );
  }
}

class _HeadersTab extends StatelessWidget {
  const _HeadersTab({required this.headers, required this.scrollController});
  final Map<String, String> headers;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final entries = headers.entries.toList();
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.value,
                style: const TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CookiesTab extends StatelessWidget {
  const _CookiesTab({required this.cookies, required this.scrollController});
  final List cookies;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (cookies.isEmpty) {
      return Center(
        child: Text(
          'No cookies',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: cookies.length,
      itemBuilder: (context, index) {
        final cookie = cookies[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cookie.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(cookie.value),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'JetBrainsMono',
        ),
      ),
    );
  }
}
