import 'dart:convert';

import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/domain/enums/ws_connection_mode.dart';
import 'package:aun_reqstudio/domain/models/ws_registry_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class WsSessionStorage {
  WsSessionStorage._();
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  static WebSocketRegistryState _defaultRegistry() {
    final id = _uuid.v4();
    return WebSocketRegistryState(
      ready: true,
      tabs: [WebSocketSessionTab(id: id)],
      activeSessionId: id,
    );
  }

  /// Loads persisted tabs (v2) or migrates legacy single-session JSON (v1).
  static Future<WebSocketRegistryState> loadRegistry() async {
    final raw = await _storage.read(key: StorageKeys.wsSavedSession);
    if (raw == null || raw.isEmpty) {
      return _defaultRegistry();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final v = map['v'];
      if (v == 2) {
        return _parseV2(map);
      }
      return _migrateV1(map);
    } catch (_) {
      return _defaultRegistry();
    }
  }

  static WebSocketRegistryState _parseV2(Map<String, dynamic> map) {
    final activeId = map['activeId'] as String? ?? '';
    final tabList = map['tabs'] as List<dynamic>? ?? [];
    final tabs = <WebSocketSessionTab>[];
    for (final e in tabList) {
      final m = e as Map<String, dynamic>;
      final id = m['id'] as String? ?? _uuid.v4();
      final url = m['url'] as String? ?? '';
      final protocols = m['protocols'] as String? ?? '';
      final headerList = m['headers'] as List<dynamic>? ?? [];
      final headers = headerList
          .map((h) {
            final hm = h as Map<String, dynamic>;
            return (
              key: hm['k'] as String? ?? '',
              value: hm['v'] as String? ?? '',
            );
          })
          .where((h) => h.key.isNotEmpty)
          .toList();
      final mode = WsConnectionMode.fromStorage(m['mode'] as String?);
      final socketIoNs = m['socketIoNs'] as String? ?? '/';
      final socketIoQuery = m['socketIoQuery'] as String? ?? '';
      final socketIoAuth = m['socketIoAuth'] as String? ?? '';
      tabs.add(
        WebSocketSessionTab(
          id: id,
          url: url,
          protocolsCsv: protocols,
          headers: headers,
          connectionMode: mode,
          socketIoNamespace: socketIoNs,
          socketIoQuery: socketIoQuery,
          socketIoAuthJson: socketIoAuth,
        ),
      );
    }
    if (tabs.isEmpty) {
      return _defaultRegistry();
    }
    var active = activeId;
    if (!tabs.any((t) => t.id == active)) {
      active = tabs.first.id;
    }
    return WebSocketRegistryState(
      ready: true,
      tabs: tabs,
      activeSessionId: active,
    );
  }

  /// Legacy: `{ "url", "protocols", "headers" }` at root.
  static WebSocketRegistryState _migrateV1(Map<String, dynamic> map) {
    final url = map['url'] as String? ?? '';
    final protocols = map['protocols'] as String? ?? '';
    final headerList = map['headers'] as List<dynamic>? ?? [];
    final headers = headerList
        .map((e) {
          final m = e as Map<String, dynamic>;
          return (
            key: m['k'] as String? ?? '',
            value: m['v'] as String? ?? '',
          );
        })
        .where((h) => h.key.isNotEmpty)
        .toList();
    final id = _uuid.v4();
    return WebSocketRegistryState(
      ready: true,
      tabs: [
        WebSocketSessionTab(
          id: id,
          url: url,
          protocolsCsv: protocols,
          headers: headers,
          connectionMode: WsConnectionMode.nativeWebSocket,
          socketIoNamespace: '/',
          socketIoQuery: '',
          socketIoAuthJson: '',
        ),
      ],
      activeSessionId: id,
    );
  }

  static Future<void> saveRegistry(WebSocketRegistryState state) async {
    if (!state.ready || state.tabs.isEmpty) return;
    final map = {
      'v': 2,
      'activeId': state.activeSessionId,
      'tabs': [
        for (final t in state.tabs)
          {
            'id': t.id,
            'url': t.url,
            'protocols': t.protocolsCsv,
            'mode': t.connectionMode.storageKey,
            'socketIoNs': t.socketIoNamespace,
            'socketIoQuery': t.socketIoQuery,
            'socketIoAuth': t.socketIoAuthJson,
            'headers': [
              for (final h in t.headers) {'k': h.key, 'v': h.value},
            ],
          },
      ],
    };
    await _storage.write(
      key: StorageKeys.wsSavedSession,
      value: jsonEncode(map),
    );
  }

  static Future<void> clear() async {
    await _storage.delete(key: StorageKeys.wsSavedSession);
  }
}
