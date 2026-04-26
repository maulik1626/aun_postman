import 'dart:async';
import 'dart:convert';

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/web/web_toast.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const int _kMaxWsTabs = 8;

final DateFormat _kWsMessageTimeFormat = DateFormat('h:mm:ss a');

void _showWebsocketCopiedToastMaterial(BuildContext context) {
  if (!context.mounted) return;
  if (AppPlatform.usesWebCustomUi) {
    WebToast.show(
      context,
      message: 'Copied to clipboard',
      type: WebToastType.success,
    );
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final mq = MediaQuery.of(context);
  final scheme = Theme.of(context).colorScheme;
  const snackBarHeight = 52.0;
  final top = mq.padding.top + 8;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: scheme.inverseSurface,
        content: Text(
          'Copied to clipboard',
          style: TextStyle(
            color: scheme.onInverseSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: mq.size.height - top - snackBarHeight,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}

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

class WebSocketScreenMaterial extends ConsumerStatefulWidget {
  const WebSocketScreenMaterial({super.key});

  @override
  ConsumerState<WebSocketScreenMaterial> createState() =>
      _WebSocketScreenMaterialState();
}

class _WebSocketScreenMaterialState
    extends ConsumerState<WebSocketScreenMaterial> {
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
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (modalContext) => _SavedComposeModalMaterial(
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
          final body =
              ref.read(wsComposerDraftProvider(sid)).trim();
          if (body.isEmpty) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Save'),
                content: const Text('Composer is empty.'),
                actions: [
                  TextButton(
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
    final primary = Theme.of(context).colorScheme.primary;

    ref.listen<WebSocketRegistryState>(webSocketRegistryProvider,
        (prev, next) {
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
      return const Center(child: CircularProgressIndicator());
    }

    final activeId = reg.activeSessionId;
    final hasMsgs = activeId.isNotEmpty
        ? ref
            .watch(webSocketSessionNotifierProvider(activeId))
            .messages
            .isNotEmpty
        : false;

    _syncTabStripKeys(reg.tabs.map((t) => t.id).toSet());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(AppRoutes.collections);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket'),
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Saved messages',
            onPressed: _openSavedSheet,
          ),
          if (hasMsgs && activeId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear messages',
              onPressed: () => ref
                  .read(webSocketSessionNotifierProvider(activeId)
                      .notifier)
                  .clearMessages(),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Tab strip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              for (var i = 0; i < reg.tabs.length; i++)
                Padding(
                  key: _tabStripKeys[reg.tabs[i].id],
                  padding: const EdgeInsets.only(right: 6),
                  child: _SessionTabChipMaterial(
                    label: _tabChipLabel(reg.tabs[i].url),
                    selected:
                        reg.tabs[i].id == reg.activeSessionId,
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
              IconButton(
                onPressed: _tryAddTab,
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 26,
                  color: primary,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6),
                constraints: const BoxConstraints(
                    minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
        Divider(
            height: 0.5,
            color: Theme.of(context).dividerColor),

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
                _WebSocketSessionPanelMaterial(
                  key: ValueKey(t.id),
                  sessionId: t.id,
                ),
            ],
          ),
        ),
      ],
      ),
      ),
    );
  }
}

// ── Session tab chip ─────────────────────────────────────────────────────────

class _SessionTabChipMaterial extends StatelessWidget {
  const _SessionTabChipMaterial({
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
    final primary = Theme.of(context).colorScheme.primary;
    final secondary =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.15)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primary
                : Theme.of(context).dividerColor,
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
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (canClose && onClose != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  Icons.cancel,
                  size: 16,
                  color: secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Session panel ─────────────────────────────────────────────────────────────

class _WebSocketSessionPanelMaterial extends ConsumerStatefulWidget {
  const _WebSocketSessionPanelMaterial({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<_WebSocketSessionPanelMaterial> createState() =>
      _WebSocketSessionPanelMaterialState();
}

class _WebSocketSessionPanelMaterialState
    extends ConsumerState<_WebSocketSessionPanelMaterial>
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
    _logFilterPageController =
        PageController(initialPage: _logFilter.index);
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
              .read(wsComposerFormatLiveProvider(widget.sessionId)
                  .notifier)
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
      if (f == WsLogFilter.sent &&
          m.direction != WsMessageDirection.sent) {
        return false;
      }
      if (f == WsLogFilter.received &&
          m.direction != WsMessageDirection.received) {
        return false;
      }
      return _messageMatchesQuery(m, _searchController.text);
    }).toList();
  }

  void _onLogFilterSegmentSelected(Set<int> s) {
    if (s.isEmpty) return;
    final v = WsLogFilter.values[s.first];
    if (v == _logFilter) return;
    setState(() => _logFilter = v);
    _logFilterPageController.animateToPage(
      v.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onLogFilterPageChanged(int i) {
    final v = WsLogFilter.values[i];
    if (v != _logFilter) setState(() => _logFilter = v);
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.55),
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
            horizontal: 12, vertical: 12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final msg = list[index];
          final isSent = msg.direction == WsMessageDirection.sent;
          return _MessageBubbleMaterial(
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
        WsComposerFormat.json => '{"event":"hello","data":{"x":1}}',
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
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
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
      final pretty =
          const JsonEncoder.withIndent('  ').convert(decoded);
      setState(() {
        _messageController.text = pretty;
        _messageController.selection = TextSelection.collapsed(
            offset: _messageController.text.length);
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
        .read(webSocketSessionNotifierProvider(widget.sessionId)
            .notifier)
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
        .map((r) => (
              key: r.keyController.text.trim(),
              value: r.valueController.text,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wsState = ref
        .watch(webSocketSessionNotifierProvider(widget.sessionId));
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);
    final surface = Theme.of(context).colorScheme.surfaceContainerLow;

    final isConnected =
        wsState.status == WsConnectionStatus.connected;
    final isConnecting =
        wsState.status == WsConnectionStatus.connecting;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = viewInsetsBottom > 0
        ? 0.0
        : MediaQuery.paddingOf(context).bottom;
    final headerPanelHeight =
        (MediaQuery.sizeOf(context).height * 0.30)
            .clamp(120.0, 220.0);
    final hasAnyMessages = wsState.messages.isNotEmpty;

    // Status dot color
    final dotColor = switch (wsState.status) {
      WsConnectionStatus.connected => Colors.green,
      WsConnectionStatus.connecting => Colors.orange,
      WsConnectionStatus.error => Colors.red,
      WsConnectionStatus.disconnected =>
        Theme.of(context).colorScheme.outline,
    };

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // ── URL + connect bar ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            color: surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // URL row
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        enabled: !isConnected && !isConnecting,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              _connectionMode ==
                                      WsConnectionMode.socketIo
                                  ? 'https://localhost:3000'
                                  : 'wss://echo.websocket.org',
                          hintStyle: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 13),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                        ),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      onPressed: !isConnected
                          ? () => setState(
                              () => _showHeaders = !_showHeaders)
                          : null,
                      icon: Icon(
                        Icons.tune,
                        size: 20,
                        color: _showHeaders ? primary : secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isConnecting)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      )
                    else if (isConnected)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        onPressed: () => ref
                            .read(webSocketSessionNotifierProvider(
                                    widget.sessionId)
                                .notifier)
                            .disconnect(),
                        child: const Text('Disconnect',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      )
                    else
                      AppGradientButton.material(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          final url = _urlController.text.trim();
                          if (url.isNotEmpty) {
                            AppHaptics.light();
                            ref
                                .read(
                                    webSocketSessionNotifierProvider(
                                            widget.sessionId)
                                        .notifier)
                                .setHeaders(_buildHeaders());
                            ref
                                .read(
                                    webSocketSessionNotifierProvider(
                                            widget.sessionId)
                                        .notifier)
                                .connect(
                                  url,
                                  protocols: _parseSubprotocols(),
                                  mode: _connectionMode,
                                  socketIoNamespace:
                                      _namespaceController.text,
                                  socketIoQuery:
                                      _socketIoQueryController.text,
                                  socketIoAuthJson:
                                      _socketIoAuthJsonController
                                          .text,
                                );
                            _scheduleDraftPersist();
                          }
                        },
                        child: const Text('Connect',
                            style: TextStyle(fontSize: 14)),
                      ),
                  ],
                ),
                // Connection mode + sub-protocol/socket.io fields
                if (!isConnected && !isConnecting) ...[
                  const SizedBox(height: 10),
                  SegmentedButton<WsConnectionMode>(
                    segments: const [
                      ButtonSegment(
                        value: WsConnectionMode.nativeWebSocket,
                        label: Text('WebSocket'),
                      ),
                      ButtonSegment(
                        value: WsConnectionMode.socketIo,
                        label: Text('Socket.IO'),
                      ),
                    ],
                    selected: {_connectionMode},
                    onSelectionChanged: (s) {
                      if (s.isEmpty) return;
                      setState(() => _connectionMode = s.first);
                      _scheduleDraftPersist();
                    },
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor:
                          primary.withValues(alpha: 0.15),
                      selectedForegroundColor: primary,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_connectionMode ==
                      WsConnectionMode.nativeWebSocket)
                    TextField(
                      controller: _subprotocolController,
                      style: const TextStyle(
                          fontFamily: 'JetBrainsMono', fontSize: 12),
                      decoration: const InputDecoration(
                        hintText:
                            'Subprotocols (optional, comma-separated)',
                        hintStyle: TextStyle(
                            fontFamily: 'JetBrainsMono', fontSize: 12),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      autocorrect: false,
                    )
                  else ...[
                    TextField(
                      controller: _namespaceController,
                      style: const TextStyle(
                          fontFamily: 'JetBrainsMono', fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Namespace (e.g. / or /chat)',
                        hintStyle: TextStyle(
                            fontFamily: 'JetBrainsMono', fontSize: 12),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      autocorrect: false,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use https:// or http:// (ws:// is converted). '
                      'Optional query & auth in connection headers panel.',
                      style: TextStyle(
                          fontSize: 11, height: 1.25, color: secondary),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: _saveAllTabs,
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Save tabs',
                              style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          foregroundColor: secondary,
                        ),
                        onPressed: _clearAllSaved,
                        child: const Text('Clear saved',
                            style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  // Auto-reconnect
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Auto-reconnect',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                            Text(
                              'After an unexpected disconnect',
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  color: secondary),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.75,
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: ref
                              .watch(appSettingsProvider)
                              .wsAutoReconnect,
                          activeThumbColor: primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setWsAutoReconnect(v),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Headers panel ─────────────────────────────────────────────
        if (_showHeaders && !isConnected)
          SliverToBoxAdapter(
            child: SizedBox(
              height: headerPanelHeight,
              child: Container(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_connectionMode == WsConnectionMode.socketIo)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'SOCKET.IO HANDSHAKE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                                color: secondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _socketIoQueryController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Query string (optional, e.g. token=abc&x=1)',
                                hintStyle: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 12),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                              ),
                              style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 12),
                              autocorrect: false,
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller:
                                  _socketIoAuthJsonController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Auth JSON (optional, e.g. {"token":"…"})',
                                hintStyle: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 12),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                              ),
                              style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 12),
                              minLines: 2,
                              maxLines: 4,
                              autocorrect: false,
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 10, 8, 4),
                      child: Row(
                        children: [
                          Text(
                            'CONNECTION HEADERS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: secondary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 30, minHeight: 30),
                            onPressed: _addHeaderRow,
                            icon: Icon(Icons.add_circle_outline,
                                size: 18, color: primary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification:
                            _unfocusOnUserScrollNotification,
                        child: ListView.builder(
                          primary: false,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          itemCount: _headerRows.length,
                          itemBuilder: (context, i) {
                            final row = _headerRows[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: row.keyController,
                                      style: const TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 12),
                                      decoration:
                                          const InputDecoration(
                                        hintText: 'Header name',
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          row.valueController,
                                      style: const TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 12),
                                      decoration:
                                          const InputDecoration(
                                        hintText: 'Value',
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 28, minHeight: 28),
                                    onPressed: () =>
                                        _removeHeaderRow(i),
                                    icon: const Icon(
                                        Icons.remove_circle,
                                        size: 18,
                                        color: Colors.red),
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

        // ── Search + filter ───────────────────────────────────────────
        if (hasAnyMessages) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search messages',
                  prefixIcon:
                      Icon(Icons.search_outlined, size: 18),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                      value: 0,
                      label: Text('All',
                          style: TextStyle(fontSize: 12))),
                  ButtonSegment(
                      value: 1,
                      label: Text('Sent',
                          style: TextStyle(fontSize: 12))),
                  ButtonSegment(
                      value: 2,
                      label: Text('Received',
                          style: TextStyle(fontSize: 12))),
                ],
                selected: {_logFilter.index},
                onSelectionChanged: _onLogFilterSegmentSelected,
                showSelectedIcon: false,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
        ],

        // ── Message list / empty state ────────────────────────────────
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: primary.withValues(
                                      alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons
                                      .swap_horiz_outlined,
                                  size: 40,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                isConnected
                                    ? 'Connected'
                                    : 'Not connected',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isConnected
                                    ? 'Send a message below'
                                    : 'Enter a URL and tap Connect',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: secondary),
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
                            for (final filter
                                in WsLogFilter.values)
                              _messageListPage(
                                context,
                                wsState.messages,
                                filter,
                              ),
                          ],
                        ),
                      ),
              ),

              // ── Composer ─────────────────────────────────────────
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
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLow,
                      border: Border(
                        top: BorderSide(
                            color:
                                Theme.of(context).dividerColor,
                            width: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<WsComposerFormat>(
                          segments: const [
                            ButtonSegment(
                              value: WsComposerFormat.text,
                              label: Text('Text',
                                  style:
                                      TextStyle(fontSize: 11)),
                            ),
                            ButtonSegment(
                              value: WsComposerFormat.json,
                              label: Text('JSON',
                                  style:
                                      TextStyle(fontSize: 11)),
                            ),
                            ButtonSegment(
                              value: WsComposerFormat.binaryHex,
                              label: Text('Hex',
                                  style:
                                      TextStyle(fontSize: 11)),
                            ),
                            ButtonSegment(
                              value:
                                  WsComposerFormat.binaryBase64,
                              label: Text('Base64',
                                  style:
                                      TextStyle(fontSize: 11)),
                            ),
                          ],
                          selected: {_composerFormat},
                          onSelectionChanged: (s) {
                            if (s.isEmpty) return;
                            final v = s.first;
                            if (v != _composerFormat) {
                              AppHaptics.light();
                              setState(
                                  () => _composerFormat = v);
                              ref
                                  .read(
                                    wsComposerFormatLiveProvider(
                                            widget.sessionId)
                                        .notifier,
                                  )
                                  .setFormat(v);
                            }
                          },
                          showSelectedIcon: false,
                        ),
                        if (_composerFormat ==
                            WsComposerFormat.json)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(
                                    top: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize
                                    .shrinkWrap,
                              ),
                              onPressed: _beautifyJson,
                              child: const Text('Beautify',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600)),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                constraints:
                                    const BoxConstraints(
                                        minHeight: 36),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  style: const TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        _composerPlaceholder(),
                                    hintStyle: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.zero,
                                  ),
                                  maxLines: 5,
                                  minLines: 1,
                                  onSubmitted: (_) =>
                                      _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary,
                                ),
                                child: const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.white,
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

// ── Saved compose modal ───────────────────────────────────────────────────────

class _SavedComposeModalMaterial extends ConsumerWidget {
  const _SavedComposeModalMaterial({
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
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);
    final h = MediaQuery.sizeOf(context).height * 0.52;

    return SizedBox(
      height: h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
                const Expanded(
                  child: Text(
                    'Saved messages',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: onSaveCurrent,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          Divider(height: 0.5, color: Theme.of(context).dividerColor),
          Expanded(
            child: saved.isEmpty
                ? Center(
                    child: Text(
                      'No saved messages yet.\nTap Save to store the composer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: secondary),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: _unfocusOnUserScrollNotification,
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      itemCount: saved.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 0.5,
                        indent: 16,
                        color: Theme.of(context).dividerColor,
                      ),
                      itemBuilder: (context, i) {
                        final m = saved[i];
                        return Dismissible(
                          key: ValueKey(m.uid),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          onDismissed: (_) => ref
                              .read(wsSavedComposeListProvider.notifier)
                              .delete(m.uid),
                          child: InkWell(
                            onTap: () => onPick(m.body, m.format),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatLabel(m.format),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: primary,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  Text(
                                    DateFormat.yMMMd()
                                        .add_jm()
                                        .format(m.savedAt),
                                    style: TextStyle(
                                        fontSize: 11, color: secondary),
                                  ),
                                ],
                              ),
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

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubbleMaterial extends StatefulWidget {
  const _MessageBubbleMaterial({
    super.key,
    required this.message,
    required this.isSent,
  });

  final WebSocketMessage message;
  final bool isSent;

  @override
  State<_MessageBubbleMaterial> createState() =>
      _MessageBubbleMaterialState();
}

class _MessageBubbleMaterialState
    extends State<_MessageBubbleMaterial> {
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
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);
    final isBinary =
        widget.message.payloadKind == WsPayloadKind.binary;
    final List<int> bytes = isBinary
        ? (() {
            try {
              return base64Decode(widget.message.content);
            } catch (_) {
              return <int>[];
            }
          })()
        : const <int>[];

    final isJson =
        !isBinary && _isJsonText(widget.message.content);

    final displayText = isBinary
        ? (_binaryAsHex
            ? formatHex(bytes)
            : widget.message.content)
        : (_isPrettyJson && isJson)
            ? _prettyPrint(widget.message.content)
            : widget.message.content;

    final sizeLabel = isBinary &&
            widget.message.byteLength != null
        ? '${widget.message.byteLength} B'
        : null;

    return Align(
      alignment: widget.isSent
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: displayText));
          AppHaptics.light();
          _showWebsocketCopiedToastMaterial(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          decoration: BoxDecoration(
            color: widget.isSent
                ? primary.withValues(alpha: 0.18)
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.7),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft:
                  Radius.circular(widget.isSent ? 14 : 3),
              bottomRight:
                  Radius.circular(widget.isSent ? 3 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sizeLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Text(sizeLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: secondary)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _kWsMessageTimeFormat
                          .format(widget.message.timestamp),
                      style: TextStyle(
                          fontSize: 10, color: secondary),
                    ),
                    if (isBinary) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(
                            () => _binaryAsHex = !_binaryAsHex),
                        child: Text(
                          _binaryAsHex ? 'Base64' : 'Hex',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primary),
                        ),
                      ),
                    ],
                    if (isJson) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(
                            () => _isPrettyJson = !_isPrettyJson),
                        child: Text(
                          _isPrettyJson ? 'Raw' : 'Pretty',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primary),
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

// ── Header row helper ─────────────────────────────────────────────────────────

class _HeaderRow {
  final keyController = TextEditingController();
  final valueController = TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
