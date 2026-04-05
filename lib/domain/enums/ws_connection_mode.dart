/// Transport for a WebSocket tab: raw RFC 6455 or Socket.IO (Engine.IO).
enum WsConnectionMode {
  nativeWebSocket,
  socketIo;

  String get storageKey => switch (this) {
        WsConnectionMode.nativeWebSocket => 'native',
        WsConnectionMode.socketIo => 'socketio',
      };

  static WsConnectionMode fromStorage(String? value) {
    if (value == 'socketio') return WsConnectionMode.socketIo;
    return WsConnectionMode.nativeWebSocket;
  }
}
