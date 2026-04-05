import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:aun_postman/core/utils/ws_binary_codec.dart';
import 'package:aun_postman/core/utils/ws_socket_io_url.dart';
import 'package:aun_postman/domain/enums/ws_composer_format.dart';
import 'package:aun_postman/domain/enums/ws_connection_mode.dart';
import 'package:aun_postman/domain/enums/ws_message_direction.dart'
    show WsConnectionStatus, WsMessageDirection;
import 'package:aun_postman/domain/enums/ws_payload_kind.dart';
import 'package:aun_postman/domain/models/websocket_message.dart';
import 'package:aun_postman/features/settings/providers/app_settings_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'websocket_session_provider.freezed.dart';
part 'websocket_session_provider.g.dart';

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

@Riverpod(keepAlive: true)
class WebSocketSessionNotifier extends _$WebSocketSessionNotifier {
  static const _uuid = Uuid();
  static const _maxMessages = 500;
  WebSocketChannel? _channel;
  sio.Socket? _socket;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _userInitiatedDisconnect = false;
  String? _lastUrl;
  List<String> _lastProtocols = [];
  WsConnectionMode _lastMode = WsConnectionMode.nativeWebSocket;
  String _lastSocketIoNamespace = '/';
  String _lastSocketIoQuery = '';
  String _lastSocketIoAuthJson = '';

  @override
  WebSocketState build(String sessionId) {
    ref.onDispose(() {
      _reconnectTimer?.cancel();
      _sub?.cancel();
      _channel?.sink.close();
      _socket?.dispose();
    });
    return const WebSocketState();
  }

  void setHeaders(List<({String key, String value})> headers) {
    state = state.copyWith(headers: headers);
  }

  Future<void> _tearDownTransport() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    try {
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _scheduleReconnect() {
    _cancelReconnectTimer();
    if (!ref.read(appSettingsProvider).wsAutoReconnect) return;
    if (_userInitiatedDisconnect) return;
    final url = _lastUrl;
    if (url == null || url.isEmpty) return;
    if (_reconnectAttempt >= 8) return;

    final delays = [1, 2, 4, 8, 16, 16, 16, 16];
    final sec = delays[_reconnectAttempt.clamp(0, delays.length - 1)];
    _reconnectAttempt++;

    _reconnectTimer = Timer(Duration(seconds: sec), () async {
      if (_userInitiatedDisconnect) return;
      await connect(
        url,
        protocols: _lastProtocols,
        mode: _lastMode,
        socketIoNamespace: _lastSocketIoNamespace,
        socketIoQuery: _lastSocketIoQuery,
        socketIoAuthJson: _lastSocketIoAuthJson,
      );
    });
  }

  Future<void> connect(
    String url, {
    List<String> protocols = const [],
    WsConnectionMode mode = WsConnectionMode.nativeWebSocket,
    String socketIoNamespace = '/',
    String socketIoQuery = '',
    String socketIoAuthJson = '',
  }) async {
    _cancelReconnectTimer();
    _userInitiatedDisconnect = false;
    _lastUrl = url;
    _lastProtocols = List.from(protocols);
    _lastMode = mode;
    _lastSocketIoNamespace = socketIoNamespace;
    _lastSocketIoQuery = socketIoQuery;
    _lastSocketIoAuthJson = socketIoAuthJson;

    if (state.status == WsConnectionStatus.connected ||
        state.status == WsConnectionStatus.connecting) {
      await _tearDownTransport();
    }

    state = state.copyWith(
      status: WsConnectionStatus.connecting,
      error: null,
      connectedUrl: url.trim(),
    );

    if (mode == WsConnectionMode.socketIo) {
      await _connectSocketIo(url.trim());
      return;
    }

    try {
      final headerMap = <String, dynamic>{};
      for (final h in state.headers) {
        if (h.key.isNotEmpty) headerMap[h.key] = h.value;
      }

      final protoList = protocols
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final useIo = headerMap.isNotEmpty || protoList.isNotEmpty;

      _channel = useIo
          ? IOWebSocketChannel.connect(
              Uri.parse(url),
              headers: headerMap.isEmpty ? null : headerMap,
              protocols: protoList.isEmpty ? null : protoList,
              pingInterval: const Duration(seconds: 25),
            )
          : WebSocketChannel.connect(Uri.parse(url));

      await _channel!.ready;
      _reconnectAttempt = 0;
      state = state.copyWith(status: WsConnectionStatus.connected);

      _sub = _channel!.stream.listen(
        _onSocketData,
        onError: (e) {
          _sub?.cancel();
          _sub = null;
          final wasConnected = state.status == WsConnectionStatus.connected;
          state = state.copyWith(
            status: WsConnectionStatus.error,
            error: e.toString(),
          );
          if (wasConnected) _scheduleReconnect();
        },
        onDone: () {
          _sub?.cancel();
          _sub = null;
          if (state.status == WsConnectionStatus.connected) {
            state = state.copyWith(status: WsConnectionStatus.disconnected);
            _scheduleReconnect();
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

  Future<void> _connectSocketIo(String url) async {
    try {
      final uri = buildSocketIoConnectionUri(url, _lastSocketIoNamespace);
      final headerMap = <String, dynamic>{};
      for (final h in state.headers) {
        if (h.key.isNotEmpty) headerMap[h.key] = h.value;
      }

      Map<String, dynamic>? authMap;
      final authRaw = _lastSocketIoAuthJson.trim();
      if (authRaw.isNotEmpty) {
        final decoded = jsonDecode(authRaw);
        if (decoded is! Map) {
          state = state.copyWith(
            status: WsConnectionStatus.error,
            error: 'Socket.IO auth must be a JSON object',
          );
          return;
        }
        authMap = Map<String, dynamic>.from(decoded);
      }

      Map<String, String>? queryMap;
      final q = _lastSocketIoQuery.trim();
      if (q.isNotEmpty) {
        queryMap = Uri.splitQueryString(q);
      }

      final opts = sio.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .disableReconnection()
          .setTimeout(45000);

      if (headerMap.isNotEmpty) {
        opts.setExtraHeaders(headerMap);
      }
      if (authMap != null) {
        opts.setAuth(authMap);
      }
      if (queryMap != null && queryMap.isNotEmpty) {
        opts.setQuery(queryMap);
      }

      final socket = sio.io(uri.toString(), opts.build());
      _socket = socket;

      socket.onConnect((_) {
        _reconnectAttempt = 0;
        state = state.copyWith(
          status: WsConnectionStatus.connected,
          error: null,
          connectedUrl: uri.toString(),
        );
      });

      socket.onConnectError((data) {
        state = state.copyWith(
          status: WsConnectionStatus.error,
          error: data?.toString() ?? 'Socket.IO connect failed',
        );
      });

      socket.onDisconnect((_) {
        if (_userInitiatedDisconnect) return;
        if (state.status == WsConnectionStatus.connected) {
          state = state.copyWith(status: WsConnectionStatus.disconnected);
          _scheduleReconnect();
        }
      });

      socket.onAny((event, data) {
        _appendSocketIoIncoming(event, data);
      });

      socket.connect();
    } catch (e) {
      state = state.copyWith(
        status: WsConnectionStatus.error,
        error: e.toString(),
      );
    }
  }

  dynamic _jsonSafeForLog(dynamic v) {
    if (v == null) return null;
    if (v is String || v is num || v is bool) return v;
    if (v is Uint8List) {
      return {
        '__binary__': true,
        'bytes': v.length,
        'b64': base64Encode(v),
      };
    }
    if (v is List<int>) {
      return {
        '__binary__': true,
        'bytes': v.length,
        'b64': base64Encode(v),
      };
    }
    if (v is List) {
      return v.map(_jsonSafeForLog).toList();
    }
    if (v is Map) {
      return v.map((k, e) => MapEntry('$k', _jsonSafeForLog(e)));
    }
    return v.toString();
  }

  void _appendSocketIoIncoming(String event, dynamic data) {
    final enc = <String, dynamic>{
      'event': event,
      'data': _jsonSafeForLog(data),
    };
    String content;
    try {
      content = const JsonEncoder.withIndent('  ').convert(enc);
    } catch (_) {
      content = '$event: ${data.toString()}';
    }
    _appendMessage(
      WebSocketMessage(
        id: _uuid.v4(),
        content: content,
        direction: WsMessageDirection.received,
        timestamp: DateTime.now(),
        payloadKind: WsPayloadKind.text,
        byteLength: null,
      ),
    );
  }

  void _onSocketData(Object? data) {
    final WebSocketMessage message;
    if (data is String) {
      message = WebSocketMessage(
        id: _uuid.v4(),
        content: data,
        direction: WsMessageDirection.received,
        timestamp: DateTime.now(),
        payloadKind: WsPayloadKind.text,
        byteLength: null,
      );
    } else if (data is List<int>) {
      final bytes =
          data is Uint8List ? data : Uint8List.fromList(data);
      message = WebSocketMessage(
        id: _uuid.v4(),
        content: base64Encode(bytes),
        direction: WsMessageDirection.received,
        timestamp: DateTime.now(),
        payloadKind: WsPayloadKind.binary,
        byteLength: bytes.length,
      );
    } else {
      message = WebSocketMessage(
        id: _uuid.v4(),
        content: data.toString(),
        direction: WsMessageDirection.received,
        timestamp: DateTime.now(),
        payloadKind: WsPayloadKind.text,
        byteLength: null,
      );
    }
    _appendMessage(message);
  }

  void _appendMessage(WebSocketMessage message) {
    final updated = [...state.messages, message];
    state = state.copyWith(
      messages: updated.length > _maxMessages
          ? updated.sublist(updated.length - _maxMessages)
          : updated,
    );
  }

  /// Returns an error message if the payload could not be sent; null on success.
  String? sendComposed(String raw, WsComposerFormat format) {
    if (state.status != WsConnectionStatus.connected) {
      return 'Not connected';
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Message is empty';

    if (_socket != null) {
      return _sendSocketIo(trimmed, format);
    }

    switch (format) {
      case WsComposerFormat.text:
      case WsComposerFormat.json:
        _channel?.sink.add(trimmed);
        _appendMessage(
          WebSocketMessage(
            id: _uuid.v4(),
            content: trimmed,
            direction: WsMessageDirection.sent,
            timestamp: DateTime.now(),
            payloadKind: WsPayloadKind.text,
            byteLength: null,
          ),
        );
        return null;
      case WsComposerFormat.binaryHex:
        final bytes = tryDecodeHex(trimmed);
        if (bytes == null) {
          return 'Invalid hex (use pairs of 0-9, a-f)';
        }
        _channel?.sink.add(bytes);
        _appendMessage(
          WebSocketMessage(
            id: _uuid.v4(),
            content: base64Encode(bytes),
            direction: WsMessageDirection.sent,
            timestamp: DateTime.now(),
            payloadKind: WsPayloadKind.binary,
            byteLength: bytes.length,
          ),
        );
        return null;
      case WsComposerFormat.binaryBase64:
        final bytes = tryDecodeBase64(trimmed);
        if (bytes == null) {
          return 'Invalid Base64';
        }
        _channel?.sink.add(bytes);
        _appendMessage(
          WebSocketMessage(
            id: _uuid.v4(),
            content: base64Encode(bytes),
            direction: WsMessageDirection.sent,
            timestamp: DateTime.now(),
            payloadKind: WsPayloadKind.binary,
            byteLength: bytes.length,
          ),
        );
        return null;
    }
  }

  void _appendSocketIoSent(String event, dynamic data) {
    final enc = <String, dynamic>{
      'event': event,
      'data': _jsonSafeForLog(data),
    };
    final content = const JsonEncoder.withIndent('  ').convert(enc);
    _appendMessage(
      WebSocketMessage(
        id: _uuid.v4(),
        content: content,
        direction: WsMessageDirection.sent,
        timestamp: DateTime.now(),
        payloadKind: WsPayloadKind.text,
        byteLength: null,
      ),
    );
  }

  String? _sendSocketIo(String trimmed, WsComposerFormat format) {
    final socket = _socket;
    if (socket == null) return 'Not connected';

    switch (format) {
      case WsComposerFormat.text:
        socket.emit('message', trimmed);
        _appendSocketIoSent('message', trimmed);
        return null;
      case WsComposerFormat.json:
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            final m = Map<String, dynamic>.from(decoded);
            final ev = m['event'];
            if (ev is String && ev.isNotEmpty) {
              final payload =
                  m.containsKey('data') ? m['data'] : null;
              socket.emit(ev, payload);
              _appendSocketIoSent(ev, payload);
              return null;
            }
          }
          socket.emit('message', decoded);
          _appendSocketIoSent('message', decoded);
          return null;
        } catch (_) {
          return 'Invalid JSON for Socket.IO';
        }
      case WsComposerFormat.binaryHex:
        final bytes = tryDecodeHex(trimmed);
        if (bytes == null) {
          return 'Invalid hex (use pairs of 0-9, a-f)';
        }
        socket.emit('message', bytes);
        _appendMessage(
          WebSocketMessage(
            id: _uuid.v4(),
            content: base64Encode(bytes),
            direction: WsMessageDirection.sent,
            timestamp: DateTime.now(),
            payloadKind: WsPayloadKind.binary,
            byteLength: bytes.length,
          ),
        );
        return null;
      case WsComposerFormat.binaryBase64:
        final bytes = tryDecodeBase64(trimmed);
        if (bytes == null) {
          return 'Invalid Base64';
        }
        socket.emit('message', bytes);
        _appendMessage(
          WebSocketMessage(
            id: _uuid.v4(),
            content: base64Encode(bytes),
            direction: WsMessageDirection.sent,
            timestamp: DateTime.now(),
            payloadKind: WsPayloadKind.binary,
            byteLength: bytes.length,
          ),
        );
        return null;
    }
  }

  Future<void> disconnect() async {
    _userInitiatedDisconnect = true;
    _cancelReconnectTimer();
    await _sub?.cancel();
    await _channel?.sink.close();
    _sub = null;
    _channel = null;
    _socket?.dispose();
    _socket = null;
    state = state.copyWith(
      status: WsConnectionStatus.disconnected,
      error: null,
    );
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}
