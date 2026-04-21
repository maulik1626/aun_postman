import 'dart:convert';
import 'dart:io';

import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/widgets/scaled_cupertino_switch.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/har_exporter.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_processing_controller.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_text_engine.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_syntax.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

/// Shared by [ResponseViewerSheet] search and [_PrettyTab] highlighting.
(String, String) prettifyResponseBody(String raw, {bool unwrapJson = false}) {
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

double _lineNumberGutterWidth(int lineCount) {
  final digits = lineCount.toString().length;
  return (digits * 8.5 + 12).clamp(30.0, 56.0);
}

Widget _withCupertinoScrollbar({
  required BuildContext context,
  required ScrollController controller,
  required Widget child,
}) {
  return MediaQuery(
    data: MediaQuery.of(context).removePadding(
      removeLeft: true,
      removeTop: true,
      removeRight: true,
      removeBottom: true,
    ),
    child: CupertinoScrollbar(
      controller: controller,
      thumbVisibility: false,
      thickness: 3,
      thicknessWhileDragging: 5,
      radius: const Radius.circular(12),
      radiusWhileDragging: const Radius.circular(12),
      mainAxisMargin: 0,
      child: child,
    ),
  );
}

/// Pretty / raw body: monospace line index column + bordered content.
///
/// [lines] is built lazily via [ListView.builder] so very large responses do
/// not create tens of thousands of widgets at once.
class _LineNumberedBody extends StatelessWidget {
  const _LineNumberedBody({
    required this.textEngine,
    required this.scrollController,
    required this.softWrap,
    required this.buildLine,
    this.softWrapLineContentBackground,
  });

  final ResponseTextEngine textEngine;
  final ScrollController scrollController;
  final bool softWrap;

  /// One highlighted / raw line per index.
  final Widget Function(BuildContext context, int index, String line) buildLine;

  /// When [softWrap] is true, fills only the content column (not the gutter).
  final Color? softWrapLineContentBackground;

  @override
  Widget build(BuildContext context) {
    final lineCount = textEngine.lineCount;
    final gutterW = _lineNumberGutterWidth(lineCount);
    final sep = CupertinoColors.separator.resolveFrom(context);
    final numStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 12,
      height: 1.5,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    const outerPad = 12.0;
    const gap = 8.0;

    if (softWrap) {
      return _withCupertinoScrollbar(
        context: context,
        controller: scrollController,
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(outerPad, 0, outerPad, outerPad),
          itemCount: lineCount,
          itemBuilder: (context, i) {
            final line = textEngine.lineAt(i);
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
                      border: Border(left: BorderSide(color: sep, width: 1)),
                    ),
                    child: softWrapLineContentBackground != null
                        ? ColoredBox(
                            color: softWrapLineContentBackground!,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: buildLine(context, i, line),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: buildLine(context, i, line),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerMaxW = constraints.maxWidth - outerPad * 2;
        final contentW = (innerMaxW - gutterW - gap).clamp(
          0.0,
          double.infinity,
        );
        final innerMinW = (contentW - 10).clamp(0.0, double.infinity);

        return _withCupertinoScrollbar(
          context: context,
          controller: scrollController,
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(outerPad, 0, outerPad, outerPad),
            itemCount: lineCount,
            itemBuilder: (context, i) {
              final line = textEngine.lineAt(i);
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
                  SizedBox(
                    width: contentW,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: sep, width: 1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: innerMinW),
                            child: buildLine(context, i, line),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _BodyMatch {
  const _BodyMatch({required this.lineIndex, required this.start});

  final int lineIndex;
  final int start;
}

List<_BodyMatch> _collectBodyMatches(String text, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final out = <_BodyMatch>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final lineLower = lines[i].toLowerCase();
    var from = 0;
    while (true) {
      final at = lineLower.indexOf(q, from);
      if (at < 0) break;
      out.add(_BodyMatch(lineIndex: i, start: at));
      from = at + q.length;
    }
  }
  return out;
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
  late final ScrollController _prettyScrollController;
  late final ScrollController _rawScrollController;
  late final ScrollController _headersScrollController;
  late final ScrollController _cookiesScrollController;
  late final TextEditingController _bodySearchController;
  int _activeBodyMatchIndex = -1;

  /// Cached [jsonDecode] result for the current [HttpResponse.body].
  bool? _cachedBodyIsJson;
  String? _cachedBodyFingerprint;

  /// Cached [prettifyResponseBody] for search + Pretty tab.
  (String, String)? _prettyCache;
  String? _prettyCacheBodyFingerprint;
  bool? _prettyCacheUnwrap;
  late final ResponseProcessingController _processingController;
  List<_BodyMatch> _bodyMatchesCache = const [];

  bool get _prettyBodyIsJson {
    final b = widget.response.body;
    if (_cachedBodyFingerprint != b) {
      _cachedBodyFingerprint = b;
      try {
        jsonDecode(b);
        _cachedBodyIsJson = true;
      } catch (_) {
        _cachedBodyIsJson = false;
      }
    }
    return _cachedBodyIsJson ?? false;
  }

  Future<void> _syncPrettyCache() async {
    final raw = widget.response.body;
    final unwrap = _prettyBodyIsJson && _jsonUnwrap;
    if (_prettyCacheBodyFingerprint == raw &&
        _prettyCacheUnwrap == unwrap &&
        _prettyCache != null) {
      return;
    }
    _prettyCacheBodyFingerprint = raw;
    _prettyCacheUnwrap = unwrap;
    final result = await _processingController.computePretty(
      raw: raw,
      unwrapJson: unwrap,
    );
    if (!mounted) return;
    setState(() {
      _prettyCache = (result.text, result.language);
    });
    if (_bodySearchController.text.trim().isNotEmpty) {
      _refreshBodyMatches();
    }
  }

  @override
  void initState() {
    super.initState();
    _prettyScrollController = ScrollController();
    _rawScrollController = ScrollController();
    _headersScrollController = ScrollController();
    _cookiesScrollController = ScrollController();
    _bodySearchController = TextEditingController();
    _processingController = ResponseProcessingController();
    _prettyCache = (widget.response.body, 'plaintext');
    _syncPrettyCache();
  }

  @override
  void didUpdateWidget(ResponseViewerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response.body != widget.response.body) {
      _cachedBodyFingerprint = null;
      _prettyCacheBodyFingerprint = null;
      _prettyCache = (widget.response.body, 'plaintext');
      _syncPrettyCache();
      _refreshBodyMatches();
    }
  }

  @override
  void dispose() {
    _bodySearchController.dispose();
    _prettyScrollController.dispose();
    _rawScrollController.dispose();
    _headersScrollController.dispose();
    _cookiesScrollController.dispose();
    _processingController.dispose();
    super.dispose();
  }

  ScrollController get _activeBodyScrollController =>
      _selectedTab == 0 ? _prettyScrollController : _rawScrollController;

  String get _bodySearchHaystack {
    final raw = widget.response.body;
    if (_selectedTab == 0) {
      return _prettyCache!.$1;
    }
    return raw;
  }

  int get _bodyMatchCount => _bodyMatchesCache.length;
  List<_BodyMatch> get _bodyMatches => _bodyMatchesCache;

  Future<void> _refreshBodyMatches() async {
    final query = _bodySearchController.text;
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _bodyMatchesCache = const [];
        _activeBodyMatchIndex = -1;
      });
      _processingController.setSearchState(ResponseSearchState.idle);
      return;
    }
    setState(() {
      _bodyMatchesCache = _collectBodyMatches(_bodySearchHaystack, query);
      _syncActiveMatchForQuery();
    });
    final matches = await _processingController.computeSearchMatches(
      text: _bodySearchHaystack,
      query: query,
    );
    if (!mounted) return;
    setState(() {
      _bodyMatchesCache = matches
          .map((m) => _BodyMatch(lineIndex: m.lineIndex, start: m.start))
          .toList(growable: false);
      _syncActiveMatchForQuery();
    });
  }

  void _syncActiveMatchForQuery() {
    final matches = _bodyMatches;
    if (matches.isEmpty) {
      _activeBodyMatchIndex = -1;
      return;
    }
    if (_activeBodyMatchIndex < 0 || _activeBodyMatchIndex >= matches.length) {
      _activeBodyMatchIndex = 0;
    }
  }

  void _jumpToActiveBodyMatch() {
    final controller = _activeBodyScrollController;
    if (!controller.hasClients) return;
    final matches = _bodyMatches;
    if (_activeBodyMatchIndex < 0 || _activeBodyMatchIndex >= matches.length) {
      return;
    }
    const lineHeight = 18.0;
    const topPad = 0.0;
    final line = matches[_activeBodyMatchIndex].lineIndex;
    final target = topPad + (line * lineHeight);
    final max = controller.position.maxScrollExtent;
    final clamped = target.clamp(0.0, max);
    controller.jumpTo(clamped);
  }

  void _scheduleJumpToActiveBodyMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpToActiveBodyMatch();
    });
  }

  void _goToNextBodyMatch() {
    final matches = _bodyMatches;
    if (matches.isEmpty) return;
    setState(() {
      _activeBodyMatchIndex = (_activeBodyMatchIndex + 1) % matches.length;
    });
    _scheduleJumpToActiveBodyMatch();
  }

  void _goToPrevBodyMatch() {
    final matches = _bodyMatches;
    if (matches.isEmpty) return;
    setState(() {
      _activeBodyMatchIndex =
          (_activeBodyMatchIndex - 1 + matches.length) % matches.length;
    });
    _scheduleJumpToActiveBodyMatch();
  }

  Future<void> _shareResponse(
    BuildContext context,
    HttpResponse response,
  ) async {
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
        [
          XFile(
            file.path,
            mimeType: ext == 'json' ? 'application/json' : 'text/plain',
          ),
        ],
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
    final processing = _processingController;
    final canExportHar =
        widget.harRequest != null && widget.harStartedAt != null;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final statusColor = AppColors.statusColor(response.statusCode);
    final prettyPair = _prettyCache!;
    _syncActiveMatchForQuery();

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
                    title: 'AUN - ReqStudio',
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
            onValueChanged: (v) {
              setState(() => _selectedTab = v ?? 0);
              _refreshBodyMatches();
            },
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
                        onChanged: (v) {
                          setState(() => _jsonUnwrap = v);
                          _syncPrettyCache();
                          _refreshBodyMatches();
                        },
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
                    onChanged: (_) {
                      setState(() => _activeBodyMatchIndex = 0);
                      _refreshBodyMatches();
                    },
                  ),
                ),
                if (_bodySearchController.text.trim().isNotEmpty) ...[
                  if (processing.searchState == ResponseSearchState.indexing)
                    Text(
                      'Indexing...',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (_bodyMatchCount > 0)
                    Text(
                      '${_activeBodyMatchIndex + 1}/$_bodyMatchCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    )
                  else
                    Text(
                      '0/0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 30,
                    onPressed: _bodyMatchCount > 0 ? _goToPrevBodyMatch : null,
                    child: const Icon(CupertinoIcons.chevron_up, size: 16),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 30,
                    onPressed: _bodyMatchCount > 0 ? _goToNextBodyMatch : null,
                    child: const Icon(CupertinoIcons.chevron_down, size: 16),
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
                prettyBody: prettyPair.$1,
                language: prettyPair.$2,
                isDark: isDark,
                scrollController: _prettyScrollController,
                searchQuery: _bodySearchController.text,
                softWrap: _prettyBodyIsJson ? _jsonSoftWrap : true,
                activeMatch: _activeBodyMatchIndex,
                matches: _bodyMatches,
              ),
              _RawTab(
                body: response.body,
                scrollController: _rawScrollController,
                searchQuery: _bodySearchController.text,
                activeMatch: _activeBodyMatchIndex,
                matches: _bodyMatches,
              ),
              _HeadersTab(
                headers: response.headers,
                scrollController: _headersScrollController,
              ),
              _CookiesTab(
                cookies: response.cookies,
                scrollController: _cookiesScrollController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _detectContentType(HttpResponse response) {
    final ct =
        response.headers['content-type'] ??
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
    required this.prettyBody,
    required this.language,
    required this.isDark,
    required this.scrollController,
    required this.searchQuery,
    required this.softWrap,
    required this.activeMatch,
    required this.matches,
  });

  final String prettyBody;
  final String language;
  final bool isDark;
  final ScrollController scrollController;
  final String searchQuery;
  final bool softWrap;
  final int activeMatch;
  final List<_BodyMatch> matches;

  static const _mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    final theme = isDark ? atomOneDarkTheme : atomOneLightTheme;
    final textEngine = ResponseTextEngine(prettyBody);
    final softWrapBg =
        theme['root']?.backgroundColor ?? const Color(0xffffffff);

    if (searchQuery.trim().isEmpty) {
      return SelectableRegion(
        selectionControls: cupertinoTextSelectionControls,
        child: _LineNumberedBody(
          textEngine: textEngine,
          scrollController: scrollController,
          softWrap: softWrap,
          softWrapLineContentBackground: softWrap ? softWrapBg : null,
          buildLine: (context, index, line) => HighlightedLineWidget(
            line: line,
            language: language,
            theme: theme,
            textStyle: _mono,
            softWrap: softWrap,
          ),
        ),
      );
    }
    return _SearchHighlightedScrollBody(
      text: prettyBody,
      searchQuery: searchQuery,
      scrollController: scrollController,
      // Keep deterministic line heights while searching so arrow navigation
      // lands on the correct match instead of drifting with wrapped lines.
      softWrap: false,
      activeMatch: activeMatch,
      matches: matches,
    );
  }
}

class _RawTab extends StatelessWidget {
  const _RawTab({
    required this.body,
    required this.scrollController,
    required this.searchQuery,
    required this.activeMatch,
    required this.matches,
  });

  final String body;
  final ScrollController scrollController;
  final String searchQuery;
  final int activeMatch;
  final List<_BodyMatch> matches;

  static const _textStyle = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    final textEngine = ResponseTextEngine(body);
    if (searchQuery.trim().isEmpty) {
      return SelectableRegion(
        selectionControls: cupertinoTextSelectionControls,
        child: _LineNumberedBody(
          textEngine: textEngine,
          scrollController: scrollController,
          softWrap: true,
          buildLine: (_, __, line) => Text(line, style: _textStyle),
        ),
      );
    }
    return _SearchHighlightedScrollBody(
      text: body,
      searchQuery: searchQuery,
      scrollController: scrollController,
      // Keep deterministic line heights while searching so arrow navigation
      // lands on the correct match instead of drifting with wrapped lines.
      softWrap: false,
      activeMatch: activeMatch,
      matches: matches,
    );
  }
}

class _SearchHighlightedScrollBody extends StatelessWidget {
  const _SearchHighlightedScrollBody({
    required this.text,
    required this.searchQuery,
    required this.scrollController,
    required this.softWrap,
    required this.activeMatch,
    required this.matches,
  });

  final String text;
  final String searchQuery;
  final ScrollController scrollController;
  final bool softWrap;
  final int activeMatch;
  final List<_BodyMatch> matches;

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
    Color activeHighlightBg,
    int lineIndex,
    int activeMatchIndex,
    List<_BodyMatch> matches,
  ) {
    if (q.isEmpty) return [TextSpan(text: line, style: _base)];
    final spans = <InlineSpan>[];
    final lower = line.toLowerCase();
    final nq = q.toLowerCase();
    var start = 0;
    var matchOrdinal = 0;
    var i = lower.indexOf(nq);
    while (i >= 0) {
      if (i > start) {
        spans.add(TextSpan(text: line.substring(start, i), style: _base));
      }
      final currentMatchOrdinal = matchOrdinal;
      var absoluteMatchIndex = -1;
      var seen = 0;
      for (final m in matches) {
        if (m.lineIndex == lineIndex) {
          if (seen == currentMatchOrdinal && m.start == i) {
            absoluteMatchIndex = matches.indexOf(m);
            break;
          }
          seen++;
        }
      }
      final isActive = absoluteMatchIndex == activeMatchIndex;
      spans.add(
        TextSpan(
          text: line.substring(i, i + q.length),
          style: _base.copyWith(
            backgroundColor: (isActive ? activeHighlightBg : highlightBg)
                .withValues(alpha: 0.7),
            color: isActive ? CupertinoColors.black : CupertinoColors.label,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      matchOrdinal++;
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
    final activeHighlightBg = CupertinoColors.systemOrange.resolveFrom(context);
    final textEngine = ResponseTextEngine(text);

    return SelectableRegion(
      selectionControls: cupertinoTextSelectionControls,
      child: _LineNumberedBody(
        textEngine: textEngine,
        scrollController: scrollController,
        softWrap: softWrap,
        buildLine: (context, index, line) => Text.rich(
          TextSpan(
            children: _spansForLine(
              line,
              q,
              highlightBg,
              activeHighlightBg,
              index,
              activeMatch,
              matches,
            ),
          ),
          softWrap: softWrap,
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
    return _withCupertinoScrollbar(
      context: context,
      controller: scrollController,
      child: ListView.separated(
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
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
    return _withCupertinoScrollbar(
      context: context,
      controller: scrollController,
      child: ListView.builder(
        controller: scrollController,
        itemCount: cookies.length,
        itemBuilder: (context, index) {
          final cookie = cookies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cookie.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(cookie.value),
              ],
            ),
          );
        },
      ),
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
