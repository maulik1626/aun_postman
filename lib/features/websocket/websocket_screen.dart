import 'dart:convert';

import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/app/widgets/scaled_cupertino_switch.dart';
import 'package:aun_postman/core/notifications/user_notification.dart';
import 'package:aun_postman/core/utils/app_haptics.dart';
import 'package:aun_postman/core/utils/ws_binary_codec.dart';
import 'package:aun_postman/data/local/ws_session_storage.dart';
import 'package:aun_postman/features/settings/providers/app_settings_provider.dart';
import 'package:aun_postman/domain/enums/ws_composer_format.dart';
import 'package:aun_postman/domain/enums/ws_log_filter.dart';
import 'package:aun_postman/domain/enums/ws_message_direction.dart';
import 'package:aun_postman/domain/enums/ws_payload_kind.dart';
import 'package:aun_postman/domain/models/websocket_message.dart';
import 'package:aun_postman/features/websocket/providers/websocket_provider.dart';
import 'package:aun_postman/features/websocket/providers/ws_saved_compose_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Dismisses the keyboard when the user scrolls (not programmatic scroll).
bool _unfocusOnUserScrollNotification(ScrollNotification n) {
  if (n is ScrollUpdateNotification && n.dragDetails != null) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
  return false;
}

class WebSocketScreen extends ConsumerStatefulWidget {
  const WebSocketScreen({super.key});

  @override
  ConsumerState<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends ConsumerState<WebSocketScreen> {
  final _urlController = TextEditingController();
  final _subprotocolController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  late final PageController _logFilterPageController;
  late final List<ScrollController> _logScrollControllers;

  final List<_HeaderRow> _headerRows = [];
  bool _showHeaders = false;

  WsComposerFormat _composerFormat = WsComposerFormat.text;
  WsLogFilter _logFilter = WsLogFilter.all;

  ProviderSubscription<WebSocketState>? _wsSub;
  bool _wsListenerRegistered = false;
  bool _scrollToBottomScheduled = false;

  @override
  void initState() {
    super.initState();
    _logFilterPageController = PageController(initialPage: _logFilter.index);
    _logScrollControllers = List.generate(
      WsLogFilter.values.length,
      (_) => ScrollController(),
    );
    _addHeaderRow();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedWsSession());
  }

  Future<void> _loadSavedWsSession() async {
    final snap = await WsSessionStorage.load();
    if (!mounted || snap == null) return;
    setState(() {
      _urlController.text = snap.url;
      _subprotocolController.text = snap.protocolsCsv;
      for (final r in _headerRows) {
        r.dispose();
      }
      _headerRows.clear();
      if (snap.headers.isEmpty) {
        _headerRows.add(_HeaderRow());
      } else {
        for (final h in snap.headers) {
          final row = _HeaderRow();
          row.keyController.text = h.key;
          row.valueController.text = h.value;
          _headerRows.add(row);
        }
      }
    });
  }

  Future<void> _saveWsSession() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      await _showAlert('Session', 'Enter a URL before saving.');
      return;
    }
    await WsSessionStorage.save(
      url: url,
      protocolsCsv: _subprotocolController.text.trim(),
      headers: _buildHeaders(),
    );
    if (!mounted) return;
    UserNotification.show(
      context: context,
      title: 'WebSocket',
      body: 'Connection details saved.',
    );
  }

  Future<void> _clearWsSession() async {
    await WsSessionStorage.clear();
    if (!mounted) return;
    UserNotification.show(
      context: context,
      title: 'WebSocket',
      body: 'Saved session cleared.',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wsListenerRegistered) return;
    _wsListenerRegistered = true;
    _wsSub = ref.listenManual<WebSocketState>(
      webSocketNotifierProvider,
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
  }

  @override
  void dispose() {
    _wsSub?.close();
    _wsSub = null;
    _urlController.dispose();
    _subprotocolController.dispose();
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

  void _addHeaderRow() {
    setState(() => _headerRows.add(_HeaderRow()));
  }

  void _removeHeaderRow(int index) {
    setState(() {
      _headerRows[index].dispose();
      _headerRows.removeAt(index);
    });
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
    setState(() => _composerFormat = values[next]);
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
    } catch (_) {
      _showAlert('JSON', 'Could not parse JSON.');
    }
  }

  void _sendMessage() {
    final err = ref
        .read(webSocketNotifierProvider.notifier)
        .sendComposed(_messageController.text, _composerFormat);
    if (err != null) {
      _showAlert('Send failed', err);
      return;
    }
    _messageController.clear();
  }

  Future<void> _openSavedSheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (modalContext) => _SavedComposeModal(
        onPick: (body, format) {
          setState(() {
            _composerFormat = format;
            _messageController.text = body;
            _messageController.selection =
                TextSelection.collapsed(offset: body.length);
          });
          Navigator.of(modalContext).pop();
        },
        onSaveCurrent: () async {
          final body = _messageController.text.trim();
          if (body.isEmpty) {
            await _showAlert('Save', 'Composer is empty.');
            return;
          }
          await ref.read(wsSavedComposeListProvider.notifier).saveBody(
                body: body,
                format: _composerFormat,
              );
          if (modalContext.mounted) Navigator.of(modalContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(webSocketNotifierProvider);

    final isConnected = wsState.status == WsConnectionStatus.connected;
    final isConnecting = wsState.status == WsConnectionStatus.connecting;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = viewInsetsBottom > 0
        ? 0.0
        : MediaQuery.paddingOf(context).bottom;
    final headerPanelHeight =
        (MediaQuery.sizeOf(context).height * 0.30).clamp(120.0, 220.0);

    final hasAnyMessages = wsState.messages.isNotEmpty;

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('WebSocket'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 44,
                  onPressed: _openSavedSheet,
                  child: const Icon(CupertinoIcons.bookmark),
                ),
                if (hasAnyMessages)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44,
                    onPressed: () => ref
                        .read(webSocketNotifierProvider.notifier)
                        .clearMessages(),
                    child: const Icon(CupertinoIcons.trash),
                  ),
              ],
            ),
          ),
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
                      placeholder: 'wss://echo.websocket.org',
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
                    minSize: 32,
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
                      minSize: 0,
                      color: CupertinoColors.destructiveRed,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () => ref
                          .read(webSocketNotifierProvider.notifier)
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
                              .read(webSocketNotifierProvider.notifier)
                              .setHeaders(_buildHeaders());
                          ref
                              .read(webSocketNotifierProvider.notifier)
                              .connect(url, protocols: _parseSubprotocols());
                        }
                      },
                      child: const Text(
                        'Connect',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
                  if (!isConnected && !isConnecting)
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
                    ),
                  if (!isConnected && !isConnecting) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              onPressed: _saveWsSession,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Save session',
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
                            onPressed: _clearWsSession,
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
                              minSize: 30,
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
                                    minSize: 28,
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
                                    CupertinoIcons
                                        .arrow_right_arrow_left_circle,
                                    size: 40,
                                    color:
                                        CupertinoTheme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  isConnected ? 'Connected' : 'Not connected',
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
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
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
                              }
                            },
                          ),
                          if (_composerFormat == WsComposerFormat.json)
                            Align(
                              alignment: Alignment.centerRight,
                              child: CupertinoButton(
                                padding: const EdgeInsets.only(top: 2),
                                minSize: 0,
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
                                minSize: 36,
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
      ),
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
                                  color: CupertinoTheme.of(context).primaryColor,
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
                                DateFormat.yMMMd().add_jm().format(m.savedAt),
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: widget.isSent
              ? CupertinoTheme.of(context).primaryColor.withOpacity(0.18)
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
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
              child: SelectableRegion(
                selectionControls: cupertinoTextSelectionControls,
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm:ss').format(widget.message.timestamp),
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: displayText));
                    },
                    child: Icon(
                      CupertinoIcons.doc_on_doc,
                      size: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
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

class _HeaderRow {
  final keyController = TextEditingController();
  final valueController = TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
