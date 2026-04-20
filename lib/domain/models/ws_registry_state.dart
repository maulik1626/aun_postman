import 'package:aun_reqstudio/domain/enums/ws_connection_mode.dart';

/// Persisted WebSocket tab: identity + connection draft (URL, protocols, headers).
class WebSocketSessionTab {
  const WebSocketSessionTab({
    required this.id,
    this.url = '',
    this.protocolsCsv = '',
    this.headers = const [],
    this.connectionMode = WsConnectionMode.nativeWebSocket,
    this.socketIoNamespace = '/',
    this.socketIoQuery = '',
    this.socketIoAuthJson = '',
  });

  final String id;
  final String url;
  final String protocolsCsv;
  final List<({String key, String value})> headers;
  final WsConnectionMode connectionMode;
  /// Socket.IO namespace path, e.g. `/` or `/chat`.
  final String socketIoNamespace;
  /// Optional handshake query (`a=1&b=2`, no leading `?`).
  final String socketIoQuery;
  /// Optional JSON object for Socket.IO `auth` (e.g. `{"token":"…"}`).
  final String socketIoAuthJson;

  WebSocketSessionTab copyWith({
    String? url,
    String? protocolsCsv,
    List<({String key, String value})>? headers,
    WsConnectionMode? connectionMode,
    String? socketIoNamespace,
    String? socketIoQuery,
    String? socketIoAuthJson,
  }) =>
      WebSocketSessionTab(
        id: id,
        url: url ?? this.url,
        protocolsCsv: protocolsCsv ?? this.protocolsCsv,
        headers: headers ?? this.headers,
        connectionMode: connectionMode ?? this.connectionMode,
        socketIoNamespace: socketIoNamespace ?? this.socketIoNamespace,
        socketIoQuery: socketIoQuery ?? this.socketIoQuery,
        socketIoAuthJson: socketIoAuthJson ?? this.socketIoAuthJson,
      );
}

class WebSocketRegistryState {
  const WebSocketRegistryState({
    required this.ready,
    required this.tabs,
    required this.activeSessionId,
  });

  final bool ready;
  final List<WebSocketSessionTab> tabs;
  final String activeSessionId;

  int get activeIndex {
    final i = tabs.indexWhere((t) => t.id == activeSessionId);
    return i < 0 ? 0 : i;
  }

  WebSocketRegistryState copyWith({
    bool? ready,
    List<WebSocketSessionTab>? tabs,
    String? activeSessionId,
  }) =>
      WebSocketRegistryState(
        ready: ready ?? this.ready,
        tabs: tabs ?? this.tabs,
        activeSessionId: activeSessionId ?? this.activeSessionId,
      );
}
