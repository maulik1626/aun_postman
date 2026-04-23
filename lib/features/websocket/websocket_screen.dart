import 'dart:async';
import 'dart:convert';

import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/app/widgets/scaled_cupertino_switch.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/app_haptics.dart';
import 'package:aun_reqstudio/core/utils/ws_binary_codec.dart';
import 'package:aun_reqstudio/domain/enums/ws_composer_format.dart';
import 'package:aun_reqstudio/domain/enums/ws_connection_mode.dart';
import 'package:aun_reqstudio/domain/enums/ws_log_filter.dart';
import 'package:aun_reqstudio/domain/enums/ws_message_direction.dart';
import 'package:aun_reqstudio/domain/enums/ws_payload_kind.dart';
import 'package:aun_reqstudio/domain/models/websocket_message.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:aun_reqstudio/features/websocket/providers/websocket_registry_provider.dart';
import 'package:aun_reqstudio/features/websocket/providers/websocket_session_provider.dart';
import 'package:aun_reqstudio/features/websocket/providers/ws_composer_draft_provider.dart';
import 'package:aun_reqstudio/features/websocket/providers/ws_pending_compose_provider.dart';
import 'package:aun_reqstudio/features/websocket/providers/ws_saved_compose_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const int _kMaxWsTabs = 8;

final DateFormat _kWsMessageTimeFormat = DateFormat('h:mm:ss a');

void _showWebsocketCopiedToast(BuildContext context) {
  if (!context.mounted) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      final topInset = MediaQuery.of(ctx).padding.top + 8;
      final isDark = CupertinoTheme.brightnessOf(ctx) == Brightness.dark;
      return Positioned(
        left: 0,
        right: 0,
        top: topInset,
        child: IgnorePointer(
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground
                    .resolveFrom(ctx)
                    .withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CupertinoColors.separator
                      .resolveFrom(ctx)
                      .withValues(alpha: isDark ? 0.55 : 0.45),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black
                        .withValues(alpha: isDark ? 0.42 : 0.12),
                    blurRadius: isDark ? 20 : 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                child: Text(
                  'Copied to clipboard',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(ctx),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2000), () {
    if (!entry.mounted) return;
    entry.remove();
    entry.dispose();
  });
}

/// Dismisses the keyboard when the user scrolls (not programmatic scroll).
bool _unfocusOnUserScrollNotification(ScrollNotification n) {
  if (n is ScrollUpdateNotification && n.dragDetails != null) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
  return false;
}

String _tabChipLabel(String url) {
  final u = url.trim();
  if (u.isEmpty) return 'New';
  try {
    final uri = Uri.parse(u);
    final h = uri.host;
    if (h.isNotEmpty) {
      return h.length > 14 ? '${h.substring(0, 14)}…' : h;
    }
  } catch (_) {}
  return u.length > 16 ? '${u.substring(0, 16)}…' : u;
}

class WebSocketScreen extends ConsumerStatefulWidget {
  const WebSocketScreen({super.key});

  @override
  ConsumerState<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends ConsumerState<WebSocketScreen> {
  late final PageController _pageController;
  final Map<String, GlobalKey> _tabStripKeys = {};
  bool _storageLoadRequested = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncTabStripKeys(Set<String> sessionIds) {
    _tabStripKeys.removeWhere((id, _) => !sessionIds.contains(id));
    for (final id in sessionIds) {
      _tabStripKeys.putIfAbsent(id, GlobalKey.new);
    }
  }

  void _scrollTabChipIntoView(
    String sessionId, {
    bool waitExtraLayoutFrame = false,
  }) {
    void scroll() {
      if (!mounted) return;
      final ctx = _tabStripKeys[sessionId]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.35,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    void schedule() {
      if (!mounted) return;
      if (waitExtraLayoutFrame) {
        WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
      } else {
        scroll();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => schedule());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_storageLoadRequested) return;
    _storageLoadRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(webSocketRegistryProvider.notifier).loadFromStorage();
      if (!mounted) return;
      final reg = ref.read(webSocketRegistryProvider);
      if (reg.ready && _pageController.hasClients) {
        _pageController.jumpToPage(reg.activeIndex);
        if (reg.activeSessionId.isNotEmpty) {
          _scrollTabChipIntoView(
            reg.activeSessionId,
            waitExtraLayoutFrame: true,
          );
        }
      }
    });
  }

  void _tryAddTab() {
    final reg = ref.read(webSocketRegistryProvider);
    if (reg.tabs.length >= _kMaxWsTabs) {
      UserNotification.show(
        context: context,
        title: 'WebSocket',
        body: 'You can have at most $_kMaxWsTabs connections.',
      );
      return;
    }
    ref.read(webSocketRegistryProvider.notifier).addTab();
  }

  Future<void> _openSavedSheet() async {
    final reg = ref.read(webSocketRegistryProvider);
    if (!reg.ready || reg.activeSessionId.isEmpty) return;
    final sid = reg.activeSessionId;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (modalContext) => _SavedComposeModal(
        onPick: (body, format) {
          ref.read(wsPendingComposeNotifierProvider.notifier).enqueue(
                WsPendingCompose(
                  sessionId: sid,
                  body: body,
                  format: format,
                ),
              );
          Navigator.of(modalContext).pop();
        },
        onSaveCurrent: () async {
          final body = ref.read(wsComposerDraftProvider(sid)).trim();
          if (body.isEmpty) {
            await showCupertinoDialog<void>(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Save'),
                content: const Text('Composer is empty.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
          final format = ref.read(wsComposerFormatLiveProvider(sid));
          await ref.read(wsSavedComposeListProvider.notifier).saveBody(
                body: body,
                format: format,
              );
          if (modalContext.mounted) Navigator.of(modalContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reg = ref.watch(webSocketRegistryProvider);

    ref.listen<WebSocketRegistryState>(webSocketRegistryProvider, (prev, next) {
      if (!next.ready) return;
      if (prev == null || !prev.ready) return;
      if (prev.tabs.length != next.tabs.length) {
        final i = next.activeIndex.clamp(0, next.tabs.length - 1);
        final activeId = next.tabs[i].id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(i);
          }
          _scrollTabChipIntoView(
            activeId,
            waitExtraLayoutFrame: true,
          );
        });
      }
    });

    if (!reg.ready) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final activeId = reg.activeSessionId;
    final hasMsgs = activeId.isNotEmpty
        ? ref.watch(webSocketSessionNotifierProvider(activeId)).messages.isNotEmpty
        : false;

    _syncTabStripKeys(reg.tabs.map((t) => t.id).toSet());

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('WebSocket'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: _openSavedSheet,
                child: const Icon(CupertinoIcons.bookmark),
              ),
              if (hasMsgs && activeId.isNotEmpty)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: () => ref
                      .read(webSocketSessionNotifierProvider(activeId).notifier)
                      .clearMessages(),
                  child: const Icon(CupertinoIcons.trash),
                ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    for (var i = 0; i < reg.tabs.length; i++)
                      Padding(
                        key: _tabStripKeys[reg.tabs[i].id],
                        padding: const EdgeInsets.only(right: 6),
                        child: _SessionTabChip(
                          label: _tabChipLabel(reg.tabs[i].url),
                          selected: reg.tabs[i].id == reg.activeSessionId,
                          canClose: reg.tabs.length > 1,
                          onTap: () {
                            ref
                                .read(webSocketRegistryProvider.notifier)
                                .setActive(reg.tabs[i].id);
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOut,
                            );
                          },
                          onClose: reg.tabs.length > 1
                              ? () => ref
                                  .read(webSocketRegistryProvider.notifier)
                                  .removeTab(reg.tabs[i].id)
                              : null,
                        ),
                      ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(36, 36),
                      onPressed: _tryAddTab,
                      child: Icon(
                        CupertinoIcons.add_circled,
                        size: 26,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 0.5,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const PageScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  onPageChanged: (i) {
                    final r = ref.read(webSocketRegistryProvider);
                    if (i >= 0 && i < r.tabs.length) {
                      final id = r.tabs[i].id;
                      ref
                          .read(webSocketRegistryProvider.notifier)
                          .setActive(id);
                      _scrollTabChipIntoView(id);
                    }
                  },
                  children: [
                    for (final t in reg.tabs)
                      _WebSocketSessionPanel(
                        key: ValueKey(t.id),
                        sessionId: t.id,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTabChip extends StatelessWidget {
  const _SessionTabChip({
    required this.label,
    required this.selected,
    required this.canClose,
    required this.onTap,
    this.onClose,
  });

  final String label;
  final bool selected;
  final bool canClose;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.15)
              : CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primary
                : CupertinoColors.separator.resolveFrom(context),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            if (canClose && onClose != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WebSocketSessionPanel extends ConsumerStatefulWidget {
  const _WebSocketSessionPanel({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<_WebSocketSessionPanel> createState() =>
      _WebSocketSessionPanelState();
}

class _WebSocketSessionPanelState extends ConsumerState<_WebSocketSessionPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final TextEditingController _urlController;
  late final TextEditingController _subprotocolController;
  late final TextEditingController _namespaceController;
  late final TextEditingController _socketIoQueryController;
  late final TextEditingController _socketIoAuthJsonController;
  late final TextEditingController _messageController;
  late final TextEditingController _searchController;

  late final PageController _logFilterPageController;
  late final List<ScrollController> _logScrollControllers;

  final List<_HeaderRow> _headerRows = [];
  bool _showHeaders = false;

  WsConnectionMode _connectionMode = WsConnectionMode.nativeWebSocket;

  WsComposerFormat _composerFormat = WsComposerFormat.text;
  WsLogFilter _logFilter = WsLogFilter.all;

  ProviderSubscription<WebSocketState>? _wsSub;
  ProviderSubscription<WsPendingCompose?>? _pendingSnippetSub;
  bool _wsListenerRegistered = false;
  bool _scrollToBottomScheduled = false;
  bool _controllersBound = false;
  Timer? _draftDebounce;

  WebSocketSessionTab? _tabFor(WidgetRef r) {
    final reg = r.read(webSocketRegistryProvider);
    for (final t in reg.tabs) {
      if (t.id == widget.sessionId) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _logFilterPageController = PageController(initialPage: _logFilter.index);
    _logScrollControllers = List.generate(
      WsLogFilter.values.length,
      (_) => ScrollController(),
    );
    _urlController = TextEditingController();
    _subprotocolController = TextEditingController();
    _namespaceController = TextEditingController();
    _socketIoQueryController = TextEditingController();
    _socketIoAuthJsonController = TextEditingController();
    _messageController = TextEditingController();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _wsSub?.close();
    _pendingSnippetSub?.close();
    _urlController.dispose();
    _subprotocolController.dispose();
    _namespaceController.dispose();
    _socketIoQueryController.dispose();
    _socketIoAuthJsonController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _logFilterPageController.dispose();
    for (final c in _logScrollControllers) {
      c.dispose();
    }
    for (final r in _headerRows) {
      r.dispose();
    }
    super.dispose();
  }

  void _scheduleDraftPersist() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(webSocketRegistryProvider.notifier).updateTabDraft(
            widget.sessionId,
            url: _urlController.text,
            protocolsCsv: _subprotocolController.text,
            headers: _buildHeaders(),
            connectionMode: _connectionMode,
            socketIoNamespace: _namespaceController.text,
            socketIoQuery: _socketIoQueryController.text,
            socketIoAuthJson: _socketIoAuthJsonController.text,
          );
    });
  }

  void _bindFromRegistryOnce() {
    if (_controllersBound) return;
    final tab = _tabFor(ref);
    if (tab == null) return;
    _controllersBound = true;
    _connectionMode = tab.connectionMode;
    _urlController.text = tab.url;
    _subprotocolController.text = tab.protocolsCsv;
    _namespaceController.text = tab.socketIoNamespace;
    _socketIoQueryController.text = tab.socketIoQuery;
    _socketIoAuthJsonController.text = tab.socketIoAuthJson;
    for (final r in _headerRows) {
      r.dispose();
    }
    _headerRows.clear();
    if (tab.headers.isEmpty) {
      _headerRows.add(_HeaderRow());
    } else {
      for (final h in tab.headers) {
        final row = _HeaderRow();
        row.keyController.text = h.key;
        row.valueController.text = h.value;
        _headerRows.add(row);
      }
    }
    _attachHeaderListeners();
    _urlController.addListener(_scheduleDraftPersist);
    _subprotocolController.addListener(_scheduleDraftPersist);
    _namespaceController.addListener(_scheduleDraftPersist);
    _socketIoQueryController.addListener(_scheduleDraftPersist);
    _socketIoAuthJsonController.addListener(_scheduleDraftPersist);
    _messageController.addListener(() {
      ref
          .read(wsComposerDraftProvider(widget.sessionId).notifier)
          .setDraft(_messageController.text);
    });
    ref
        .read(wsComposerFormatLiveProvider(widget.sessionId).notifier)
        .setFormat(_composerFormat);
    if (mounted) setState(() {});
  }

  void _attachHeaderListeners() {
    for (final r in _headerRows) {
      r.keyController.removeListener(_scheduleDraftPersist);
      r.valueController.removeListener(_scheduleDraftPersist);
      r.keyController.addListener(_scheduleDraftPersist);
      r.valueController.addListener(_scheduleDraftPersist);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindFromRegistryOnce();
    if (_wsListenerRegistered) return;
    _wsListenerRegistered = true;
    _wsSub = ref.listenManual<WebSocketState>(
      webSocketSessionNotifierProvider(widget.sessionId),
      (prev, next) {
        if (next.messages.length != (prev?.messages.length ?? 0)) {
          _scheduleScrollToBottom();
        }
        if (next.status == WsConnectionStatus.error &&
            next.error != null &&
            prev?.status != WsConnectionStatus.error) {
          final ctx = context;
          if (!ctx.mounted) return;
          UserNotification.show(
            context: ctx,
            title: 'WebSocket',
            body: next.error!,
          );
        }
      },
    );
    _pendingSnippetSub ??= ref.listenManual<WsPendingCompose?>(
      wsPendingComposeNotifierProvider,
      (prev, next) {
        final p = next;
        if (p == null || p.sessionId != widget.sessionId) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _composerFormat = p.format;
            _messageController.text = p.body;
            _messageController.selection =
                TextSelection.collapsed(offset: p.body.length);
          });
          ref
              .read(wsComposerDraftProvider(widget.sessionId).notifier)
              .setDraft(p.body);
          ref
              .read(wsComposerFormatLiveProvider(widget.sessionId).notifier)
              .setFormat(p.format);
          ref.read(wsPendingComposeNotifierProvider.notifier).clear();
        });
      },
    );
  }

  void _scheduleScrollToBottom() {
    if (_scrollToBottomScheduled) return;
    _scrollToBottomScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomScheduled = false;
      if (!mounted) return;
      final c = _logScrollControllers[_logFilter.index];
      if (c.hasClients) {
        c.animateTo(
          c.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<WebSocketMessage> _filteredMessages(
    List<WebSocketMessage> all, {
    WsLogFilter? forFilter,
  }) {
    final f = forFilter ?? _logFilter;
    return all.where((m) {
      if (f == WsLogFilter.sent && m.direction != WsMessageDirection.sent) {
        return false;
      }
      if (f == WsLogFilter.received &&
          m.direction != WsMessageDirection.received) {
        return false;
      }
      return _messageMatchesQuery(m, _searchController.text);
    }).toList();
  }

  void _onLogFilterSegmentSelected(WsLogFilter? v) {
    if (v == null || v == _logFilter) return;
    setState(() => _logFilter = v);
    _logFilterPageController.animateToPage(
      v.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onLogFilterPageChanged(int i) {
    final v = WsLogFilter.values[i];
    if (v != _logFilter) {
      setState(() => _logFilter = v);
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _stepComposerFormat(int delta) {
    final values = WsComposerFormat.values;
    final i = values.indexOf(_composerFormat);
    final next = (i + delta).clamp(0, values.length - 1);
    if (next == i) return;
    AppHaptics.light();
    final f = values[next];
    setState(() => _composerFormat = f);
    ref
        .read(wsComposerFormatLiveProvider(widget.sessionId).notifier)
        .setFormat(f);
  }

  Widget _messageListPage(
    BuildContext context,
    List<WebSocketMessage> all,
    WsLogFilter filter,
  ) {
    final list = _filteredMessages(all, forFilter: filter);
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No matching messages',
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }
    final scrollIndex = filter.index;
    return NotificationListener<ScrollNotification>(
      onNotification: _unfocusOnUserScrollNotification,
      child: ListView.builder(
        primary: false,
        controller: _logScrollControllers[scrollIndex],
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final msg = list[index];
          final isSent = msg.direction == WsMessageDirection.sent;
          return _MessageBubble(
            key: ValueKey('${filter.name}-${msg.id}'),
            message: msg,
            isSent: isSent,
          );
        },
      ),
    );
  }

  bool _messageMatchesQuery(WebSocketMessage m, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    if (m.payloadKind == WsPayloadKind.text) {
      return m.content.toLowerCase().contains(s);
    }
    if (m.content.toLowerCase().contains(s)) return true;
    try {
      final bytes = base64Decode(m.content);
      return formatHex(bytes).toLowerCase().contains(s);
    } catch (_) {
      return false;
    }
  }

  String _composerPlaceholder() {
    if (_connectionMode == WsConnectionMode.socketIo) {
      return switch (_composerFormat) {
        WsComposerFormat.text => 'Plain text → event "message"…',
        WsComposerFormat.json =>
          '{"event":"hello","data":{"x":1}}',
        WsComposerFormat.binaryHex => '48656c6c6f (hex → "message")',
        WsComposerFormat.binaryBase64 => 'SGVsbG8= (Base64 → "message")',
      };
    }
    return switch (_composerFormat) {
      WsComposerFormat.text => 'Text message…',
      WsComposerFormat.json => '{"hello":"world"}',
      WsComposerFormat.binaryHex => '48656c6c6f (hex)',
      WsComposerFormat.binaryBase64 => 'SGVsbG8=',
    };
  }

  Future<void> _showAlert(String title, String message) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _beautifyJson() {
    try {
      final decoded = jsonDecode(_messageController.text);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      setState(() {
        _messageController.text = pretty;
        _messageController.selection =
            TextSelection.collapsed(offset: _messageController.text.length);
      });
      ref
          .read(wsComposerDraftProvider(widget.sessionId).notifier)
          .setDraft(pretty);
    } catch (_) {
      _showAlert('JSON', 'Could not parse JSON.');
    }
  }

  void _sendMessage() {
    final err = ref
        .read(webSocketSessionNotifierProvider(widget.sessionId).notifier)
        .sendComposed(_messageController.text, _composerFormat);
    if (err != null) {
      _showAlert('Send failed', err);
      return;
    }
    _messageController.clear();
    ref
        .read(wsComposerDraftProvider(widget.sessionId).notifier)
        .setDraft('');
  }

  Future<void> _saveAllTabs() async {
    ref.read(webSocketRegistryProvider.notifier).updateTabDraft(
          widget.sessionId,
          url: _urlController.text,
          protocolsCsv: _subprotocolController.text,
          headers: _buildHeaders(),
          connectionMode: _connectionMode,
          socketIoNamespace: _namespaceController.text,
          socketIoQuery: _socketIoQueryController.text,
          socketIoAuthJson: _socketIoAuthJsonController.text,
        );
    await ref.read(webSocketRegistryProvider.notifier).persistNow();
    if (!mounted) return;
    UserNotification.show(
      context: context,
      title: 'WebSocket',
      body: 'All tabs saved.',
    );
  }

  Future<void> _clearAllSaved() async {
    await ref.read(webSocketRegistryProvider.notifier).clearAllSaved();
    if (!mounted) return;
    UserNotification.show(
      context: context,
      title: 'WebSocket',
      body: 'Saved tabs cleared.',
    );
  }

  void _addHeaderRow() {
    setState(() => _headerRows.add(_HeaderRow()));
    _attachHeaderListeners();
    _scheduleDraftPersist();
  }

  void _removeHeaderRow(int index) {
    setState(() {
      _headerRows[index].dispose();
      _headerRows.removeAt(index);
    });
    _scheduleDraftPersist();
  }

  List<String> _parseSubprotocols() {
    return _subprotocolController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<({String key, String value})> _buildHeaders() {
    return _headerRows
        .where((r) => r.keyController.text.isNotEmpty)
        .map(
          (r) =>
              (key: r.keyController.text.trim(), value: r.valueController.text),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wsState =
        ref.watch(webSocketSessionNotifierProvider(widget.sessionId));

    final isConnected = wsState.status == WsConnectionStatus.connected;
    final isConnecting = wsState.status == WsConnectionStatus.connecting;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = viewInsetsBottom > 0
        ? 0.0
        : MediaQuery.paddingOf(context).bottom;
    final headerPanelHeight =
        (MediaQuery.sizeOf(context).height * 0.30).clamp(120.0, 220.0);

    final hasAnyMessages = wsState.messages.isNotEmpty;

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemBackground.resolveFrom(
                context,
              ),
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: switch (wsState.status) {
                          WsConnectionStatus.connected =>
                            CupertinoColors.systemGreen.resolveFrom(context),
                          WsConnectionStatus.connecting =>
                            CupertinoColors.systemOrange.resolveFrom(context),
                          WsConnectionStatus.error =>
                            CupertinoColors.destructiveRed,
                          WsConnectionStatus.disconnected =>
                            CupertinoColors.systemGrey4.resolveFrom(context),
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _urlController,
                        enabled: !isConnected && !isConnecting,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 13,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        placeholder: _connectionMode == WsConnectionMode.socketIo
                            ? 'https://localhost:3000'
                            : 'wss://echo.websocket.org',
                        placeholderStyle: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 13,
                          color: CupertinoColors.placeholderText.resolveFrom(
                            context,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemBackground
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      onPressed: !isConnected
                          ? () => setState(() => _showHeaders = !_showHeaders)
                          : null,
                      child: Icon(
                        CupertinoIcons.slider_horizontal_3,
                        size: 20,
                        color: _showHeaders
                            ? CupertinoTheme.of(context).primaryColor
                            : CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isConnecting)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoActivityIndicator(),
                      )
                    else if (isConnected)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        minimumSize: Size.zero,
                        color: CupertinoColors.destructiveRed,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () => ref
                            .read(
                              webSocketSessionNotifierProvider(widget.sessionId)
                                  .notifier,
                            )
                            .disconnect(),
                        child: const Text(
                          'Disconnect',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      AppGradientButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          final url = _urlController.text.trim();
                          if (url.isNotEmpty) {
                            AppHaptics.light();
                            ref
                                .read(
                                  webSocketSessionNotifierProvider(
                                    widget.sessionId,
                                  ).notifier,
                                )
                                .setHeaders(_buildHeaders());
                            ref
                                .read(
                                  webSocketSessionNotifierProvider(
                                    widget.sessionId,
                                  ).notifier,
                                )
                                .connect(
                                  url,
                                  protocols: _parseSubprotocols(),
                                  mode: _connectionMode,
                                  socketIoNamespace: _namespaceController.text,
                                  socketIoQuery: _socketIoQueryController.text,
                                  socketIoAuthJson:
                                      _socketIoAuthJsonController.text,
                                );
                            _scheduleDraftPersist();
                          }
                        },
                        child: const Text(
                          'Connect',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
                if (!isConnected && !isConnecting) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: CupertinoSlidingSegmentedControl<
                        WsConnectionMode>(
                      groupValue: _connectionMode,
                      children: const {
                        WsConnectionMode.nativeWebSocket: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('WebSocket'),
                        ),
                        WsConnectionMode.socketIo: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Socket.IO'),
                        ),
                      },
                      onValueChanged: (v) {
                        if (v == null) return;
                        setState(() => _connectionMode = v);
                        _scheduleDraftPersist();
                      },
                    ),
                  ),
                  if (_connectionMode == WsConnectionMode.nativeWebSocket)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CupertinoTextField(
                        controller: _subprotocolController,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        placeholder:
                            'Subprotocols (optional, comma-separated)',
                        placeholderStyle: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: CupertinoColors.placeholderText.resolveFrom(
                            context,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemBackground
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        autocorrect: false,
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CupertinoTextField(
                        controller: _namespaceController,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        placeholder: 'Namespace (e.g. / or /chat)',
                        placeholderStyle: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: CupertinoColors.placeholderText.resolveFrom(
                            context,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemBackground
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        autocorrect: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 2),
                      child: Text(
                        'Use https:// or http:// (ws:// is converted). '
                        'Optional query & auth in connection headers panel.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ],
                if (!isConnected && !isConnecting) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            onPressed: _saveAllTabs,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Save tabs',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoTheme.of(context)
                                      .primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          onPressed: _clearAllSaved,
                          child: Text(
                            'Clear saved',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto-reconnect',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.label
                                    .resolveFrom(context),
                              ),
                            ),
                            Text(
                              'After an unexpected disconnect',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ScaledCupertinoSwitch(
                        value:
                            ref.watch(appSettingsProvider).wsAutoReconnect,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setWsAutoReconnect(v),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_showHeaders && !isConnected)
          SliverToBoxAdapter(
            child: SizedBox(
              height: headerPanelHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemBackground
                      .resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_connectionMode == WsConnectionMode.socketIo)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'SOCKET.IO HANDSHAKE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            CupertinoTextField(
                              controller: _socketIoQueryController,
                              placeholder:
                                  'Query string (optional, e.g. token=abc&x=1)',
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors
                                    .secondarySystemBackground
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              autocorrect: false,
                            ),
                            const SizedBox(height: 6),
                            CupertinoTextField(
                              controller: _socketIoAuthJsonController,
                              placeholder:
                                  'Auth JSON (optional, e.g. {"token":"…"})',
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                              ),
                              minLines: 2,
                              maxLines: 4,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors
                                    .secondarySystemBackground
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              autocorrect: false,
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                      child: Row(
                        children: [
                          Text(
                            'CONNECTION HEADERS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                          const Spacer(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(30, 30),
                            onPressed: _addHeaderRow,
                            child: Icon(
                              CupertinoIcons.add_circled,
                              size: 18,
                              color: CupertinoTheme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _unfocusOnUserScrollNotification,
                        child: ListView.builder(
                          primary: false,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _headerRows.length,
                          itemBuilder: (context, i) {
                            final row = _headerRows[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CupertinoTextField(
                                      controller: row.keyController,
                                      placeholder: 'Header name',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 12,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors
                                            .secondarySystemBackground
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: CupertinoTextField(
                                      controller: row.valueController,
                                      placeholder: 'Value',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 12,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors
                                            .secondarySystemBackground
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(28, 28),
                                    onPressed: () => _removeHeaderRow(i),
                                    child: const Icon(
                                      CupertinoIcons.minus_circle_fill,
                                      size: 18,
                                      color: CupertinoColors.destructiveRed,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (hasAnyMessages) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: CupertinoTextField(
                controller: _searchController,
                placeholder: 'Search messages',
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    CupertinoIcons.search,
                    size: 18,
                    color: CupertinoColors.secondaryLabel.resolveFrom(
                      context,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemBackground
                      .resolveFrom(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CupertinoSlidingSegmentedControl<WsLogFilter>(
                groupValue: _logFilter,
                children: {
                  WsLogFilter.all: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('All', style: TextStyle(fontSize: 12)),
                  ),
                  WsLogFilter.sent: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Sent', style: TextStyle(fontSize: 12)),
                  ),
                  WsLogFilter.received: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Received',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                },
                onValueChanged: _onLogFilterSegmentSelected,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
        ],
        SliverFillRemaining(
          hasScrollBody: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: !hasAnyMessages
                    ? Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: CupertinoTheme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  CupertinoIcons.arrow_right_arrow_left_circle,
                                  size: 40,
                                  color:
                                      CupertinoTheme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                isConnected ? 'Connected' : 'Not connected',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isConnected
                                    ? 'Send a message below'
                                    : 'Enter a URL and tap Connect',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : PrimaryScrollController.none(
                        child: PageView(
                          controller: _logFilterPageController,
                          onPageChanged: _onLogFilterPageChanged,
                          physics: const PageScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            for (final filter in WsLogFilter.values)
                              _messageListPage(
                                context,
                                wsState.messages,
                                filter,
                              ),
                          ],
                        ),
                      ),
              ),
              if (isConnected)
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity;
                    if (v == null) return;
                    if (v < -200) {
                      _stepComposerFormat(1);
                    } else if (v > 200) {
                      _stepComposerFormat(-1);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 8,
                      top: 8,
                      bottom: safeBottom + 8,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemBackground
                          .resolveFrom(context),
                      border: Border(
                        top: BorderSide(
                          color: CupertinoColors.separator.resolveFrom(context),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CupertinoSlidingSegmentedControl<WsComposerFormat>(
                          groupValue: _composerFormat,
                          children: {
                            WsComposerFormat.text: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'Text',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            WsComposerFormat.json: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'JSON',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            WsComposerFormat.binaryHex: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'Hex',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            WsComposerFormat.binaryBase64: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'Base64',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          },
                          onValueChanged: (v) {
                            if (v != null && v != _composerFormat) {
                              AppHaptics.light();
                              setState(() => _composerFormat = v);
                              ref
                                  .read(
                                    wsComposerFormatLiveProvider(
                                      widget.sessionId,
                                    ).notifier,
                                  )
                                  .setFormat(v);
                            }
                          },
                        ),
                        if (_composerFormat == WsComposerFormat.json)
                          Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoButton(
                              padding: const EdgeInsets.only(top: 2),
                              minimumSize: Size.zero,
                              onPressed: _beautifyJson,
                              child: Text(
                                'Beautify',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoTheme.of(context)
                                      .primaryColor,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 36,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors
                                      .tertiarySystemBackground
                                      .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: CupertinoTextField(
                                  controller: _messageController,
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 14,
                                    color: CupertinoColors.label
                                        .resolveFrom(context),
                                  ),
                                  placeholder: _composerPlaceholder(),
                                  placeholderStyle: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 14,
                                    color: CupertinoColors.placeholderText
                                        .resolveFrom(context),
                                  ),
                                  decoration: null,
                                  padding: EdgeInsets.zero,
                                  maxLines: 5,
                                  minLines: 1,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(36, 36),
                              onPressed: _sendMessage,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: CupertinoTheme.of(context)
                                      .primaryColor,
                                ),
                                child: const Icon(
                                  CupertinoIcons.arrow_up,
                                  color: CupertinoColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SavedComposeModal extends ConsumerWidget {
  const _SavedComposeModal({
    required this.onPick,
    required this.onSaveCurrent,
  });

  final void Function(String body, WsComposerFormat format) onPick;
  final Future<void> Function() onSaveCurrent;

  String _formatLabel(WsComposerFormat f) => switch (f) {
        WsComposerFormat.text => 'Text',
        WsComposerFormat.json => 'JSON',
        WsComposerFormat.binaryHex => 'Hex',
        WsComposerFormat.binaryBase64 => 'Base64',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(wsSavedComposeListProvider);
    final h = MediaQuery.sizeOf(context).height * 0.52;

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
                const Expanded(
                  child: Text(
                    'Saved messages',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: onSaveCurrent,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          Expanded(
            child: saved.isEmpty
                ? Center(
                    child: Text(
                      'No saved messages yet.\nTap Save to store the composer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: _unfocusOnUserScrollNotification,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: saved.length,
                      separatorBuilder: (_, __) => Container(
                        height: 0.5,
                        margin: const EdgeInsets.only(left: 16),
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                      itemBuilder: (context, i) {
                        final m = saved[i];
                        return Dismissible(
                          key: ValueKey(m.uid),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: CupertinoColors.destructiveRed,
                            child: const Icon(
                              CupertinoIcons.delete,
                              color: CupertinoColors.white,
                            ),
                          ),
                          onDismissed: (_) => ref
                              .read(wsSavedComposeListProvider.notifier)
                              .delete(m.uid),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            alignment: Alignment.centerLeft,
                            onPressed: () => onPick(m.body, m.format),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatLabel(m.format),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        CupertinoTheme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 13,
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(m.savedAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
  });

  final WebSocketMessage message;
  final bool isSent;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _isPrettyJson = false;
  bool _binaryAsHex = false;

  String _prettyPrint(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  bool _isJsonText(String raw) {
    try {
      jsonDecode(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBinary = widget.message.payloadKind == WsPayloadKind.binary;
    final List<int> bytes = isBinary
        ? (() {
            try {
              return base64Decode(widget.message.content);
            } catch (_) {
              return <int>[];
            }
          })()
        : const <int>[];

    final isJson = !isBinary && _isJsonText(widget.message.content);

    final displayText = isBinary
        ? (_binaryAsHex
            ? formatHex(bytes)
            : widget.message.content)
        : (_isPrettyJson && isJson)
            ? _prettyPrint(widget.message.content)
            : widget.message.content;

    final sizeLabel = isBinary && widget.message.byteLength != null
        ? '${widget.message.byteLength} B'
        : null;

    return Align(
      alignment: widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: displayText));
          AppHaptics.light();
          _showWebsocketCopiedToast(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          decoration: BoxDecoration(
            color: widget.isSent
                ? CupertinoTheme.of(context)
                    .primaryColor
                    .withValues(alpha: 0.18)
                : CupertinoColors.secondarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(widget.isSent ? 14 : 3),
              bottomRight: Radius.circular(widget.isSent ? 3 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sizeLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Text(
                    sizeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _kWsMessageTimeFormat.format(widget.message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                    if (isBinary) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _binaryAsHex = !_binaryAsHex),
                        child: Text(
                          _binaryAsHex ? 'Base64' : 'Hex',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                    if (isJson) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isPrettyJson = !_isPrettyJson),
                        child: Text(
                          _isPrettyJson ? 'Raw' : 'Pretty',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow {
  final keyController = TextEditingController();
  final valueController = TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
