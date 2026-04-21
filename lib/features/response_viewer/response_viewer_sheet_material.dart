import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/har_exporter.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_json_tree.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_performance_policy.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_processing_controller.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_search_match_lookup.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_text_engine.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_syntax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

List<SearchMatch> _collectBodyMatchesMat(String text, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final out = <SearchMatch>[];
  final engine = ResponseTextEngine(text);
  for (var i = 0; i < engine.lineCount; i++) {
    final lineLower = engine.lineAt(i).toLowerCase();
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

double _lineNumberGutterWidth(int lineCount) {
  final digits = lineCount.toString().length;
  return (digits * 8.5 + 12).clamp(30.0, 56.0);
}

double _estimatedMonospaceContentWidth(ResponseTextEngine textEngine) {
  return textEngine.maxLineLength * 7.2 + 24;
}

double _estimatedJsonTreeContentWidth(List<ResponseJsonTreeEntry> entries) {
  if (entries.isEmpty) return 240;
  var widest = 240.0;
  for (final entry in entries) {
    final depthInset = entry.depth * 14.0;
    final glyphEstimate =
        ((entry.label?.length ?? 4) + entry.valueText.length) * 7.2;
    final candidate = 44 + depthInset + glyphEstimate;
    if (candidate > widest) {
      widest = candidate;
    }
  }
  return widest;
}

Widget _withMaterialScrollbar({
  required BuildContext context,
  required ScrollController controller,
  required Widget child,
}) {
  final cs = Theme.of(context).colorScheme;
  return ScrollbarTheme(
    data: ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll(false),
      trackVisibility: const WidgetStatePropertyAll(false),
      interactive: true,
      radius: const Radius.circular(12),
      thickness: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.dragged)) return 5.0;
        return 3.0;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.dragged)) {
          return cs.primary.withValues(alpha: 0.72);
        }
        if (states.contains(WidgetState.hovered)) {
          return cs.primary.withValues(alpha: 0.5);
        }
        return cs.onSurface.withValues(alpha: 0.3);
      }),
    ),
    child: Scrollbar(
      controller: controller,
      thumbVisibility: false,
      trackVisibility: false,
      interactive: true,
      child: child,
    ),
  );
}

class ResponseViewerSheetMaterial extends StatefulWidget {
  const ResponseViewerSheetMaterial({
    super.key,
    required this.response,
    this.harRequest,
    this.harStartedAt,
  });

  final HttpResponse response;
  final HttpRequest? harRequest;
  final DateTime? harStartedAt;

  @override
  State<ResponseViewerSheetMaterial> createState() =>
      _ResponseViewerSheetMaterialState();
}

class _ResponseViewerSheetMaterialState
    extends State<ResponseViewerSheetMaterial> {
  int _selectedTab = 0;
  bool _timingExpanded = false;
  bool _jsonSoftWrap = true;
  bool _jsonUnwrap = false;
  ResponseJsonPrettyViewMode _jsonPrettyViewMode =
      ResponseJsonPrettyViewMode.tree;
  late final ScrollController _prettyScrollController;
  late final ScrollController _rawScrollController;
  late final ScrollController _prettyHorizontalScrollController;
  late final ScrollController _rawHorizontalScrollController;
  late final ScrollController _headersScrollController;
  late final ScrollController _cookiesScrollController;
  late final TextEditingController _bodySearchController;
  int _activeBodyMatchIndex = -1;

  bool? _cachedBodyIsJson;
  String? _cachedBodyFingerprint;
  Object? _cachedDecodedJson;

  (String, String)? _prettyCache;
  String? _prettyCacheBodyFingerprint;
  bool? _prettyCacheUnwrap;
  late final ResponseProcessingController _processingController;
  List<SearchMatch> _bodyMatchesCache = const [];
  Timer? _searchDebounce;
  int _searchSyncCharsLimit = 120000;
  int _syntaxHighlightCharsLimit = 180000;
  int _prettyFormatCharsLimit = 260000;
  int _jsonTreeCharsLimit = 5000000;
  int _searchDebounceMs = 180;
  ResponsePayloadTier _payloadTier = ResponsePayloadTier.small;
  ResponseTextEngine? _rawTextEngine;
  String? _rawTextEngineFingerprint;
  ResponseTextEngine? _prettyTextEngine;
  String? _prettyTextEngineFingerprint;
  ResponseJsonTreeNode? _jsonTreeRoot;
  String? _jsonTreeFingerprint;
  final Map<String, bool> _jsonTreeExpansionOverrides = <String, bool>{};

  bool get _prettyBodyIsJson {
    final b = widget.response.body;
    if (_cachedBodyFingerprint != b) {
      _cachedBodyFingerprint = b;
      try {
        _cachedDecodedJson = jsonDecode(b);
        _cachedBodyIsJson = true;
      } catch (_) {
        _cachedDecodedJson = null;
        _cachedBodyIsJson = false;
      }
    }
    return _cachedBodyIsJson ?? false;
  }

  bool get _prettyFormattingEnabled {
    return widget.response.body.length <= _prettyFormatCharsLimit;
  }

  bool get _supportsStructuredJsonPrettyView {
    return _prettyBodyIsJson &&
        !_jsonUnwrap &&
        widget.response.body.length <= _jsonTreeCharsLimit;
  }

  bool get _usesStructuredJsonPrettyView {
    return _supportsStructuredJsonPrettyView &&
        _jsonPrettyViewMode == ResponseJsonPrettyViewMode.tree;
  }

  Object? get _decodedJsonBody {
    if (!_prettyBodyIsJson) return null;
    return _cachedDecodedJson;
  }

  ResponseJsonTreeNode? get _activeJsonTreeRoot {
    if (!_supportsStructuredJsonPrettyView) return null;
    final decoded = _decodedJsonBody;
    if (decoded == null) return null;
    final raw = widget.response.body;
    if (_jsonTreeFingerprint != raw || _jsonTreeRoot == null) {
      _jsonTreeRoot = buildResponseJsonTree(decoded);
      _jsonTreeFingerprint = raw;
    }
    return _jsonTreeRoot;
  }

  ResponseJsonTreePresentation _buildJsonTreePresentation(String query) {
    final root = _activeJsonTreeRoot;
    if (root == null) {
      return const ResponseJsonTreePresentation(entries: [], matches: []);
    }
    return buildResponseJsonTreePresentation(
      root: root,
      expansionOverrides: _jsonTreeExpansionOverrides,
      query: query,
    );
  }

  Future<void> _syncPrettyCache() async {
    final raw = widget.response.body;
    final unwrap = _prettyBodyIsJson && _jsonUnwrap;
    if (_prettyCacheBodyFingerprint == raw &&
        _prettyCacheUnwrap == unwrap &&
        _prettyCache != null) {
      return;
    }
    if (_usesStructuredJsonPrettyView) {
      _prettyCacheBodyFingerprint = raw;
      _prettyCacheUnwrap = false;
      if (!mounted) return;
      setState(() {
        _prettyCache = (raw, 'json');
        _prettyTextEngine = _activeRawTextEngine;
        _prettyTextEngineFingerprint = raw;
      });
      if (_bodySearchController.text.trim().isNotEmpty) {
        _scheduleBodySearchRefresh(immediate: true);
      }
      return;
    }
    if (!_prettyFormattingEnabled) {
      _prettyCacheBodyFingerprint = raw;
      _prettyCacheUnwrap = false;
      if (!mounted) return;
      setState(() {
        _prettyCache = (raw, 'plaintext');
        _prettyTextEngine = _activeRawTextEngine;
        _prettyTextEngineFingerprint = raw;
      });
      if (_bodySearchController.text.trim().isNotEmpty) {
        _scheduleBodySearchRefresh(immediate: true);
      }
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
      _prettyTextEngine = ResponseTextEngine(result.text);
      _prettyTextEngineFingerprint = result.text;
    });
    if (_bodySearchController.text.trim().isNotEmpty) {
      _scheduleBodySearchRefresh(immediate: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _prettyScrollController = ScrollController();
    _rawScrollController = ScrollController();
    _prettyHorizontalScrollController = ScrollController();
    _rawHorizontalScrollController = ScrollController();
    _headersScrollController = ScrollController();
    _cookiesScrollController = ScrollController();
    _bodySearchController = TextEditingController();
    _processingController = ResponseProcessingController();
    _prettyCache = (widget.response.body, 'plaintext');
    _rawTextEngine = ResponseTextEngine(widget.response.body);
    _rawTextEngineFingerprint = widget.response.body;
    _prettyTextEngine = _rawTextEngine;
    _prettyTextEngineFingerprint = widget.response.body;
    _syncPrettyCache();
  }

  @override
  void didUpdateWidget(ResponseViewerSheetMaterial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response.body != widget.response.body) {
      _cachedBodyFingerprint = null;
      _cachedDecodedJson = null;
      _prettyCacheBodyFingerprint = null;
      _jsonTreeFingerprint = null;
      _jsonTreeRoot = null;
      _jsonTreeExpansionOverrides.clear();
      _prettyCache = (widget.response.body, 'plaintext');
      _rawTextEngine = ResponseTextEngine(widget.response.body);
      _rawTextEngineFingerprint = widget.response.body;
      _prettyTextEngine = _rawTextEngine;
      _prettyTextEngineFingerprint = widget.response.body;
      _syncPrettyCache();
      _scheduleBodySearchRefresh(immediate: true);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _bodySearchController.dispose();
    _prettyScrollController.dispose();
    _rawScrollController.dispose();
    _prettyHorizontalScrollController.dispose();
    _rawHorizontalScrollController.dispose();
    _headersScrollController.dispose();
    _cookiesScrollController.dispose();
    _processingController.dispose();
    super.dispose();
  }

  ScrollController get _activeBodyScrollController =>
      _selectedTab == 0 ? _prettyScrollController : _rawScrollController;

  ScrollController get _activeBodyHorizontalScrollController =>
      _selectedTab == 0
      ? _prettyHorizontalScrollController
      : _rawHorizontalScrollController;

  bool get _isSearchingBody => _bodySearchController.text.trim().isNotEmpty;

  bool get _activeBodySoftWrap {
    if (_selectedTab == 0) {
      if (_isSearchingBody) return false;
      if (_usesStructuredJsonPrettyView) return _jsonSoftWrap;
      return !_prettyBodyIsJson || _jsonSoftWrap;
    }
    return !_isSearchingBody;
  }

  String get _bodySearchHaystack {
    final raw = widget.response.body;
    if (_selectedTab == 0) {
      return _prettyCache!.$1;
    }
    return raw;
  }

  int get _bodyMatchCount => _bodyMatchesCache.length;
  List<SearchMatch> get _bodyMatches => _bodyMatchesCache;

  ResponseTextEngine get _activePrettyTextEngine {
    final prettyBody = _prettyCache!.$1;
    if (_prettyTextEngineFingerprint != prettyBody ||
        _prettyTextEngine == null) {
      _prettyTextEngine = ResponseTextEngine(prettyBody);
      _prettyTextEngineFingerprint = prettyBody;
    }
    return _prettyTextEngine!;
  }

  ResponseTextEngine get _activeRawTextEngine {
    final raw = widget.response.body;
    if (_rawTextEngineFingerprint != raw || _rawTextEngine == null) {
      _rawTextEngine = ResponseTextEngine(raw);
      _rawTextEngineFingerprint = raw;
    }
    return _rawTextEngine!;
  }

  void _scheduleBodySearchRefresh({bool immediate = false}) {
    _searchDebounce?.cancel();
    if (immediate || _bodySearchController.text.trim().isEmpty) {
      _refreshBodyMatches();
      return;
    }
    _searchDebounce = Timer(
      Duration(milliseconds: _searchDebounceMs),
      _refreshBodyMatches,
    );
  }

  void _setJsonPrettyViewMode(ResponseJsonPrettyViewMode mode) {
    if (_jsonPrettyViewMode == mode) return;
    setState(() {
      _jsonPrettyViewMode = mode;
    });
    _syncPrettyCache();
    _scheduleBodySearchRefresh(immediate: true);
  }

  Future<void> _refreshBodyMatches() async {
    final query = _bodySearchController.text;
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _bodyMatchesCache = const [];
        _activeBodyMatchIndex = -1;
      });
      _processingController.invalidateSearch();
      return;
    }
    if (_selectedTab == 0 && _usesStructuredJsonPrettyView) {
      _processingController.invalidateSearch(
        nextState: ResponseSearchState.ready,
      );
      final presentation = _buildJsonTreePresentation(query);
      setState(() {
        _bodyMatchesCache = List<SearchMatch>.unmodifiable(
          presentation.matches,
        );
        _syncActiveMatchForQuery();
      });
      _scheduleJumpToActiveBodyMatch();
      return;
    }
    final haystack = _bodySearchHaystack;
    if (haystack.length <= _searchSyncCharsLimit) {
      _processingController.invalidateSearch(
        nextState: ResponseSearchState.ready,
      );
      setState(() {
        _bodyMatchesCache = _collectBodyMatchesMat(haystack, query);
        _syncActiveMatchForQuery();
      });
      _scheduleJumpToActiveBodyMatch();
      return;
    }
    final matches = await _processingController.computeSearchMatches(
      text: haystack,
      query: query,
    );
    if (!mounted) return;
    setState(() {
      _bodyMatchesCache = List<SearchMatch>.unmodifiable(matches);
      _syncActiveMatchForQuery();
    });
    _scheduleJumpToActiveBodyMatch();
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
    final matches = _bodyMatches;
    if (_activeBodyMatchIndex < 0 || _activeBodyMatchIndex >= matches.length) {
      return;
    }
    final controller = _activeBodyScrollController;
    if (controller.hasClients) {
      const lineHeight = 18.0;
      const topPad = 0.0;
      final line = matches[_activeBodyMatchIndex].lineIndex;
      final target = topPad + (line * lineHeight);
      final max = controller.position.maxScrollExtent;
      final clamped = target.clamp(0.0, max);
      controller.jumpTo(clamped);
    }
    final horizontalController = _activeBodyHorizontalScrollController;
    if (!_activeBodySoftWrap && horizontalController.hasClients) {
      final match = matches[_activeBodyMatchIndex];
      final viewport = horizontalController.position.viewportDimension;
      final target = math.max(0, match.start * 7.2 - viewport * 0.35);
      final max = horizontalController.position.maxScrollExtent;
      horizontalController.jumpTo(target.clamp(0.0, max).toDouble());
    }
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

  void _toggleJsonNodeExpansion(String nodeId, bool isExpanded) {
    if (nodeId == r'$') return;
    setState(() {
      _jsonTreeExpansionOverrides[nodeId] = !isExpanded;
    });
    if (_isSearchingBody) {
      _scheduleBodySearchRefresh(immediate: true);
    }
  }

  void _setAllJsonNodesExpanded(bool expanded) {
    final root = _activeJsonTreeRoot;
    if (root == null) return;

    void walk(ResponseJsonTreeNode node) {
      if (node.id != r'$' && node.hasChildren) {
        _jsonTreeExpansionOverrides[node.id] = expanded;
      }
      for (final child in node.children) {
        walk(child);
      }
    }

    setState(() {
      _jsonTreeExpansionOverrides.clear();
      walk(root);
    });
    if (_isSearchingBody) {
      _scheduleBodySearchRefresh(immediate: true);
    }
  }

  Future<void> _shareResponse(
    BuildContext context,
    HttpResponse response,
  ) async {
    try {
      final ext = _detectContentType(response.body, response.headers) == 'JSON'
          ? 'json'
          : 'txt';
      final size = MediaQuery.sizeOf(context);
      final origin = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 1,
        height: 1,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/response.$ext');
      await file.writeAsString(response.body);
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
      final size = MediaQuery.sizeOf(context);
      final origin = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 1,
        height: 1,
      );
      final har = HarExporter.buildEntry(
        request: req,
        response: widget.response,
        startedAt: started,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/request.har');
      await file.writeAsString(har);
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
    final viewportWidth = MediaQuery.of(context).size.width;
    final policy = ResponsePerformancePolicy.fromViewportWidth(
      width: viewportWidth,
      bodyChars: widget.response.body.length,
    );
    _payloadTier = policy.payloadTier;
    _searchSyncCharsLimit = policy.searchSyncCharsLimit;
    _syntaxHighlightCharsLimit = policy.syntaxHighlightCharsLimit;
    _prettyFormatCharsLimit = policy.prettyFormatCharsLimit;
    _jsonTreeCharsLimit = policy.jsonTreeCharsLimit;
    _searchDebounceMs = policy.searchDebounceMs;
    HighlightedLineWidget.configureCacheLimit(policy.highlightCacheEntries);
    final response = widget.response;
    final processing = _processingController;
    final prettyPair = _prettyCache!;
    final canExportHar =
        widget.harRequest != null && widget.harStartedAt != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = AppColors.statusColor(response.statusCode);
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dividerColor = Theme.of(context).dividerColor;
    final effectiveJsonPrettyViewMode = _supportsStructuredJsonPrettyView
        ? _jsonPrettyViewMode
        : ResponseJsonPrettyViewMode.text;
    final useStructuredJsonView = _usesStructuredJsonPrettyView;
    final jsonTreePresentation = useStructuredJsonView
        ? _buildJsonTreePresentation(_bodySearchController.text)
        : null;
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
              color: dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Status bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _StatusChipMaterial(
                label: '${response.statusCode} ${response.statusMessage}',
                color: statusColor,
              ),
              const SizedBox(width: 8),
              _StatusChipMaterial(
                label: response.durationMs < 1000
                    ? '${response.durationMs}ms'
                    : '${(response.durationMs / 1000).toStringAsFixed(2)}s',
                color: primary,
              ),
              const SizedBox(width: 8),
              _StatusChipMaterial(
                label: _formatSize(response.sizeBytes),
                color: Colors.indigo,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copy body',
                icon: const Icon(Icons.content_copy_outlined, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: response.body));
                  UserNotification.show(
                    context: context,
                    title: 'AUN - ReqStudio',
                    body: 'Response copied',
                  );
                },
              ),
              IconButton(
                tooltip: 'Share response',
                icon: const Icon(Icons.share_outlined, size: 18),
                onPressed: () => _shareResponse(context, response),
              ),
              if (canExportHar)
                IconButton(
                  tooltip: 'Export HAR',
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  onPressed: () => _shareHar(context),
                ),
            ],
          ),
        ),

        // Timing row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _timingExpanded = !_timingExpanded),
            child: Row(
              children: [
                Icon(
                  _timingExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 14,
                  color: secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Timing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  response.durationMs < 1000
                      ? '${response.durationMs} ms total'
                      : '${(response.durationMs / 1000).toStringAsFixed(2)} s total',
                  style: TextStyle(fontSize: 12, color: secondary),
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
                style: TextStyle(fontSize: 12, height: 1.35, color: secondary),
              ),
            ),
          ),

        // Tab bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(
                    'Pretty · ${_detectContentType(response.body, response.headers)}',
                  ),
                ),
                const ButtonSegment(value: 1, label: Text('Raw')),
                ButtonSegment(
                  value: 2,
                  label: Text('Headers (${response.headers.length})'),
                ),
                ButtonSegment(
                  value: 3,
                  label: Text('Cookies (${response.cookies.length})'),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) {
                  setState(() => _selectedTab = s.first);
                  _scheduleBodySearchRefresh(immediate: true);
                }
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: primary.withValues(alpha: 0.15),
                selectedForegroundColor: primary,
                textStyle: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // JSON soft-wrap / unwrap toggles
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
                        style: TextStyle(fontSize: 13, color: onSurface),
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.75,
                        alignment: Alignment.centerLeft,
                        child: Switch(
                          value: _jsonSoftWrap,
                          onChanged: (v) => setState(() => _jsonSoftWrap = v),
                          activeThumbColor: primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
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
                        style: TextStyle(fontSize: 13, color: onSurface),
                      ),
                      const SizedBox(width: 8),
                      if (_prettyFormattingEnabled)
                        Transform.scale(
                          scale: 0.75,
                          alignment: Alignment.centerRight,
                          child: Switch(
                            value: _jsonUnwrap,
                            onChanged: (v) {
                              setState(() => _jsonUnwrap = v);
                              _syncPrettyCache();
                              _scheduleBodySearchRefresh(immediate: true);
                            },
                            activeThumbColor: primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      else
                        Text(
                          'Large response',
                          style: TextStyle(fontSize: 12, color: secondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (_selectedTab == 0 && _prettyBodyIsJson)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<ResponseJsonPrettyViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: ResponseJsonPrettyViewMode.text,
                        label: Text('Text'),
                      ),
                      ButtonSegment(
                        value: ResponseJsonPrettyViewMode.tree,
                        label: Text('Tree'),
                      ),
                    ],
                    selected: {effectiveJsonPrettyViewMode},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      final mode = selection.first;
                      if (mode == ResponseJsonPrettyViewMode.tree &&
                          !_supportsStructuredJsonPrettyView) {
                        return;
                      }
                      _setJsonPrettyViewMode(mode);
                    },
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: primary.withValues(alpha: 0.15),
                      selectedForegroundColor: primary,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (jsonTreePresentation != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => _setAllJsonNodesExpanded(false),
                    child: const Text('Collapse all'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => _setAllJsonNodesExpanded(true),
                    child: const Text('Expand all'),
                  ),
                ],
              ],
            ),
          ),

        if (_selectedTab == 0 && !_prettyFormattingEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _payloadTier == ResponsePayloadTier.extreme
                    ? 'Extreme payload mode: pretty formatting is paused to keep the viewer stable.'
                    : 'Large payload mode: pretty formatting is paused to keep scrolling and search responsive.',
                style: TextStyle(fontSize: 12, height: 1.35, color: secondary),
              ),
            ),
          ),

        // Search bar (body/raw tabs)
        if (_selectedTab == 0 || _selectedTab == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bodySearchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Find in body',
                      prefixIcon: Icon(Icons.search_outlined, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _activeBodyMatchIndex = 0;
                      });
                      _scheduleBodySearchRefresh();
                    },
                  ),
                ),
                if (_bodySearchController.text.trim().isNotEmpty) ...[
                  if (processing.searchState == ResponseSearchState.indexing)
                    Text(
                      'Indexing...',
                      style: TextStyle(fontSize: 11, color: secondary),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _bodyMatchCount > 0
                        ? '${_activeBodyMatchIndex + 1}/$_bodyMatchCount'
                        : '0/0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: secondary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: 'Previous match',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                    onPressed: _bodyMatchCount > 0 ? _goToPrevBodyMatch : null,
                  ),
                  IconButton(
                    tooltip: 'Next match',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    onPressed: _bodyMatchCount > 0 ? _goToNextBodyMatch : null,
                  ),
                ],
              ],
            ),
          ),

        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _PrettyTabMaterial(
                jsonTreeEntries: jsonTreePresentation?.entries ?? const [],
                onToggleJsonNodeExpansion: _toggleJsonNodeExpansion,
                textEngine: _activePrettyTextEngine,
                prettyBody: prettyPair.$1,
                language: prettyPair.$2,
                isDark: isDark,
                scrollController: _prettyScrollController,
                searchQuery: _bodySearchController.text,
                softWrap: _prettyBodyIsJson ? _jsonSoftWrap : true,
                activeMatch: _activeBodyMatchIndex,
                matches: _bodyMatches,
                enableSyntaxHighlight:
                    _prettyFormattingEnabled &&
                    _syntaxHighlightCharsLimit > 0 &&
                    prettyPair.$1.length <= _syntaxHighlightCharsLimit,
                horizontalScrollController: _prettyHorizontalScrollController,
                useStructuredJsonView: useStructuredJsonView,
              ),
              _RawTabMaterial(
                textEngine: _activeRawTextEngine,
                body: response.body,
                scrollController: _rawScrollController,
                searchQuery: _bodySearchController.text,
                activeMatch: _activeBodyMatchIndex,
                matches: _bodyMatches,
                horizontalScrollController: _rawHorizontalScrollController,
              ),
              _HeadersTabMaterial(
                headers: response.headers,
                scrollController: _headersScrollController,
              ),
              _CookiesTabMaterial(
                cookies: response.cookies,
                scrollController: _cookiesScrollController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _detectContentType(String body, Map<String, String> headers) {
    if (_prettyBodyIsJson) return 'JSON';
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html')) {
      return 'HTML';
    }
    if (trimmed.startsWith('<')) {
      return 'XML';
    }
    final ct = headers['content-type'] ?? headers['Content-Type'] ?? '';
    if (ct.contains('json')) return 'JSON';
    if (ct.contains('xml')) return 'XML';
    if (ct.contains('html')) return 'HTML';
    return 'TEXT';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Line-numbered body (virtualized) ──────────────────────────────────────────

class _LineNumberedBodyMaterial extends StatelessWidget {
  const _LineNumberedBodyMaterial({
    required this.textEngine,
    required this.scrollController,
    required this.softWrap,
    required this.buildLine,
    this.softWrapLineContentBackground,
    this.horizontalScrollController,
    this.contentWidthEstimate,
  });

  final ResponseTextEngine textEngine;
  final ScrollController scrollController;
  final bool softWrap;
  final Widget Function(BuildContext context, int index, String line) buildLine;
  final Color? softWrapLineContentBackground;
  final ScrollController? horizontalScrollController;
  final double? contentWidthEstimate;

  @override
  Widget build(BuildContext context) {
    final lineCount = textEngine.lineCount;
    final gutterW = _lineNumberGutterWidth(lineCount);
    final sep = Theme.of(context).dividerColor;
    final numStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 12,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    const outerPad = 12.0;
    const gap = 8.0;

    if (softWrap) {
      return _withMaterialScrollbar(
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
                const SizedBox(width: gap),
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
        final viewportContentW = (innerMaxW - gutterW - gap).clamp(
          0.0,
          double.infinity,
        );
        final resolvedContentW = math.max(
          viewportContentW,
          contentWidthEstimate ?? viewportContentW,
        );
        final totalW = outerPad * 2 + gutterW + gap + resolvedContentW;

        final verticalList = _withMaterialScrollbar(
          context: context,
          controller: scrollController,
          child: SizedBox(
            width: totalW,
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                outerPad,
                0,
                outerPad,
                outerPad,
              ),
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
                    const SizedBox(width: gap),
                    SizedBox(
                      width: resolvedContentW,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: sep, width: 1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: buildLine(context, i, line),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        final horizontalController = horizontalScrollController;
        if (horizontalController == null) {
          return verticalList;
        }

        return _withMaterialScrollbar(
          context: context,
          controller: horizontalController,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: verticalList,
          ),
        );
      },
    );
  }
}

// ── Pretty tab ────────────────────────────────────────────────────────────────

class _PrettyTabMaterial extends StatelessWidget {
  const _PrettyTabMaterial({
    required this.jsonTreeEntries,
    required this.onToggleJsonNodeExpansion,
    required this.textEngine,
    required this.prettyBody,
    required this.language,
    required this.isDark,
    required this.scrollController,
    required this.searchQuery,
    required this.softWrap,
    required this.activeMatch,
    required this.matches,
    required this.enableSyntaxHighlight,
    required this.horizontalScrollController,
    required this.useStructuredJsonView,
  });

  final List<ResponseJsonTreeEntry> jsonTreeEntries;
  final void Function(String nodeId, bool isExpanded) onToggleJsonNodeExpansion;
  final ResponseTextEngine textEngine;
  final String prettyBody;
  final String language;
  final bool isDark;
  final ScrollController scrollController;
  final String searchQuery;
  final bool softWrap;
  final int activeMatch;
  final List<SearchMatch> matches;
  final bool enableSyntaxHighlight;
  final ScrollController horizontalScrollController;
  final bool useStructuredJsonView;

  static const _mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    final theme = isDark ? atomOneDarkTheme : atomOneLightTheme;
    final softWrapBg =
        theme['root']?.backgroundColor ?? const Color(0xffffffff);

    if (useStructuredJsonView) {
      return _JsonTreeTabMaterial(
        entries: jsonTreeEntries,
        scrollController: scrollController,
        horizontalScrollController: horizontalScrollController,
        searchQuery: searchQuery,
        softWrap: softWrap,
        activeMatch: activeMatch,
        matches: matches,
        onToggleNodeExpansion: onToggleJsonNodeExpansion,
      );
    }

    if (searchQuery.trim().isEmpty) {
      return SelectableRegion(
        selectionControls: materialTextSelectionControls,
        child: _LineNumberedBodyMaterial(
          textEngine: textEngine,
          scrollController: scrollController,
          softWrap: softWrap,
          softWrapLineContentBackground: softWrap ? softWrapBg : null,
          horizontalScrollController: horizontalScrollController,
          contentWidthEstimate: _estimatedMonospaceContentWidth(textEngine),
          buildLine: (context, index, line) => enableSyntaxHighlight
              ? HighlightedLineWidget(
                  line: line,
                  language: language,
                  theme: theme,
                  textStyle: _mono,
                  softWrap: softWrap,
                )
              : Text(line, style: _mono, softWrap: softWrap),
        ),
      );
    }

    return _SearchHighlightedScrollBodyMaterial(
      textEngine: textEngine,
      text: prettyBody,
      searchQuery: searchQuery,
      scrollController: scrollController,
      horizontalScrollController: horizontalScrollController,
      // Keep deterministic line heights while searching so arrow navigation
      // lands on the correct match instead of drifting with wrapped lines.
      softWrap: false,
      activeMatch: activeMatch,
      matches: matches,
    );
  }
}

class _JsonTreeTabMaterial extends StatelessWidget {
  const _JsonTreeTabMaterial({
    required this.entries,
    required this.scrollController,
    required this.horizontalScrollController,
    required this.searchQuery,
    required this.softWrap,
    required this.activeMatch,
    required this.matches,
    required this.onToggleNodeExpansion,
  });

  final List<ResponseJsonTreeEntry> entries;
  final ScrollController scrollController;
  final ScrollController horizontalScrollController;
  final String searchQuery;
  final bool softWrap;
  final int activeMatch;
  final List<SearchMatch> matches;
  final void Function(String nodeId, bool isExpanded) onToggleNodeExpansion;

  static const _base = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  List<InlineSpan> _buildSpans(
    BuildContext context,
    ResponseJsonTreeEntry entry,
    bool isActive,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final labelColor = scheme.primary;
    final defaultColor = scheme.onSurface;
    final nullColor = scheme.onSurface.withValues(alpha: 0.55);
    const highlightBg = Colors.amber;
    const activeHighlightBg = Colors.deepOrangeAccent;
    final query = searchQuery.trim().toLowerCase();

    TextStyle valueStyle;
    switch (entry.kind) {
      case ResponseJsonValueKind.string:
        valueStyle = _base.copyWith(color: Colors.green.shade700);
      case ResponseJsonValueKind.number:
        valueStyle = _base.copyWith(color: Colors.orange.shade700);
      case ResponseJsonValueKind.boolean:
        valueStyle = _base.copyWith(color: Colors.blue.shade700);
      case ResponseJsonValueKind.nil:
        valueStyle = _base.copyWith(color: nullColor);
      case ResponseJsonValueKind.object:
      case ResponseJsonValueKind.array:
        valueStyle = _base.copyWith(color: defaultColor);
    }

    final label = entry.label ?? 'JSON';
    return <InlineSpan>[
      ..._highlightedSegments(
        text: label,
        style: _base.copyWith(color: labelColor),
        query: query,
        background: isActive ? activeHighlightBg : highlightBg,
      ),
      TextSpan(
        text: entry.label == null ? ' ' : ': ',
        style: _base.copyWith(color: defaultColor),
      ),
      ..._highlightedSegments(
        text: entry.valueText,
        style: valueStyle,
        query: query,
        background: isActive ? activeHighlightBg : highlightBg,
      ),
    ];
  }

  static List<InlineSpan> _highlightedSegments({
    required String text,
    required TextStyle style,
    required String query,
    required Color background,
  }) {
    if (query.isEmpty) {
      return <InlineSpan>[TextSpan(text: text, style: style)];
    }

    final out = <InlineSpan>[];
    final lower = text.toLowerCase();
    var start = 0;
    var index = lower.indexOf(query);
    while (index >= 0) {
      if (index > start) {
        out.add(TextSpan(text: text.substring(start, index), style: style));
      }
      out.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: style.copyWith(
            backgroundColor: background.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      );
      start = index + query.length;
      index = lower.indexOf(query, start);
    }
    if (start < text.length) {
      out.add(TextSpan(text: text.substring(start), style: style));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final activeLineIndex = activeMatch >= 0 && activeMatch < matches.length
        ? matches[activeMatch].lineIndex
        : -1;

    return SelectableRegion(
      selectionControls: materialTextSelectionControls,
      child: _JsonTreeBodyMaterial(
        entries: entries,
        scrollController: scrollController,
        horizontalScrollController: horizontalScrollController,
        softWrap: softWrap,
        contentWidthEstimate: _estimatedJsonTreeContentWidth(entries),
        buildEntry: (context, index, entry) {
          final isActive = index == activeLineIndex;
          final rowColor = isActive
              ? Colors.deepOrangeAccent.withValues(alpha: 0.12)
              : null;

          return DecoratedBox(
            decoration: BoxDecoration(color: rowColor),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: entry.depth * 14.0),
                if (entry.hasChildren)
                  InkWell(
                    onTap: () =>
                        onToggleNodeExpansion(entry.nodeId, entry.isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1, right: 4),
                      child: Icon(
                        entry.isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 20),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: _buildSpans(context, entry, isActive)),
                    softWrap: softWrap,
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

class _JsonTreeBodyMaterial extends StatelessWidget {
  const _JsonTreeBodyMaterial({
    required this.entries,
    required this.scrollController,
    required this.horizontalScrollController,
    required this.softWrap,
    required this.contentWidthEstimate,
    required this.buildEntry,
  });

  final List<ResponseJsonTreeEntry> entries;
  final ScrollController scrollController;
  final ScrollController horizontalScrollController;
  final bool softWrap;
  final double contentWidthEstimate;
  final Widget Function(
    BuildContext context,
    int index,
    ResponseJsonTreeEntry entry,
  )
  buildEntry;

  @override
  Widget build(BuildContext context) {
    final lineCount = entries.length;
    final gutterW = _lineNumberGutterWidth(lineCount);
    final sep = Theme.of(context).dividerColor;
    final numStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 12,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    const outerPad = 12.0;
    const gap = 8.0;

    Widget verticalList({required double? width}) {
      final list = ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(outerPad, 0, outerPad, outerPad),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
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
              const SizedBox(width: gap),
              if (width == null)
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: sep, width: 1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: buildEntry(context, i, entry),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: width,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: sep, width: 1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: buildEntry(context, i, entry),
                    ),
                  ),
                ),
            ],
          );
        },
      );

      return _withMaterialScrollbar(
        context: context,
        controller: scrollController,
        child: width == null
            ? list
            : SizedBox(
                width: outerPad * 2 + gutterW + gap + width,
                child: list,
              ),
      );
    }

    if (softWrap) {
      return verticalList(width: null);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerMaxW = constraints.maxWidth - outerPad * 2;
        final viewportContentW = (innerMaxW - gutterW - gap).clamp(
          0.0,
          double.infinity,
        );
        final resolvedContentW = math.max(
          viewportContentW,
          contentWidthEstimate,
        );
        final content = verticalList(width: resolvedContentW);
        return _withMaterialScrollbar(
          context: context,
          controller: horizontalScrollController,
          child: SingleChildScrollView(
            controller: horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: content,
          ),
        );
      },
    );
  }
}

// ── Raw tab ───────────────────────────────────────────────────────────────────

class _RawTabMaterial extends StatelessWidget {
  const _RawTabMaterial({
    required this.textEngine,
    required this.body,
    required this.scrollController,
    required this.searchQuery,
    required this.activeMatch,
    required this.matches,
    required this.horizontalScrollController,
  });

  final ResponseTextEngine textEngine;
  final String body;
  final ScrollController scrollController;
  final String searchQuery;
  final int activeMatch;
  final List<SearchMatch> matches;
  final ScrollController horizontalScrollController;

  static const _textStyle = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    if (searchQuery.trim().isEmpty) {
      return SelectableRegion(
        selectionControls: materialTextSelectionControls,
        child: _LineNumberedBodyMaterial(
          textEngine: textEngine,
          scrollController: scrollController,
          softWrap: true,
          horizontalScrollController: horizontalScrollController,
          buildLine: (_, __, line) => Text(line, style: _textStyle),
        ),
      );
    }
    return _SearchHighlightedScrollBodyMaterial(
      textEngine: textEngine,
      text: body,
      searchQuery: searchQuery,
      scrollController: scrollController,
      horizontalScrollController: horizontalScrollController,
      // Keep deterministic line heights while searching so arrow navigation
      // lands on the correct match instead of drifting with wrapped lines.
      softWrap: false,
      activeMatch: activeMatch,
      matches: matches,
    );
  }
}

// ── Search-highlighted scroll body ───────────────────────────────────────────

class _SearchHighlightedScrollBodyMaterial extends StatelessWidget {
  const _SearchHighlightedScrollBodyMaterial({
    required this.textEngine,
    required this.text,
    required this.searchQuery,
    required this.scrollController,
    required this.horizontalScrollController,
    required this.softWrap,
    required this.activeMatch,
    required this.matches,
  });

  final ResponseTextEngine textEngine;
  final String text;
  final String searchQuery;
  final ScrollController scrollController;
  final ScrollController horizontalScrollController;
  final bool softWrap;
  final int activeMatch;
  final List<SearchMatch> matches;

  static const TextStyle _base = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    height: 1.5,
  );

  static List<InlineSpan> _spansForLine(
    String line,
    String q,
    Color highlightBg,
    Color activeHighlightBg,
    int lineIndex,
    ResponseSearchMatchLookup matchLookup,
  ) {
    if (q.isEmpty) {
      return [TextSpan(text: line, style: _base)];
    }
    final spans = <InlineSpan>[];
    final lower = line.toLowerCase();
    final nq = q.toLowerCase();
    var start = 0;
    var i = lower.indexOf(nq);
    while (i >= 0) {
      if (i > start) {
        spans.add(TextSpan(text: line.substring(start, i), style: _base));
      }
      final isActive = matchLookup.isActiveMatch(lineIndex, i);
      spans.add(
        TextSpan(
          text: line.substring(i, i + q.length),
          style: _base.copyWith(
            backgroundColor: (isActive ? activeHighlightBg : highlightBg)
                .withValues(alpha: 0.7),
            color: isActive ? Colors.black : null,
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
    const highlightBg = Colors.amber;
    const activeHighlightBg = Colors.deepOrangeAccent;
    final matchLookup = ResponseSearchMatchLookup.fromMatches(
      matches,
      activeMatch,
    );

    return SelectableRegion(
      selectionControls: materialTextSelectionControls,
      child: _LineNumberedBodyMaterial(
        textEngine: textEngine,
        scrollController: scrollController,
        softWrap: softWrap,
        horizontalScrollController: horizontalScrollController,
        contentWidthEstimate: _estimatedMonospaceContentWidth(textEngine),
        buildLine: (context, index, line) => Text.rich(
          TextSpan(
            children: _spansForLine(
              line,
              q,
              highlightBg,
              activeHighlightBg,
              index,
              matchLookup,
            ),
          ),
          softWrap: softWrap,
        ),
      ),
    );
  }
}

// ── Headers tab ───────────────────────────────────────────────────────────────

class _HeadersTabMaterial extends StatelessWidget {
  const _HeadersTabMaterial({
    required this.headers,
    required this.scrollController,
  });

  final Map<String, String> headers;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final entries = headers.entries.toList();
    final primary = Theme.of(context).colorScheme.primary;
    return _withMaterialScrollbar(
      context: context,
      controller: scrollController,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
            Divider(height: 0.5, color: Theme.of(context).dividerColor),
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
                    color: primary,
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

// ── Cookies tab ───────────────────────────────────────────────────────────────

class _CookiesTabMaterial extends StatelessWidget {
  const _CookiesTabMaterial({
    required this.cookies,
    required this.scrollController,
  });

  final List cookies;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (cookies.isEmpty) {
      return Center(
        child: Text(
          'No cookies',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }
    return _withMaterialScrollbar(
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

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChipMaterial extends StatelessWidget {
  const _StatusChipMaterial({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
