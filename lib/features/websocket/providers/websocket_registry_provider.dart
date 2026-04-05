import 'dart:async';

import 'package:aun_postman/data/local/ws_session_storage.dart';
import 'package:aun_postman/domain/enums/ws_connection_mode.dart';
import 'package:aun_postman/domain/models/ws_registry_state.dart';
import 'package:aun_postman/features/websocket/providers/websocket_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

export 'package:aun_postman/domain/models/ws_registry_state.dart'
    show WebSocketRegistryState, WebSocketSessionTab;

part 'websocket_registry_provider.g.dart';

@Riverpod(keepAlive: true)
class WebSocketRegistry extends _$WebSocketRegistry {
  static const _maxTabs = 8;
  static const _uuid = Uuid();
  Timer? _persistTimer;

  @override
  WebSocketRegistryState build() {
    ref.onDispose(() => _persistTimer?.cancel());
    return const WebSocketRegistryState(
      ready: false,
      tabs: [],
      activeSessionId: '',
    );
  }

  Future<void> loadFromStorage() async {
    final loaded = await WsSessionStorage.loadRegistry();
    state = loaded;
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 450), () {
      final s = state;
      if (s.ready) {
        WsSessionStorage.saveRegistry(s);
      }
    });
  }

  Future<void> persistNow() async {
    _persistTimer?.cancel();
    if (state.ready) {
      await WsSessionStorage.saveRegistry(state);
    }
  }

  Future<void> clearAllSaved() async {
    _persistTimer?.cancel();
    for (final t in state.tabs) {
      ref.invalidate(webSocketSessionNotifierProvider(t.id));
    }
    await WsSessionStorage.clear();
    final id = _uuid.v4();
    state = WebSocketRegistryState(
      ready: true,
      tabs: [WebSocketSessionTab(id: id)],
      activeSessionId: id,
    );
  }

  void updateTabDraft(
    String sessionId, {
    required String url,
    required String protocolsCsv,
    required List<({String key, String value})> headers,
    WsConnectionMode? connectionMode,
    String? socketIoNamespace,
    String? socketIoQuery,
    String? socketIoAuthJson,
  }) {
    if (!state.ready) return;
    final tabs = state.tabs
        .map(
          (t) => t.id == sessionId
              ? t.copyWith(
                  url: url,
                  protocolsCsv: protocolsCsv,
                  headers: List<({String key, String value})>.from(headers),
                  connectionMode: connectionMode,
                  socketIoNamespace: socketIoNamespace,
                  socketIoQuery: socketIoQuery,
                  socketIoAuthJson: socketIoAuthJson,
                )
              : t,
        )
        .toList();
    state = state.copyWith(tabs: tabs);
    _schedulePersist();
  }

  void addTab() {
    if (!state.ready || state.tabs.length >= _maxTabs) return;
    final id = _uuid.v4();
    state = state.copyWith(
      tabs: [...state.tabs, WebSocketSessionTab(id: id)],
      activeSessionId: id,
    );
    _schedulePersist();
  }

  Future<void> removeTab(String id) async {
    if (!state.ready || state.tabs.length <= 1) return;
    await ref.read(webSocketSessionNotifierProvider(id).notifier).disconnect();
    ref.invalidate(webSocketSessionNotifierProvider(id));
    final oldTabs = state.tabs;
    final removeIndex = oldTabs.indexWhere((t) => t.id == id);
    final tabs = oldTabs.where((t) => t.id != id).toList();
    var active = state.activeSessionId;
    if (active == id) {
      if (removeIndex <= 0) {
        active = tabs.first.id;
      } else {
        active = oldTabs[removeIndex - 1].id;
      }
    }
    state = state.copyWith(tabs: tabs, activeSessionId: active);
    _schedulePersist();
  }

  void setActive(String id) {
    if (!state.ready || !state.tabs.any((t) => t.id == id)) return;
    if (state.activeSessionId == id) return;
    state = state.copyWith(activeSessionId: id);
    _schedulePersist();
  }
}
