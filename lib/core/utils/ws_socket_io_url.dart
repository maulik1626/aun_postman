/// Normalizes `ws(s)://` to `http(s)://` for Socket.IO Engine.IO handshake.
Uri socketIoHandshakeUri(String url) {
  var t = url.trim();
  if (t.startsWith('wss://')) {
    t = 'https://${t.substring(6)}';
  } else if (t.startsWith('ws://')) {
    t = 'http://${t.substring(5)}';
  }
  return Uri.parse(t);
}

/// Builds the URI passed to `io()`, including [namespace] when not default `/`.
///
/// If [namespace] is `/`, the path and query from [url] are kept as the user
/// entered (so a single field like `https://host/chat` works). Otherwise the
/// path is replaced with [namespace] while scheme/host/port/query are preserved.
Uri buildSocketIoConnectionUri(String url, String namespace) {
  final hand = socketIoHandshakeUri(url);
  var ns = namespace.trim();
  if (ns.isEmpty) ns = '/';
  if (!ns.startsWith('/')) ns = '/$ns';

  if (ns == '/') {
    final pathEmpty = hand.path.isEmpty || hand.path == '/';
    if (pathEmpty) {
      return hand.replace(path: '/');
    }
    return hand;
  }

  return Uri(
    scheme: hand.scheme,
    userInfo: hand.userInfo.isEmpty ? null : hand.userInfo,
    host: hand.host,
    port: hand.hasPort ? hand.port : null,
    query: hand.query.isEmpty ? null : hand.query,
    path: ns,
  );
}
