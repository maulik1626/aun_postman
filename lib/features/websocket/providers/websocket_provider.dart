import 'dart:async';

import 'package:aun_postman/domain/enums/ws_message_direction.dart';
import 'package:aun_postman/domain/models/websocket_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'websocket_provider.freezed.dart';
part 'websocket_provider.g.dart';

@freezed
class WebSocketState with _$WebSocketState {
  const factory WebSocketState({
    @Default(WsConnectionStatus.disconnected) WsConnectionStatus status,
    @Default([]) List<WebSocketMessage> messages,
    @Default('') String connectedUrl,
    @Default([]) List<({String key, String value})> headers,
    String? error,
  }) = _WebSocketState;
}

@riverpod
class WebSocketNotifier extends _$WebSocketNotifier {
  static const _uuid = Uuid();
  static const _maxMessages = 500;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  @override
  WebSocketState build() => const WebSocketState();

  void setHeaders(List<({String key, String value})> headers) {
    state = state.copyWith(headers: headers);
  }

  Future<void> connect(String url) async {
    if (state.status == WsConnectionStatus.connected) {
      await disconnect();
    }

    state = state.copyWith(
      status: WsConnectionStatus.connecting,
      error: null,
      connectedUrl: url,
    );

    try {
      // Build headers map from enabled non-empty entries
      final headerMap = <String, dynamic>{};
      for (final h in state.headers) {
        if (h.key.isNotEmpty) headerMap[h.key] = h.value;
      }

      // Use IOWebSocketChannel for custom headers support on iOS/Android
      _channel = headerMap.isEmpty
          ? WebSocketChannel.connect(Uri.parse(url))
          : IOWebSocketChannel.connect(
              Uri.parse(url),
              headers: headerMap,
            );

      await _channel!.ready;
      state = state.copyWith(status: WsConnectionStatus.connected);

      _sub = _channel!.stream.listen(
        (data) {
          final message = WebSocketMessage(
            id: _uuid.v4(),
            content: data.toString(),
            direction: WsMessageDirection.received,
            timestamp: DateTime.now(),
          );
          final updated = [...state.messages, message];
          state = state.copyWith(
            messages: updated.length > _maxMessages
                ? updated.sublist(updated.length - _maxMessages)
                : updated,
          );
        },
        onError: (e) {
          _sub?.cancel();
          _sub = null;
          state = state.copyWith(
            status: WsConnectionStatus.error,
            error: e.toString(),
          );
        },
        onDone: () {
          if (state.status == WsConnectionStatus.connected) {
            state =
                state.copyWith(status: WsConnectionStatus.disconnected);
          }
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: WsConnectionStatus.error,
        error: e.toString(),
      );
    }
  }

  void sendMessage(String text) {
    if (state.status != WsConnectionStatus.connected || text.isEmpty) return;
    _channel?.sink.add(text);
    final message = WebSocketMessage(
      id: _uuid.v4(),
      content: text,
      direction: WsMessageDirection.sent,
      timestamp: DateTime.now(),
    );
    final updated = [...state.messages, message];
    state = state.copyWith(
      messages: updated.length > _maxMessages
          ? updated.sublist(updated.length - _maxMessages)
          : updated,
    );
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _sub = null;
    _channel = null;
    state = state.copyWith(
        status: WsConnectionStatus.disconnected, error: null);
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}
