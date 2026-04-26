import 'package:flutter/foundation.dart';

@immutable
class WebWorkspaceTab {
  const WebWorkspaceTab({
    required this.id,
    required this.collectionUid,
    required this.title,
    this.requestUid,
    this.folderUid,
    this.isDirty = false,
    this.isSending = false,
    this.hasResponse = false,
  });

  factory WebWorkspaceTab.newRequest({
    required String collectionUid,
    String? folderUid,
    int? timestamp,
  }) {
    final stamp = timestamp ?? DateTime.now().microsecondsSinceEpoch;
    return WebWorkspaceTab(
      id: 'new:$collectionUid:${folderUid ?? 'root'}:$stamp',
      collectionUid: collectionUid,
      folderUid: folderUid,
      title: 'New Request',
      isDirty: true,
    );
  }

  factory WebWorkspaceTab.savedRequest({
    required String collectionUid,
    required String requestUid,
    required String title,
  }) {
    return WebWorkspaceTab(
      id: savedRequestTabId(
        collectionUid: collectionUid,
        requestUid: requestUid,
      ),
      collectionUid: collectionUid,
      requestUid: requestUid,
      title: title,
    );
  }

  final String id;
  final String collectionUid;
  final String? requestUid;
  final String? folderUid;
  final String title;
  final bool isDirty;
  final bool isSending;
  final bool hasResponse;

  bool get isNewUnsaved => requestUid == null;

  bool get requiresCloseConfirmation => isNewUnsaved || isDirty || isSending;

  WebWorkspaceTab copyWith({
    String? title,
    bool? isDirty,
    bool? isSending,
    bool? hasResponse,
    String? requestUid,
  }) {
    return WebWorkspaceTab(
      id: id,
      collectionUid: collectionUid,
      requestUid: requestUid ?? this.requestUid,
      folderUid: folderUid,
      title: title ?? this.title,
      isDirty: isDirty ?? this.isDirty,
      isSending: isSending ?? this.isSending,
      hasResponse: hasResponse ?? this.hasResponse,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WebWorkspaceTab &&
        other.id == id &&
        other.collectionUid == collectionUid &&
        other.requestUid == requestUid &&
        other.folderUid == folderUid &&
        other.title == title &&
        other.isDirty == isDirty &&
        other.isSending == isSending &&
        other.hasResponse == hasResponse;
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectionUid,
    requestUid,
    folderUid,
    title,
    isDirty,
    isSending,
    hasResponse,
  );
}

String savedRequestTabId({
  required String collectionUid,
  required String requestUid,
}) {
  return '$collectionUid:$requestUid';
}

@immutable
class WebWorkspaceState {
  const WebWorkspaceState({
    this.tabs = const <WebWorkspaceTab>[],
    this.activeTabId,
  });

  final List<WebWorkspaceTab> tabs;
  final String? activeTabId;

  WebWorkspaceTab? get activeTab {
    for (final tab in tabs) {
      if (tab.id == activeTabId) return tab;
    }
    return null;
  }

  WebWorkspaceState copyWith({
    List<WebWorkspaceTab>? tabs,
    String? activeTabId,
    bool clearActiveTabId = false,
  }) {
    return WebWorkspaceState(
      tabs: tabs ?? this.tabs,
      activeTabId: clearActiveTabId ? null : (activeTabId ?? this.activeTabId),
    );
  }
}

class WebWorkspaceTabController extends ChangeNotifier {
  WebWorkspaceState _state = const WebWorkspaceState();

  WebWorkspaceState get state => _state;

  List<WebWorkspaceTab> get tabs => List.unmodifiable(_state.tabs);

  String? get activeTabId => _state.activeTabId;

  WebWorkspaceTab? get activeTab => _state.activeTab;

  void openNewRequest({
    required String collectionUid,
    String? folderUid,
    int? timestamp,
  }) {
    final tab = WebWorkspaceTab.newRequest(
      collectionUid: collectionUid,
      folderUid: folderUid,
      timestamp: timestamp,
    );
    _setState(
      _state.copyWith(tabs: [..._state.tabs, tab], activeTabId: tab.id),
    );
  }

  void openSavedRequest({
    required String collectionUid,
    required String requestUid,
    required String title,
  }) {
    final matchingOpenTab = _state.tabs
        .where(
          (tab) =>
              tab.collectionUid == collectionUid &&
              tab.requestUid == requestUid,
        )
        .firstOrNull;
    if (matchingOpenTab != null) {
      focusTab(matchingOpenTab.id);
      return;
    }

    final tabId = savedRequestTabId(
      collectionUid: collectionUid,
      requestUid: requestUid,
    );
    if (_state.tabs.any((tab) => tab.id == tabId)) {
      focusTab(tabId);
      return;
    }
    final tab = WebWorkspaceTab.savedRequest(
      collectionUid: collectionUid,
      requestUid: requestUid,
      title: title,
    );
    _setState(
      _state.copyWith(tabs: [..._state.tabs, tab], activeTabId: tab.id),
    );
  }

  void focusTab(String tabId) {
    if (_state.activeTabId == tabId) return;
    if (!_state.tabs.any((tab) => tab.id == tabId)) return;
    _setState(_state.copyWith(activeTabId: tabId));
  }

  bool requestCloseTab(String tabId) {
    final tab = _tabById(tabId);
    if (tab == null) return true;
    return !tab.requiresCloseConfirmation;
  }

  void closeTab(String tabId) {
    final index = _state.tabs.indexWhere((tab) => tab.id == tabId);
    if (index == -1) return;

    final nextTabs = [..._state.tabs]..removeAt(index);
    String? nextActiveId = _state.activeTabId;
    if (_state.activeTabId == tabId) {
      if (nextTabs.isEmpty) {
        nextActiveId = null;
      } else {
        nextActiveId = nextTabs[index.clamp(0, nextTabs.length - 1)].id;
      }
    }

    _setState(
      _state.copyWith(
        tabs: nextTabs,
        activeTabId: nextActiveId,
        clearActiveTabId: nextActiveId == null,
      ),
    );
  }

  void reportTabStatus({
    required String tabId,
    required String title,
    required bool isDirty,
    required bool isSending,
    required bool hasResponse,
    String? requestUid,
  }) {
    final index = _state.tabs.indexWhere((tab) => tab.id == tabId);
    if (index == -1) return;
    final current = _state.tabs[index];
    final updated = current.copyWith(
      title: title.trim().isEmpty ? current.title : title.trim(),
      isDirty: isDirty,
      isSending: isSending,
      hasResponse: hasResponse,
      requestUid: requestUid,
    );
    if (updated == current) return;
    final nextTabs = [..._state.tabs];
    nextTabs[index] = updated;
    _setState(_state.copyWith(tabs: nextTabs));
  }

  WebWorkspaceTab? _tabById(String tabId) {
    for (final tab in _state.tabs) {
      if (tab.id == tabId) return tab;
    }
    return null;
  }

  void _setState(WebWorkspaceState state) {
    _state = state;
    notifyListeners();
  }
}
