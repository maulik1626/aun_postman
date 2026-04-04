import 'dart:convert';

import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/domain/enums/ws_message_direction.dart';
import 'package:aun_postman/domain/models/websocket_message.dart';
import 'package:aun_postman/features/websocket/providers/websocket_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WebSocketScreen extends ConsumerStatefulWidget {
  const WebSocketScreen({super.key});

  @override
  ConsumerState<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends ConsumerState<WebSocketScreen> {
  final _urlController = TextEditingController();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Header rows: key controller, value controller
  final List<_HeaderRow> _headerRows = [];
  bool _showHeaders = false;

  @override
  void initState() {
    super.initState();
    _addHeaderRow();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
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

  List<({String key, String value})> _buildHeaders() {
    return _headerRows
        .where((r) => r.keyController.text.isNotEmpty)
        .map((r) => (
              key: r.keyController.text.trim(),
              value: r.valueController.text,
            ))
        .toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(webSocketNotifierProvider);

    ref.listen(webSocketNotifierProvider, (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    final isConnected = wsState.status == WsConnectionStatus.connected;
    final isConnecting = wsState.status == WsConnectionStatus.connecting;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom > 0
        ? MediaQuery.of(context).viewInsets.bottom
        : MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('WebSocket'),
        trailing: wsState.messages.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 44,
                onPressed: () =>
                    ref.read(webSocketNotifierProvider.notifier).clearMessages(),
                child: const Icon(CupertinoIcons.trash),
              )
            : null,
      ),
      child: Column(
        children: [
          // ── Connection bar ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemBackground
                  .resolveFrom(context),
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Status dot
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
                      color: CupertinoColors.placeholderText
                          .resolveFrom(context),
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemBackground
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                ),
                const SizedBox(width: 8),
                // Headers toggle
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
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(width: 4),
                // Connect / Disconnect
                if (isConnecting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: CupertinoActivityIndicator(),
                  )
                else if (isConnected)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
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
                        horizontal: 14, vertical: 7),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: () {
                      final url = _urlController.text.trim();
                      if (url.isNotEmpty) {
                        ref
                            .read(webSocketNotifierProvider.notifier)
                            .setHeaders(_buildHeaders());
                        ref
                            .read(webSocketNotifierProvider.notifier)
                            .connect(url);
                      }
                    },
                    child: const Text('Connect',
                        style: TextStyle(fontSize: 14)),
                  ),
              ],
            ),
          ),

          // ── Headers panel (collapsible) ────────────────────────────────────
          if (_showHeaders && !isConnected)
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
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
                            color:
                                CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _headerRows.length,
                      itemBuilder: (context, i) {
                        final row = _headerRows[i];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: CupertinoTextField(
                                  controller: row.keyController,
                                  placeholder: 'Header name',
                                  style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 12),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors
                                        .secondarySystemBackground
                                        .resolveFrom(context),
                                    borderRadius:
                                        BorderRadius.circular(8),
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
                                      fontSize: 12),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors
                                        .secondarySystemBackground
                                        .resolveFrom(context),
                                    borderRadius:
                                        BorderRadius.circular(8),
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
                ],
              ),
            ),

          // ── Error bar ──────────────────────────────────────────────────────
          if (wsState.status == WsConnectionStatus.error &&
              wsState.error != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.destructiveRed.withOpacity(0.12),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    color: CupertinoColors.destructiveRed,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      wsState.error!,
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Messages ──────────────────────────────────────────────────────
          Expanded(
            child: wsState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_right_arrow_left_circle,
                          size: 52,
                          color: CupertinoTheme.of(context)
                              .primaryColor
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isConnected ? 'Connected' : 'Not connected',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isConnected
                              ? 'Send a message below'
                              : 'Enter a URL and tap Connect',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    itemCount: wsState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = wsState.messages[index];
                      final isSent =
                          msg.direction == WsMessageDirection.sent;
                      return _MessageBubble(
                        key: ValueKey(msg.id),
                        message: msg,
                        isSent: isSent,
                      );
                    },
                  ),
          ),

          // ── Message input bar ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: bottomInset + 8,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemBackground
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: CupertinoTextField(
                      controller: _messageController,
                      enabled: isConnected,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 14,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                      placeholder: isConnected
                          ? 'Send a message…'
                          : 'Connect first',
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
                      onSubmitted: isConnected ? _sendMessage : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 36,
                  onPressed: isConnected
                      ? () => _sendMessage(_messageController.text)
                      : null,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? CupertinoTheme.of(context).primaryColor
                          : CupertinoColors.systemGrey4
                              .resolveFrom(context),
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
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(webSocketNotifierProvider.notifier).sendMessage(text.trim());
    _messageController.clear();
  }
}

// ── _MessageBubble ────────────────────────────────────────────────────────────

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
  bool _isPretty = false;

  String _prettyPrint(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  bool _isJson(String raw) {
    try {
      jsonDecode(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJson = _isJson(widget.message.content);
    final displayText = (_isPretty && isJson)
        ? _prettyPrint(widget.message.content)
        : widget.message.content;

    return Align(
      alignment:
          widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
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
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 9, 12, 4),
              child: SelectableText(
                displayText,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 0, 8, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm:ss')
                        .format(widget.message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context),
                    ),
                  ),
                  if (isJson) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isPretty = !_isPretty),
                      child: Text(
                        _isPretty ? 'Raw' : 'Pretty',
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
                      Clipboard.setData(ClipboardData(
                          text: widget.message.content));
                    },
                    child: Icon(
                      CupertinoIcons.doc_on_doc,
                      size: 12,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context),
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

// ── _HeaderRow ────────────────────────────────────────────────────────────────

class _HeaderRow {
  final keyController = TextEditingController();
  final valueController = TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
