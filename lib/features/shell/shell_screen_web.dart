import 'dart:async';
import 'dart:math' show min;

import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/web/web_chrome_layout.dart';
import 'package:aun_reqstudio/app/web/browser_json_export.dart';
import 'package:aun_reqstudio/app/web/context_menu_blocker.dart';
import 'package:aun_reqstudio/app/web/web_toast.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/domain/enums/http_method.dart';
import 'package:aun_reqstudio/domain/models/collection.dart';
import 'package:aun_reqstudio/domain/models/folder.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/import_export/import_export_screen_web.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_execution_provider.dart';
import 'package:aun_reqstudio/features/request_builder/request_builder_screen_material.dart';
import 'package:aun_reqstudio/data/local/hive_service.dart';
import 'package:aun_reqstudio/features/shell/web_workspace_tab_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

enum _WebWorkspaceSection {
  collections,
  history,
  environments,
  websocket,
  importExport,
}

enum _ExplorerMenuAction {
  open,
  newRequest,
  rename,
  duplicate,
  exportJson,
  copyJson,
  delete,
}

const _explorerBranchAnimationDuration = Duration(milliseconds: 150);
const _explorerBranchReverseDuration = Duration(milliseconds: 110);
const _explorerRowAnimationDuration = Duration(milliseconds: 120);
const double _explorerRowHeight = 32;
const Duration _explorerSearchDebounceDuration = Duration(milliseconds: 220);
const Duration _explorerRequestTooltipHoverWait = Duration(seconds: 2);

/// Web left explorer panel (VS Code–style sidebar bounds).
const double _webExplorerPanelMinWidth = 220;
const double _webExplorerPanelMaxAbsolute = 640;
const double _webExplorerPanelMaxViewportFraction = 0.42;
const double _webExplorerPanelDefaultWidth = 316;
const double _webExplorerPanelResizeHitWidth = 6;

/// Matches [ShellScreenMaterial] compact breakpoint: bottom nav / drawer shell.
const double _webShellCompactBreakpoint = 600;

const String _hiveKeyWebExplorerPaneWidth = 'web_explorer_pane_width';

class ShellScreenWeb extends ConsumerStatefulWidget {
  const ShellScreenWeb({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<ShellScreenWeb> createState() => _ShellScreenWebState();
}

class _ShellScreenWebState extends ConsumerState<ShellScreenWeb> {
  static const _uuid = Uuid();

  final WebWorkspaceTabController _tabController = WebWorkspaceTabController();
  final ScrollController _explorerScrollController = ScrollController();
  bool _isCollectionsActivating = false;

  /// Live width during resize; listeners rebuild only the explorer + splitter,
  /// not the full workspace (tabs stay smooth while dragging).
  final ValueNotifier<double> _explorerPaneWidthNotifier =
      ValueNotifier<double>(_webExplorerPanelDefaultWidth);

  final GlobalKey<ScaffoldState> _shellScaffoldKey = GlobalKey<ScaffoldState>();
  bool? _wasCompactLayout;
  double? _lastExplorerSyncViewport;

  void _persistExplorerPaneWidth(double width) {
    if (!Hive.isBoxOpen(HiveBoxes.webUiPrefs)) return;
    unawaited(
      Hive.box<String>(
        HiveBoxes.webUiPrefs,
      ).put(_hiveKeyWebExplorerPaneWidth, width.toString()),
    );
  }

  double _clampExplorerWidthToStoredBounds(double width) {
    return width.clamp(_webExplorerPanelMinWidth, _webExplorerPanelMaxAbsolute);
  }

  /// Import/Export is not a [StatefulNavigationShell] branch; when non-null,
  /// the right pane shows that UI while the shell branch is unchanged.
  _WebWorkspaceSection? _rightPanelSectionOverride;

  StatefulNavigationShell get _shell => widget.shell;

  _WebWorkspaceSection get _activeSection {
    if (_rightPanelSectionOverride == _WebWorkspaceSection.importExport) {
      return _WebWorkspaceSection.importExport;
    }
    return switch (_shell.currentIndex) {
      0 => _WebWorkspaceSection.collections,
      1 => _WebWorkspaceSection.history,
      2 => _WebWorkspaceSection.environments,
      _ => _WebWorkspaceSection.websocket,
    };
  }

  void _switchSection(_WebWorkspaceSection section) {
    if (section == _WebWorkspaceSection.importExport) {
      setState(
        () => _rightPanelSectionOverride = _WebWorkspaceSection.importExport,
      );
      _shellScaffoldKey.currentState?.closeDrawer();
      return;
    }
    setState(() => _rightPanelSectionOverride = null);

    final index = switch (section) {
      _WebWorkspaceSection.collections => 0,
      _WebWorkspaceSection.history => 1,
      _WebWorkspaceSection.environments => 2,
      _WebWorkspaceSection.websocket => 3,
      _WebWorkspaceSection.importExport => 0,
    };
    if (section == _WebWorkspaceSection.collections &&
        _activeSection != _WebWorkspaceSection.collections) {
      setState(() => _isCollectionsActivating = true);
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _isCollectionsActivating = false);
      });
    }
    _shell.goBranch(index, initialLocation: index == _shell.currentIndex);
    _shellScaffoldKey.currentState?.closeDrawer();
  }

  void _showSnack(String message) {
    WebToast.show(context, message: message, type: WebToastType.info);
  }

  Future<void> _createCollection() async {
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => const _CreateCollectionDialogWeb(),
    );
    if (result == null) return;
    await ref
        .read(collectionsProvider.notifier)
        .create(result.$1, description: result.$2);
  }

  void _openNewRequest(Collection collection, {String? folderUid}) {
    _tabController.openNewRequest(
      collectionUid: collection.uid,
      folderUid: folderUid,
    );
    _shellScaffoldKey.currentState?.closeDrawer();
  }

  void _openRequest(Collection collection, HttpRequest request) {
    _tabController.openSavedRequest(
      collectionUid: collection.uid,
      requestUid: request.uid,
      title: request.name,
    );
    _shellScaffoldKey.currentState?.closeDrawer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vw = MediaQuery.sizeOf(context).width;
    if (!vw.isFinite || vw <= 0) return;
    if (vw == _lastExplorerSyncViewport) return;
    _lastExplorerSyncViewport = vw;
    final b = _explorerPaneBoundsForViewport(vw);
    final clamped = _explorerPaneWidthNotifier.value
        .clamp(b.minW, b.maxW)
        .toDouble();
    if (clamped != _explorerPaneWidthNotifier.value) {
      _explorerPaneWidthNotifier.value = clamped;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_handleTabControllerChanged);
    if (Hive.isBoxOpen(HiveBoxes.webUiPrefs)) {
      final raw = Hive.box<String>(
        HiveBoxes.webUiPrefs,
      ).get(_hiveKeyWebExplorerPaneWidth);
      final parsed = double.tryParse(raw ?? '');
      if (parsed != null && parsed.isFinite) {
        _explorerPaneWidthNotifier.value = _clampExplorerWidthToStoredBounds(
          parsed,
        );
      }
    }
  }

  @override
  void dispose() {
    _explorerPaneWidthNotifier.dispose();
    _explorerScrollController.dispose();
    _tabController
      ..removeListener(_handleTabControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabControllerChanged() {
    if (mounted) setState(() {});
  }

  /// Min/max width for the resizable explorer so [num.clamp] never receives
  /// `low > high` (web throws) and the explorer + splitter fit in the shell.
  ({double minW, double maxW}) _explorerPaneBoundsForViewport(
    double viewportWidth,
  ) {
    if (!viewportWidth.isFinite ||
        viewportWidth <= _webExplorerPanelResizeHitWidth) {
      return (minW: 0, maxW: 0);
    }
    final maxPhysical = viewportWidth - _webExplorerPanelResizeHitWidth;
    final maxFromFraction =
        viewportWidth * _webExplorerPanelMaxViewportFraction;
    var maxW = min(
      _webExplorerPanelMaxAbsolute,
      min(maxFromFraction, maxPhysical),
    );
    if (maxW < 0) maxW = 0;
    var minW = _webExplorerPanelMinWidth;
    if (minW > maxW) {
      minW = maxW;
    }
    return (minW: minW, maxW: maxW);
  }

  String _compactShellTitle(_WebWorkspaceSection section) {
    return switch (section) {
      _WebWorkspaceSection.collections => 'Collections',
      _WebWorkspaceSection.history => 'History',
      _WebWorkspaceSection.environments => 'Environments',
      _WebWorkspaceSection.websocket => 'WebSocket',
      _WebWorkspaceSection.importExport => 'Import / Export',
    };
  }

  Future<void> _closeTab(String tabId) async {
    if (!_tabController.requestCloseTab(tabId)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => const _CloseRequestTabDialogWeb(),
      );
      if (confirmed != true) return;
    }
    _tabController.closeTab(tabId);
  }

  Future<void> _showCollectionMenu(
    TapDownDetails details,
    Collection collection,
  ) async {
    final action = await _showExplorerMenu(details, [
      _menuItem(_ExplorerMenuAction.newRequest, Icons.add, 'New Request'),
      _menuItem(
        _ExplorerMenuAction.rename,
        Icons.drive_file_rename_outline,
        'Rename',
      ),
      _menuItem(
        _ExplorerMenuAction.duplicate,
        Icons.copy_all_outlined,
        'Duplicate',
      ),
      const PopupMenuDivider(height: 8),
      _menuItem(
        _ExplorerMenuAction.exportJson,
        Icons.download_outlined,
        'Export JSON',
      ),
      _menuItem(
        _ExplorerMenuAction.copyJson,
        Icons.content_copy_outlined,
        'Copy JSON',
      ),
      const PopupMenuDivider(height: 8),
      _menuItem(_ExplorerMenuAction.delete, Icons.delete_outline, 'Delete'),
    ]);
    if (action == null) return;

    switch (action) {
      case _ExplorerMenuAction.newRequest:
        _openNewRequest(collection);
      case _ExplorerMenuAction.rename:
        await _renameCollection(collection);
      case _ExplorerMenuAction.duplicate:
        await ref.read(collectionsProvider.notifier).duplicate(collection.uid);
        _showSnack('Collection duplicated.');
      case _ExplorerMenuAction.exportJson:
        _downloadCollectionJson(collection);
      case _ExplorerMenuAction.copyJson:
        await _copyCollectionJson(collection);
      case _ExplorerMenuAction.delete:
        await _deleteCollection(collection);
      case _ExplorerMenuAction.open:
        break;
    }
  }

  Future<void> _showFolderMenu(
    TapDownDetails details,
    Collection collection,
    Folder folder,
  ) async {
    final action = await _showExplorerMenu(details, [
      _menuItem(_ExplorerMenuAction.newRequest, Icons.add, 'New Request Here'),
      _menuItem(
        _ExplorerMenuAction.rename,
        Icons.drive_file_rename_outline,
        'Rename',
      ),
      const PopupMenuDivider(height: 8),
      _menuItem(
        _ExplorerMenuAction.exportJson,
        Icons.download_outlined,
        'Export Folder JSON',
      ),
      _menuItem(
        _ExplorerMenuAction.copyJson,
        Icons.content_copy_outlined,
        'Copy Folder JSON',
      ),
      const PopupMenuDivider(height: 8),
      _menuItem(
        _ExplorerMenuAction.delete,
        Icons.delete_outline,
        'Delete Folder',
      ),
    ]);
    if (action == null) return;

    switch (action) {
      case _ExplorerMenuAction.newRequest:
        _openNewRequest(collection, folderUid: folder.uid);
      case _ExplorerMenuAction.rename:
        await _renameFolder(collection, folder);
      case _ExplorerMenuAction.exportJson:
        _downloadFolderJson(folder);
      case _ExplorerMenuAction.copyJson:
        await _copyFolderJson(folder);
      case _ExplorerMenuAction.delete:
        await _deleteFolder(collection, folder);
      case _ExplorerMenuAction.open:
      case _ExplorerMenuAction.duplicate:
        break;
    }
  }

  Future<void> _showRequestMenu(
    TapDownDetails details,
    Collection collection,
    HttpRequest request,
  ) async {
    final action = await _showExplorerMenu(details, [
      _menuItem(_ExplorerMenuAction.open, Icons.open_in_new_outlined, 'Open'),
      _menuItem(
        _ExplorerMenuAction.rename,
        Icons.drive_file_rename_outline,
        'Rename',
      ),
      _menuItem(
        _ExplorerMenuAction.duplicate,
        Icons.copy_all_outlined,
        'Duplicate',
      ),
      const PopupMenuDivider(height: 8),
      _menuItem(
        _ExplorerMenuAction.exportJson,
        Icons.download_outlined,
        'Export Request JSON',
      ),
      _menuItem(
        _ExplorerMenuAction.copyJson,
        Icons.content_copy_outlined,
        'Copy Request JSON',
      ),
      const PopupMenuDivider(height: 8),
      _menuItem(
        _ExplorerMenuAction.delete,
        Icons.delete_outline,
        'Delete Request',
      ),
    ]);
    if (action == null) return;

    switch (action) {
      case _ExplorerMenuAction.open:
        _openRequest(collection, request);
      case _ExplorerMenuAction.rename:
        await _renameRequest(collection, request);
      case _ExplorerMenuAction.duplicate:
        await _duplicateRequest(collection, request);
      case _ExplorerMenuAction.exportJson:
        _downloadRequestJson(request);
      case _ExplorerMenuAction.copyJson:
        await _copyRequestJson(request);
      case _ExplorerMenuAction.delete:
        await _deleteRequest(collection, request);
      case _ExplorerMenuAction.newRequest:
        break;
    }
  }

  Future<_ExplorerMenuAction?> _showExplorerMenu(
    TapDownDetails details,
    List<PopupMenuEntry<_ExplorerMenuAction>> items,
  ) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      details.globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    );
    return showMenu<_ExplorerMenuAction>(
      context: context,
      position: position,
      items: items,
    );
  }

  PopupMenuItem<_ExplorerMenuAction> _menuItem(
    _ExplorerMenuAction value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<_ExplorerMenuAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _renameCollection(Collection collection) async {
    final name = await _promptForName(
      title: 'Rename Collection',
      label: 'Collection name',
      initialValue: collection.name,
      actionLabel: 'Rename',
    );
    if (name == null || name == collection.name) return;
    await ref
        .read(collectionsProvider.notifier)
        .update(collection.copyWith(name: name));
    _showSnack('Collection renamed.');
  }

  Future<void> _deleteCollection(Collection collection) async {
    final confirmed = await _confirmDestructive(
      title: 'Delete Collection?',
      message:
          'Delete "${collection.name}" and all folders and requests inside it?',
      actionLabel: 'Delete',
    );
    if (!confirmed) return;
    await ref.read(collectionsProvider.notifier).delete(collection.uid);
    _showSnack('Collection deleted.');
  }

  Future<void> _renameFolder(Collection collection, Folder folder) async {
    final name = await _promptForName(
      title: 'Rename Folder',
      label: 'Folder name',
      initialValue: folder.name,
      actionLabel: 'Rename',
    );
    if (name == null || name == folder.name) return;
    final updated = collection.copyWith(
      folders: _updateFolderInTree(
        collection.folders,
        folder.uid,
        (f) => f.copyWith(name: name),
      ),
    );
    await ref.read(collectionsProvider.notifier).update(updated);
    _showSnack('Folder renamed.');
  }

  Future<void> _deleteFolder(Collection collection, Folder folder) async {
    final totalRequests = _countRequests(folder);
    final confirmed = await _confirmDestructive(
      title: 'Delete Folder?',
      message: totalRequests > 0
          ? 'Delete "${folder.name}" and its $totalRequests request(s)?'
          : 'Delete "${folder.name}"?',
      actionLabel: 'Delete',
    );
    if (!confirmed) return;
    final updated = collection.copyWith(
      folders: _removeFolderFromTree(collection.folders, folder.uid),
    );
    await ref.read(collectionsProvider.notifier).update(updated);
    _showSnack('Folder deleted.');
  }

  Future<void> _renameRequest(
    Collection collection,
    HttpRequest request,
  ) async {
    final name = await _promptForName(
      title: 'Rename Request',
      label: 'Request name',
      initialValue: request.name,
      actionLabel: 'Rename',
    );
    if (name == null || name == request.name) return;
    await _replaceRequest(collection, request.copyWith(name: name));
    _showSnack('Request renamed.');
  }

  Future<void> _duplicateRequest(
    Collection collection,
    HttpRequest request,
  ) async {
    final now = DateTime.now();
    final copy = request.copyWith(
      uid: _uuid.v4(),
      name: '${request.name} (copy)',
      createdAt: now,
      updatedAt: now,
    );
    final folderUid = request.folderUid;
    late final Collection updated;
    if (folderUid == null) {
      updated = collection.copyWith(requests: [...collection.requests, copy]);
    } else {
      updated = collection.copyWith(
        folders: _updateFolderInTree(
          collection.folders,
          folderUid,
          (f) => f.copyWith(requests: [...f.requests, copy]),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updated);
    _showSnack('Request duplicated.');
  }

  Future<void> _deleteRequest(
    Collection collection,
    HttpRequest request,
  ) async {
    final confirmed = await _confirmDestructive(
      title: 'Delete Request?',
      message: 'Delete "${request.name}"?',
      actionLabel: 'Delete',
    );
    if (!confirmed) return;
    final folderUid = request.folderUid;
    late final Collection updated;
    if (folderUid == null) {
      updated = collection.copyWith(
        requests: collection.requests
            .where((candidate) => candidate.uid != request.uid)
            .toList(),
      );
    } else {
      updated = collection.copyWith(
        folders: _updateFolderInTree(
          collection.folders,
          folderUid,
          (f) => f.copyWith(
            requests: f.requests
                .where((candidate) => candidate.uid != request.uid)
                .toList(),
          ),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updated);
    _showSnack('Request deleted.');
  }

  Future<void> _replaceRequest(
    Collection collection,
    HttpRequest request,
  ) async {
    final folderUid = request.folderUid;
    late final Collection updated;
    if (folderUid == null) {
      updated = collection.copyWith(
        requests: collection.requests
            .map(
              (candidate) => candidate.uid == request.uid ? request : candidate,
            )
            .toList(),
      );
    } else {
      updated = collection.copyWith(
        folders: _updateFolderInTree(
          collection.folders,
          folderUid,
          (f) => f.copyWith(
            requests: f.requests
                .map(
                  (candidate) =>
                      candidate.uid == request.uid ? request : candidate,
                )
                .toList(),
          ),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updated);
  }

  void _downloadCollectionJson(Collection collection) {
    downloadJsonFile(
      fileName: '${safeJsonFileName(collection.name)}.json',
      content: CollectionV21Exporter.export(collection),
    );
    _showSnack('Collection JSON downloaded.');
  }

  Future<void> _copyCollectionJson(Collection collection) async {
    await copyJsonToClipboard(CollectionV21Exporter.export(collection));
    _showSnack('Collection JSON copied.');
  }

  void _downloadFolderJson(Folder folder) {
    downloadJsonFile(
      fileName: '${safeJsonFileName(folder.name)}.json',
      content: CollectionV21Exporter.exportFragment(
        title: folder.name,
        entries: [CollectionV21FragmentFolder(folder)],
      ),
    );
    _showSnack('Folder JSON downloaded.');
  }

  Future<void> _copyFolderJson(Folder folder) async {
    await copyJsonToClipboard(
      CollectionV21Exporter.exportFragment(
        title: folder.name,
        entries: [CollectionV21FragmentFolder(folder)],
      ),
    );
    _showSnack('Folder JSON copied.');
  }

  void _downloadRequestJson(HttpRequest request) {
    downloadJsonFile(
      fileName: '${safeJsonFileName(request.name)}.json',
      content: CollectionV21Exporter.exportFragment(
        title: request.name,
        entries: [CollectionV21FragmentRequest(request)],
      ),
    );
    _showSnack('Request JSON downloaded.');
  }

  Future<void> _copyRequestJson(HttpRequest request) async {
    await copyJsonToClipboard(
      CollectionV21Exporter.exportFragment(
        title: request.name,
        entries: [CollectionV21FragmentRequest(request)],
      ),
    );
    _showSnack('Request JSON copied.');
  }

  Future<String?> _promptForName({
    required String title,
    required String label,
    required String initialValue,
    required String actionLabel,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
            onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<bool> _confirmDestructive({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  int _countRequests(Folder folder) {
    var count = folder.requests.length;
    for (final subFolder in folder.subFolders) {
      count += _countRequests(subFolder);
    }
    return count;
  }

  List<Folder> _removeFolderFromTree(List<Folder> folders, String uid) {
    return folders
        .where((folder) => folder.uid != uid)
        .map(
          (folder) => folder.copyWith(
            subFolders: _removeFolderFromTree(folder.subFolders, uid),
          ),
        )
        .toList();
  }

  List<Folder> _updateFolderInTree(
    List<Folder> folders,
    String uid,
    Folder Function(Folder folder) updater,
  ) {
    return folders.map((folder) {
      if (folder.uid == uid) return updater(folder);
      if (folder.subFolders.isEmpty) return folder;
      return folder.copyWith(
        subFolders: _updateFolderInTree(folder.subFolders, uid, updater),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final activeSection = _activeSection;

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isCompact = viewportWidth < _webShellCompactBreakpoint;
    if (_wasCompactLayout == true && !isCompact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shellScaffoldKey.currentState?.closeDrawer();
      });
    }
    _wasCompactLayout = isCompact;

    final explorerPane = _WebExplorerPane(
      activeSection: activeSection,
      collections: collections,
      explorerScrollController: _explorerScrollController,
      isCollectionsActivating: _isCollectionsActivating,
      onSectionSelected: _switchSection,
      onCreateCollection: _createCollection,
      onOpenNewRequest: _openNewRequest,
      onOpenRequest: _openRequest,
      onCollectionContextMenu: _showCollectionMenu,
      onFolderContextMenu: _showFolderMenu,
      onRequestContextMenu: _showRequestMenu,
    );

    final Widget workspaceBody =
        activeSection == _WebWorkspaceSection.importExport
        ? ImportExportScreenWeb(
            embedded: true,
            onEmbeddedNavigateAway: () {
              if (!mounted) return;
              setState(() => _rightPanelSectionOverride = null);
            },
          )
        : activeSection == _WebWorkspaceSection.collections
        ? _RequestWorkspace(
            tabs: _tabController.tabs,
            activeTabId: _tabController.activeTabId,
            onSelectTab: _tabController.focusTab,
            onCloseTab: _closeTab,
            onReportTabStatus: _tabController.reportTabStatus,
          )
        : _shell;

    final Widget body = isCompact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WebCompactShellBar(
                title: _compactShellTitle(activeSection),
                onOpenExplorer: () =>
                    _shellScaffoldKey.currentState?.openDrawer(),
              ),
              Expanded(child: workspaceBody),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: _explorerPaneWidthNotifier,
                    builder: (context, rawExplorerWidth, __) {
                      final vw = MediaQuery.sizeOf(context).width;
                      final boundsLocal = _explorerPaneBoundsForViewport(vw);
                      final explorerWidth = rawExplorerWidth
                          .clamp(boundsLocal.minW, boundsLocal.maxW)
                          .toDouble();
                      final dragBounds = boundsLocal;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RepaintBoundary(
                            child: SizedBox(
                              width: explorerWidth,
                              child: ContextMenuBlocker(child: explorerPane),
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onDoubleTap: () {
                                final b = _explorerPaneBoundsForViewport(
                                  MediaQuery.sizeOf(context).width,
                                );
                                final next = _webExplorerPanelDefaultWidth
                                    .clamp(b.minW, b.maxW)
                                    .toDouble();
                                _explorerPaneWidthNotifier.value = next;
                                _persistExplorerPaneWidth(next);
                              },
                              onHorizontalDragUpdate: (details) {
                                final next =
                                    (_explorerPaneWidthNotifier.value +
                                            details.delta.dx)
                                        .clamp(dragBounds.minW, dragBounds.maxW)
                                        .toDouble();
                                if (next != _explorerPaneWidthNotifier.value) {
                                  _explorerPaneWidthNotifier.value = next;
                                }
                              },
                              onHorizontalDragEnd: (_) {
                                _persistExplorerPaneWidth(
                                  _explorerPaneWidthNotifier.value,
                                );
                              },
                              child: SizedBox(
                                width: _webExplorerPanelResizeHitWidth,
                                child: Center(
                                  child: Container(
                                    width: 1,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              Expanded(child: workspaceBody),
            ],
          );

    return Scaffold(
      key: _shellScaffoldKey,
      drawer: isCompact
          ? Drawer(
              width: viewportWidth,
              child: SafeArea(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: ContextMenuBlocker(child: explorerPane),
                ),
              ),
            )
          : null,
      body: body,
    );
  }
}

class _WebCompactShellBar extends StatelessWidget {
  const _WebCompactShellBar({
    required this.title,
    required this.onOpenExplorer,
  });

  final String title;
  final VoidCallback onOpenExplorer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Open workspace menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: onOpenExplorer,
              ),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebExplorerPane extends StatelessWidget {
  const _WebExplorerPane({
    required this.activeSection,
    required this.collections,
    required this.explorerScrollController,
    required this.isCollectionsActivating,
    required this.onSectionSelected,
    required this.onCreateCollection,
    required this.onOpenNewRequest,
    required this.onOpenRequest,
    required this.onCollectionContextMenu,
    required this.onFolderContextMenu,
    required this.onRequestContextMenu,
  });

  final _WebWorkspaceSection activeSection;
  final List<Collection> collections;
  final ScrollController explorerScrollController;
  final bool isCollectionsActivating;
  final ValueChanged<_WebWorkspaceSection> onSectionSelected;
  final VoidCallback onCreateCollection;
  final void Function(Collection collection, {String? folderUid})
  onOpenNewRequest;
  final void Function(Collection collection, HttpRequest request) onOpenRequest;
  final void Function(TapDownDetails details, Collection collection)
  onCollectionContextMenu;
  final void Function(
    TapDownDetails details,
    Collection collection,
    Folder folder,
  )
  onFolderContextMenu;
  final void Function(
    TapDownDetails details,
    Collection collection,
    HttpRequest request,
  )
  onRequestContextMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (_) {},
      child: ColoredBox(
        color: scheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                children: [
                  _SectionTabWeb(
                    icon: Icons.folder_outlined,
                    selectedIcon: Icons.folder,
                    label: 'Collections',
                    isSelected:
                        activeSection == _WebWorkspaceSection.collections,
                    onTap: () =>
                        onSectionSelected(_WebWorkspaceSection.collections),
                  ),
                  _SectionTabWeb(
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                    label: 'History',
                    isSelected: activeSection == _WebWorkspaceSection.history,
                    onTap: () =>
                        onSectionSelected(_WebWorkspaceSection.history),
                  ),
                  _SectionTabWeb(
                    icon: Icons.tune_outlined,
                    selectedIcon: Icons.tune,
                    label: 'Envs',
                    isSelected:
                        activeSection == _WebWorkspaceSection.environments,
                    onTap: () =>
                        onSectionSelected(_WebWorkspaceSection.environments),
                  ),
                  _SectionTabWeb(
                    icon: Icons.compare_arrows_outlined,
                    selectedIcon: Icons.compare_arrows,
                    label: 'WebSocket',
                    isSelected: activeSection == _WebWorkspaceSection.websocket,
                    onTap: () =>
                        onSectionSelected(_WebWorkspaceSection.websocket),
                  ),
                  _SectionTabWeb(
                    icon: Icons.import_export_outlined,
                    selectedIcon: Icons.import_export,
                    label: 'Import / Export',
                    isSelected:
                        activeSection == _WebWorkspaceSection.importExport,
                    onTap: () =>
                        onSectionSelected(_WebWorkspaceSection.importExport),
                  ),
                ],
              ),
            ),
            const Divider(height: 18),
            if (activeSection == _WebWorkspaceSection.collections)
              Expanded(
                child: Stack(
                  children: [
                    _CollectionsExplorerWeb(
                      collections: collections,
                      scrollController: explorerScrollController,
                      onCreateCollection: onCreateCollection,
                      onOpenNewRequest: onOpenNewRequest,
                      onOpenRequest: onOpenRequest,
                      onCollectionContextMenu: onCollectionContextMenu,
                      onFolderContextMenu: onFolderContextMenu,
                      onRequestContextMenu: onRequestContextMenu,
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: isCollectionsActivating ? 1 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: const LinearProgressIndicator(minHeight: 2),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'Open ${_sectionLabel(activeSection)} on the right',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _sectionLabel(_WebWorkspaceSection section) {
    return switch (section) {
      _WebWorkspaceSection.collections => 'Collections',
      _WebWorkspaceSection.history => 'History',
      _WebWorkspaceSection.environments => 'Envs',
      _WebWorkspaceSection.websocket => 'WebSocket',
      _WebWorkspaceSection.importExport => 'Import / Export',
    };
  }
}

class _SectionTabWeb extends StatelessWidget {
  const _SectionTabWeb({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.68);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(isSelected ? selectedIcon : icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionsExplorerWeb extends StatefulWidget {
  const _CollectionsExplorerWeb({
    required this.collections,
    required this.scrollController,
    required this.onCreateCollection,
    required this.onOpenNewRequest,
    required this.onOpenRequest,
    required this.onCollectionContextMenu,
    required this.onFolderContextMenu,
    required this.onRequestContextMenu,
  });

  final List<Collection> collections;
  final ScrollController scrollController;
  final VoidCallback onCreateCollection;
  final void Function(Collection collection, {String? folderUid})
  onOpenNewRequest;
  final void Function(Collection collection, HttpRequest request) onOpenRequest;
  final void Function(TapDownDetails details, Collection collection)
  onCollectionContextMenu;
  final void Function(
    TapDownDetails details,
    Collection collection,
    Folder folder,
  )
  onFolderContextMenu;
  final void Function(
    TapDownDetails details,
    Collection collection,
    HttpRequest request,
  )
  onRequestContextMenu;

  @override
  State<_CollectionsExplorerWeb> createState() =>
      _CollectionsExplorerWebState();
}

class _CollectionsExplorerWebState extends State<_CollectionsExplorerWeb> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'Web collections explorer',
  );
  final Set<String> _expandedCollectionUids = <String>{};
  final Set<String> _expandedFolderUids = <String>{};
  String? _selectedCollectionUid;
  String? _selectedExplorerItemId;

  late _ExplorerLiteIndex _index;
  late _ExplorerEntityResolver _resolver;
  late List<_ExplorerLiteNode> _rows;
  final TextEditingController _explorerSearchController =
      TextEditingController();
  final FocusNode _explorerSearchFocusNode = FocusNode(
    debugLabel: 'Web collections explorer search',
  );

  /// Monotonic id so only the latest scheduled scroll clamp runs (rapid
  /// expand/collapse or collection updates must not stack competing timers).
  int _explorerScrollClampScheduleId = 0;
  Timer? _explorerScrollClampTimer;
  Timer? _explorerSearchDebounceTimer;
  bool _explorerSearchPending = false;

  @override
  void initState() {
    super.initState();
    _index = _ExplorerLiteIndex.fromCollections(widget.collections);
    _resolver = _ExplorerEntityResolver.from(widget.collections);
    _rows = _visibleRows();
    _explorerSearchController.addListener(_onExplorerSearchChanged);
    _focusExplorerAfterFrame();
  }

  @override
  void didUpdateWidget(covariant _CollectionsExplorerWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final collectionsChanged = !identical(
      widget.collections,
      oldWidget.collections,
    );
    if (collectionsChanged) {
      _explorerSearchDebounceTimer?.cancel();
      _explorerSearchPending = false;
      _index = _ExplorerLiteIndex.fromCollections(widget.collections);
      _resolver = _ExplorerEntityResolver.from(widget.collections);
      _pruneExplorerState();
    }
    setState(() => _rows = _visibleRows());
    if (collectionsChanged) {
      _scheduleExplorerScrollExtentClamp();
    }
  }

  @override
  void dispose() {
    _explorerScrollClampTimer?.cancel();
    _explorerSearchDebounceTimer?.cancel();
    _explorerSearchController.removeListener(_onExplorerSearchChanged);
    _explorerSearchController.dispose();
    _explorerSearchFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _explorerSearchNorm =>
      _explorerSearchController.text.trim().toLowerCase();

  List<_ExplorerLiteNode> _visibleRows() {
    final q = _explorerSearchNorm;
    if (q.isEmpty) {
      return _index.visibleRows(
        expandedCollectionUids: _expandedCollectionUids,
        expandedFolderUids: _expandedFolderUids,
      );
    }
    return _index.visibleRowsWithSearch(
      queryNorm: q,
      expandedCollectionUids: _expandedCollectionUids,
      expandedFolderUids: _expandedFolderUids,
    );
  }

  void _onExplorerSearchChanged() {
    _explorerSearchDebounceTimer?.cancel();
    final searchOn = _explorerSearchNorm.isNotEmpty;

    if (!searchOn) {
      setState(() {
        _explorerSearchPending = false;
        _applyExplorerSearchRows();
      });
      return;
    }

    setState(() => _explorerSearchPending = true);
    _explorerSearchDebounceTimer = Timer(_explorerSearchDebounceDuration, () {
      if (!mounted) return;
      setState(() {
        _explorerSearchPending = false;
        _applyExplorerSearchRows();
      });
    });
  }

  /// Updates [_rows] from the current controller text. Call inside [setState].
  void _applyExplorerSearchRows() {
    _rows = _visibleRows();
  }

  Widget _buildExplorerSearchSuffix(ColorScheme scheme) {
    const slot = 36.0;
    const loaderSlot = 22.0;
    final hasText = _explorerSearchController.text.trim().isNotEmpty;
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: loaderSlot,
            child: Center(
              child: _explorerSearchPending && _explorerSearchNorm.isNotEmpty
                  ? SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary.withValues(alpha: 0.5),
                        backgroundColor: scheme.outline.withValues(alpha: 0.12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            width: slot,
            height: slot,
            child: hasText
                ? IconButton(
                    tooltip: 'Clear search',
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.56),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: slot,
                      minHeight: slot,
                    ),
                    onPressed: () => _explorerSearchController.clear(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _focusExplorerAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusExplorer();
    });
  }

  void _focusExplorer() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _leaveExplorerSearchField() {
    _explorerSearchFocusNode.unfocus();
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_explorerSearchFocusNode.hasFocus) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _leaveExplorerSearchField();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isRepeat = event is KeyRepeatEvent;
    if (key == LogicalKeyboardKey.keyN && _hasCommandOrControlModifier()) {
      _openNewRequestNearSelection();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (!isRepeat) _setSelectedBranchExpanded(true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (!isRepeat) {
        final row = _selectedRow();
        if (row != null &&
            row.kind != _ExplorerRowKind.request &&
            row.hasChildren &&
            row.isExpanded &&
            (row.kind == _ExplorerRowKind.folder ||
                row.kind == _ExplorerRowKind.collection)) {
          _setSelectedBranchExpanded(false);
        } else if (!_navigateSelectionToParentRow()) {
          _setSelectedBranchExpanded(false);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      _activateSelection();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _hasCommandOrControlModifier() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    return pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight) ||
        pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

  void _moveSelection(int direction) {
    if (_rows.isEmpty) return;
    final currentIndex = _selectedRowIndex();
    final nextIndex = currentIndex == -1
        ? (direction < 0 ? _rows.length - 1 : 0)
        : (currentIndex + direction).clamp(0, _rows.length - 1).toInt();
    final row = _rows[nextIndex];
    _selectExplorerItem(row.id, collectionUid: row.collectionUid);
    _ensureRowVisible(nextIndex);
  }

  int _selectedRowIndex() {
    final selectedId = _selectedExplorerItemId;
    if (selectedId == null) return -1;
    return _rows.indexWhere((row) => row.id == selectedId);
  }

  _ExplorerLiteNode? _selectedRow() {
    final selectedIndex = _selectedRowIndex();
    if (selectedIndex == -1) return null;
    return _rows[selectedIndex];
  }

  /// Move selection to the parent row when it exists (request, folder, or a
  /// nested collection if ever modeled). Root collections have no parent.
  bool _navigateSelectionToParentRow() {
    final row = _selectedRow();
    if (row == null) return false;

    final parentId = _index.parentRowId(row.id);
    if (parentId == null || !_rows.any((r) => r.id == parentId)) return false;

    _selectExplorerItem(parentId, collectionUid: row.collectionUid);
    final idx = _selectedRowIndex();
    if (idx != -1) _ensureRowVisible(idx);
    return true;
  }

  void _ensureRowVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollController.hasClients) return;

      final position = widget.scrollController.position;
      final top = index * _explorerRowHeight;
      final bottom = top + _explorerRowHeight;
      final viewportTop = position.pixels;
      final viewportBottom = viewportTop + position.viewportDimension;
      var target = viewportTop;

      if (top < viewportTop) {
        target = top;
      } else if (bottom > viewportBottom) {
        target = bottom - position.viewportDimension;
      } else {
        return;
      }

      widget.scrollController.animateTo(
        target.clamp(0.0, position.maxScrollExtent).toDouble(),
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _setSelectedBranchExpanded(bool expanded) {
    final row = _selectedRow();
    if (row == null || !row.hasChildren) return;
    if (row.kind != _ExplorerRowKind.collection &&
        row.kind != _ExplorerRowKind.folder) {
      return;
    }
    if (row.isExpanded == expanded) return;

    _commitExplorerChange(() {
      _selectedExplorerItemId = row.id;
      _selectedCollectionUid = row.collectionUid;
      switch (row.kind) {
        case _ExplorerRowKind.collection:
          if (expanded) {
            _expandedCollectionUids.add(row.collectionUid);
          } else {
            _expandedCollectionUids.remove(row.collectionUid);
          }
        case _ExplorerRowKind.folder:
          if (expanded) {
            _expandedFolderUids.add(row.folderUid!);
          } else {
            _expandedFolderUids.remove(row.folderUid!);
          }
        case _ExplorerRowKind.request:
          break;
      }
    });
    // Collapsing shrinks scroll extent and runs many removeItem animations;
    // avoid competing scroll.animateTo here (major flicker source).
    if (expanded) {
      final nextIndex = _selectedRowIndex();
      if (nextIndex != -1) _ensureRowVisible(nextIndex);
    }
  }

  void _activateSelection() {
    final row = _selectedRow();
    if (row == null) return;
    if (row.kind == _ExplorerRowKind.request) {
      final c = _resolver.collection(row.collectionUid);
      final r = _resolver.request(row.collectionUid, row.requestUid!);
      if (c != null && r != null) _openRequest(c, r);
      return;
    }
    if (row.hasChildren) {
      _setSelectedBranchExpanded(!row.isExpanded);
    }
  }

  void _openNewRequestNearSelection() {
    final row = _selectedRow();
    if (row == null) return;

    switch (row.kind) {
      case _ExplorerRowKind.collection:
        final c = _resolver.collection(row.collectionUid);
        if (c != null) _openNewRequest(c);
      case _ExplorerRowKind.folder:
        final c = _resolver.collection(row.collectionUid);
        if (c != null) {
          _openNewRequest(c, folderUid: row.folderUid);
        }
      case _ExplorerRowKind.request:
        final c = _resolver.collection(row.collectionUid);
        if (c != null) {
          _openNewRequest(c, folderUid: row.containingFolderUid);
        }
    }
  }

  void _pruneExplorerState() {
    _expandedCollectionUids.removeWhere(
      (uid) => !_index.collectionUids.contains(uid),
    );
    _expandedFolderUids.removeWhere((uid) => !_index.folderUids.contains(uid));
    if (_selectedCollectionUid != null &&
        !_index.collectionUids.contains(_selectedCollectionUid)) {
      _selectedCollectionUid = null;
    }
    if (_selectedExplorerItemId != null &&
        !_index.rowIds.contains(_selectedExplorerItemId)) {
      _selectedExplorerItemId = null;
    }
  }

  void _commitExplorerChange(VoidCallback change) {
    _focusExplorer();
    change();
    if (!mounted) return;
    setState(() => _rows = _visibleRows());
    _scheduleExplorerScrollExtentClamp();
  }

  /// After branch open/close, [ScrollPosition] can sit past the new
  /// [maxScrollExtent] while list height changes — browsers clamp that jump
  /// visibly. Coalesced, cancellable corrections keep this stable.
  void _scheduleExplorerScrollExtentClamp() {
    final scheduleId = ++_explorerScrollClampScheduleId;
    _explorerScrollClampTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || scheduleId != _explorerScrollClampScheduleId) return;
      _explorerScrollClampTimer?.cancel();
      _explorerScrollClampTimer = Timer(_explorerBranchReverseDuration, () {
        if (!mounted || scheduleId != _explorerScrollClampScheduleId) return;
        _applyExplorerScrollClampIfNeeded();
        // [maxScrollExtent] can settle a frame later after list animations.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || scheduleId != _explorerScrollClampScheduleId) return;
          _applyExplorerScrollClampIfNeeded();
        });
      });
    });
  }

  /// Returns true if scroll offset was corrected.
  bool _applyExplorerScrollClampIfNeeded() {
    if (!widget.scrollController.hasClients) return false;
    final position = widget.scrollController.position;
    final maxExtent = position.maxScrollExtent;
    if (position.pixels <= maxExtent) return false;
    position.jumpTo(maxExtent);
    return true;
  }

  void _selectExplorerItem(String itemId, {String? collectionUid}) {
    _focusExplorer();
    setState(() {
      _selectedExplorerItemId = itemId;
      if (collectionUid != null) _selectedCollectionUid = collectionUid;
    });
  }

  void _selectCollectionUid(String collectionUid) {
    final c = _resolver.collection(collectionUid);
    if (c == null) return;
    _commitExplorerChange(() {
      _selectedCollectionUid = c.uid;
      _selectedExplorerItemId = 'collection:${c.uid}';
      _expandedCollectionUids.add(c.uid);
    });
  }

  void _toggleCollectionUid(String collectionUid) {
    final c = _resolver.collection(collectionUid);
    if (c == null) return;
    _commitExplorerChange(() {
      _selectedCollectionUid = c.uid;
      _selectedExplorerItemId = 'collection:${c.uid}';
      if (!_expandedCollectionUids.remove(collectionUid)) {
        _expandedCollectionUids.add(collectionUid);
      }
    });
  }

  void _toggleFolderUid(String collectionUid, String folderUid) {
    _commitExplorerChange(() {
      _selectedCollectionUid = collectionUid;
      _selectedExplorerItemId = 'folder:$folderUid';
      if (!_expandedFolderUids.remove(folderUid)) {
        _expandedFolderUids.add(folderUid);
      }
    });
  }

  void _collapseAllCollections() {
    _commitExplorerChange(() {
      _expandedCollectionUids.clear();
      _expandedFolderUids.clear();
    });
  }

  void _expandAllCollections() {
    _commitExplorerChange(() {
      _expandedCollectionUids
        ..clear()
        ..addAll(_index.collectionUids);
      _expandedFolderUids
        ..clear()
        ..addAll(_index.folderUids);
    });
  }

  void _openNewRequest(Collection collection, {String? folderUid}) {
    _commitExplorerChange(() {
      _selectedCollectionUid = collection.uid;
      _selectedExplorerItemId = folderUid == null
          ? 'collection:${collection.uid}'
          : 'folder:$folderUid';
      _expandedCollectionUids.add(collection.uid);
      if (folderUid != null) _expandedFolderUids.add(folderUid);
    });
    widget.onOpenNewRequest(collection, folderUid: folderUid);
  }

  void _openRequest(Collection collection, HttpRequest request) {
    // Selection-only: avoid recomputing the full explorer row model on open
    // (keyboard / tap / double-tap should stay instant for large trees).
    _selectExplorerItem(
      'request:${request.uid}',
      collectionUid: collection.uid,
    );
    widget.onOpenRequest(collection, request);
  }

  void _showCollectionMenuUid(TapDownDetails details, String collectionUid) {
    final c = _resolver.collection(collectionUid);
    if (c == null) return;
    _selectExplorerItem('collection:${c.uid}', collectionUid: c.uid);
    widget.onCollectionContextMenu(details, c);
  }

  void _showFolderMenuUids(
    TapDownDetails details,
    String collectionUid,
    String folderUid,
  ) {
    final c = _resolver.collection(collectionUid);
    final f = _resolver.folder(collectionUid, folderUid);
    if (c == null || f == null) return;
    _selectExplorerItem('folder:${f.uid}', collectionUid: c.uid);
    widget.onFolderContextMenu(details, c, f);
  }

  void _showRequestMenuUids(
    TapDownDetails details,
    String collectionUid,
    String requestUid,
  ) {
    final c = _resolver.collection(collectionUid);
    final r = _resolver.request(collectionUid, requestUid);
    if (c == null || r == null) return;
    _selectExplorerItem('request:${r.uid}', collectionUid: c.uid);
    widget.onRequestContextMenu(details, c, r);
  }

  void _openNewRequestForUid(String collectionUid, {String? folderUid}) {
    final c = _resolver.collection(collectionUid);
    if (c == null) return;
    _openNewRequest(c, folderUid: folderUid);
  }

  void _openRequestUid(String collectionUid, String requestUid) {
    final c = _resolver.collection(collectionUid);
    final r = _resolver.request(collectionUid, requestUid);
    if (c == null || r == null) return;
    _openRequest(c, r);
  }

  void _selectRequestUid(String collectionUid, String requestUid) {
    _selectExplorerItem('request:$requestUid', collectionUid: collectionUid);
  }

  Widget _buildExplorerRow(_ExplorerLiteNode row) {
    return KeyedSubtree(
      key: ValueKey(row.id),
      child: _ExplorerFlatRowWeb(
        row: row,
        selectedCollectionUid: _selectedCollectionUid,
        selectedExplorerItemId: _selectedExplorerItemId,
        onSelectCollectionUid: _selectCollectionUid,
        onToggleCollectionUid: _toggleCollectionUid,
        onToggleFolderUid: _toggleFolderUid,
        onOpenNewRequestForUid: _openNewRequestForUid,
        onSelectRequestUid: _selectRequestUid,
        onOpenRequestUid: _openRequestUid,
        onCollectionContextMenuUid: _showCollectionMenuUid,
        onFolderContextMenuUid: _showFolderMenuUids,
        onRequestContextMenuUid: _showRequestMenuUids,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Explorer'.toUpperCase(),
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.48),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Collapse all collections',
                  onPressed: widget.collections.isEmpty
                      ? null
                      : _collapseAllCollections,
                  icon: const Icon(Icons.unfold_less, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Expand all collections',
                  onPressed: widget.collections.isEmpty
                      ? null
                      : _expandAllCollections,
                  icon: const Icon(Icons.unfold_more, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'New Collection',
                  onPressed: widget.onCreateCollection,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (widget.collections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SizedBox(
                height: kWebChromeSingleLineFieldHeight,
                child: TextField(
                  focusNode: _explorerSearchFocusNode,
                  controller: _explorerSearchController,
                  onSubmitted: (_) => _leaveExplorerSearchField(),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurface.withValues(alpha: 0.84),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    hintText: 'Search by name',
                    hintStyle: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 12.5,
                    ),
                    prefixIcon: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Icon(
                          Icons.search,
                          size: 18,
                          color: scheme.onSurface.withValues(alpha: 0.48),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    suffixIcon: _buildExplorerSearchSuffix(scheme),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 58,
                      minHeight: 40,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.28),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: widget.collections.isEmpty
                ? _EmptyCollectionsExplorer(
                    onCreateCollection: widget.onCreateCollection,
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _focusExplorer(),
                    child: _explorerSearchNorm.isNotEmpty && _rows.isEmpty
                        ? _ExplorerSearchEmptyState(
                            query: _explorerSearchController.text.trim(),
                          )
                        : Scrollbar(
                            controller: widget.scrollController,
                            thumbVisibility: true,
                            interactive: true,
                            child: ListView.builder(
                              controller: widget.scrollController,
                              padding: const EdgeInsets.fromLTRB(6, 0, 8, 12),
                              itemExtent: _explorerRowHeight,
                              itemCount: _rows.length,
                              itemBuilder: (context, index) {
                                return _buildExplorerRow(_rows[index]);
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerEntityResolver {
  _ExplorerEntityResolver._({
    required this.collectionsByUid,
    required this.foldersByKey,
    required this.requestsByKey,
  });

  final Map<String, Collection> collectionsByUid;
  final Map<String, Folder> foldersByKey;
  final Map<String, HttpRequest> requestsByKey;

  static String _fk(String collectionUid, String entityUid) =>
      '$collectionUid\x1F$entityUid';

  factory _ExplorerEntityResolver.from(List<Collection> collections) {
    final cMap = <String, Collection>{};
    final fMap = <String, Folder>{};
    final rMap = <String, HttpRequest>{};
    for (final c in collections) {
      cMap[c.uid] = c;
      void walkFolders(List<Folder> folders) {
        for (final f in folders) {
          fMap[_fk(c.uid, f.uid)] = f;
          for (final r in f.requests) {
            rMap[_fk(c.uid, r.uid)] = r;
          }
          walkFolders(f.subFolders);
        }
      }

      walkFolders(c.folders);
      for (final r in c.requests) {
        rMap[_fk(c.uid, r.uid)] = r;
      }
    }
    return _ExplorerEntityResolver._(
      collectionsByUid: cMap,
      foldersByKey: fMap,
      requestsByKey: rMap,
    );
  }

  Collection? collection(String uid) => collectionsByUid[uid];

  Folder? folder(String collectionUid, String folderUid) =>
      foldersByKey[_fk(collectionUid, folderUid)];

  HttpRequest? request(String collectionUid, String requestUid) =>
      requestsByKey[_fk(collectionUid, requestUid)];
}

enum _ExplorerRowKind { collection, folder, request }

class _ExplorerLiteNode {
  const _ExplorerLiteNode._({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.collectionUid,
    required this.depth,
    required this.hasChildren,
    this.folderUid,
    this.requestUid,
    this.containingFolderUid,
    this.requestMethod,
    this.isExpanded = false,
  });

  factory _ExplorerLiteNode.collection({
    required String uid,
    required String name,
    required int depth,
    required bool hasChildren,
    bool isExpanded = false,
  }) {
    return _ExplorerLiteNode._(
      id: 'collection:$uid',
      kind: _ExplorerRowKind.collection,
      displayName: name,
      collectionUid: uid,
      depth: depth,
      hasChildren: hasChildren,
      isExpanded: isExpanded,
    );
  }

  factory _ExplorerLiteNode.folder({
    required String collectionUid,
    required String folderUid,
    required String name,
    required int depth,
    required bool hasChildren,
    bool isExpanded = false,
  }) {
    return _ExplorerLiteNode._(
      id: 'folder:$folderUid',
      kind: _ExplorerRowKind.folder,
      displayName: name,
      collectionUid: collectionUid,
      depth: depth,
      hasChildren: hasChildren,
      folderUid: folderUid,
      isExpanded: isExpanded,
    );
  }

  factory _ExplorerLiteNode.request({
    required String collectionUid,
    required String requestUid,
    required String name,
    required int depth,
    required HttpMethod method,
    String? containingFolderUid,
  }) {
    return _ExplorerLiteNode._(
      id: 'request:$requestUid',
      kind: _ExplorerRowKind.request,
      displayName: name,
      collectionUid: collectionUid,
      depth: depth,
      hasChildren: false,
      requestUid: requestUid,
      containingFolderUid: containingFolderUid,
      requestMethod: method,
      isExpanded: false,
    );
  }

  final String id;
  final _ExplorerRowKind kind;
  final String displayName;
  final String collectionUid;
  final int depth;
  final bool hasChildren;
  final bool isExpanded;
  final String? folderUid;
  final String? requestUid;
  final String? containingFolderUid;
  final HttpMethod? requestMethod;

  _ExplorerLiteNode withExpanded(bool expanded) {
    if (isExpanded == expanded) return this;
    return _ExplorerLiteNode._(
      id: id,
      kind: kind,
      displayName: displayName,
      collectionUid: collectionUid,
      depth: depth,
      hasChildren: hasChildren,
      folderUid: folderUid,
      requestUid: requestUid,
      containingFolderUid: containingFolderUid,
      requestMethod: requestMethod,
      isExpanded: expanded,
    );
  }
}

class _ExplorerLiteIndex {
  const _ExplorerLiteIndex({
    required this.rootRows,
    required this.childrenByParentId,
    required this.collectionUids,
    required this.folderUids,
    required this.rowIds,
  });

  final List<_ExplorerLiteNode> rootRows;
  final Map<String, List<_ExplorerLiteNode>> childrenByParentId;
  final Set<String> collectionUids;
  final Set<String> folderUids;
  final Set<String> rowIds;

  factory _ExplorerLiteIndex.fromCollections(List<Collection> collections) {
    final rootRows = <_ExplorerLiteNode>[];
    final childrenByParentId = <String, List<_ExplorerLiteNode>>{};
    final collectionUids = <String>{};
    final folderUids = <String>{};
    final rowIds = <String>{};

    void registerRoot(_ExplorerLiteNode row) {
      rootRows.add(row);
      rowIds.add(row.id);
    }

    void registerChild(String parentId, _ExplorerLiteNode row) {
      (childrenByParentId[parentId] ??= <_ExplorerLiteNode>[]).add(row);
      rowIds.add(row.id);
    }

    void appendFolderRows({
      required String collectionUid,
      required String parentId,
      required List<Folder> folders,
      required int depth,
    }) {
      for (final folder in folders) {
        folderUids.add(folder.uid);
        final folderRow = _ExplorerLiteNode.folder(
          collectionUid: collectionUid,
          folderUid: folder.uid,
          name: folder.name,
          depth: depth,
          hasChildren:
              folder.subFolders.isNotEmpty || folder.requests.isNotEmpty,
        );
        registerChild(parentId, folderRow);
        appendFolderRows(
          collectionUid: collectionUid,
          parentId: folderRow.id,
          folders: folder.subFolders,
          depth: depth + 1,
        );
        for (final request in folder.requests) {
          registerChild(
            folderRow.id,
            _ExplorerLiteNode.request(
              collectionUid: collectionUid,
              requestUid: request.uid,
              name: request.name,
              depth: depth + 1,
              method: request.method,
              containingFolderUid: folder.uid,
            ),
          );
        }
      }
    }

    for (final collection in collections) {
      collectionUids.add(collection.uid);
      final collectionRow = _ExplorerLiteNode.collection(
        uid: collection.uid,
        name: collection.name,
        depth: 0,
        hasChildren:
            collection.folders.isNotEmpty || collection.requests.isNotEmpty,
      );
      registerRoot(collectionRow);
      appendFolderRows(
        collectionUid: collection.uid,
        parentId: collectionRow.id,
        folders: collection.folders,
        depth: 1,
      );
      for (final request in collection.requests) {
        registerChild(
          collectionRow.id,
          _ExplorerLiteNode.request(
            collectionUid: collection.uid,
            requestUid: request.uid,
            name: request.name,
            depth: 1,
            method: request.method,
          ),
        );
      }
    }

    return _ExplorerLiteIndex(
      rootRows: rootRows,
      childrenByParentId: childrenByParentId,
      collectionUids: collectionUids,
      folderUids: folderUids,
      rowIds: rowIds,
    );
  }

  String? parentRowId(String childRowId) {
    for (final entry in childrenByParentId.entries) {
      for (final child in entry.value) {
        if (child.id == childRowId) return entry.key;
      }
    }
    return null;
  }

  bool subtreeContainsSearchQuery(_ExplorerLiteNode row, String queryNorm) {
    if (row.displayName.toLowerCase().contains(queryNorm)) return true;
    for (final child
        in childrenByParentId[row.id] ?? const <_ExplorerLiteNode>[]) {
      if (subtreeContainsSearchQuery(child, queryNorm)) return true;
    }
    return false;
  }

  List<_ExplorerLiteNode> visibleRowsWithSearch({
    required String queryNorm,
    required Set<String> expandedCollectionUids,
    required Set<String> expandedFolderUids,
  }) {
    final rows = <_ExplorerLiteNode>[];
    for (final row in rootRows) {
      _appendVisibleRowForSearch(
        rows,
        row,
        queryNorm,
        expandedCollectionUids: expandedCollectionUids,
        expandedFolderUids: expandedFolderUids,
      );
    }
    return rows;
  }

  void _appendVisibleRowForSearch(
    List<_ExplorerLiteNode> rows,
    _ExplorerLiteNode row,
    String queryNorm, {
    required Set<String> expandedCollectionUids,
    required Set<String> expandedFolderUids,
  }) {
    if (!subtreeContainsSearchQuery(row, queryNorm)) return;

    final userExpanded = row.kind == _ExplorerRowKind.collection
        ? expandedCollectionUids.contains(row.collectionUid)
        : row.kind == _ExplorerRowKind.folder
        ? expandedFolderUids.contains(row.folderUid!)
        : false;
    final children = childrenByParentId[row.id] ?? const <_ExplorerLiteNode>[];
    final hasMatchingDescendant = children.any(
      (c) => subtreeContainsSearchQuery(c, queryNorm),
    );
    final visuallyExpanded = userExpanded || hasMatchingDescendant;

    rows.add(row.withExpanded(visuallyExpanded));
    if (!visuallyExpanded) return;

    for (final child in children) {
      if (!subtreeContainsSearchQuery(child, queryNorm)) continue;
      _appendVisibleRowForSearch(
        rows,
        child,
        queryNorm,
        expandedCollectionUids: expandedCollectionUids,
        expandedFolderUids: expandedFolderUids,
      );
    }
  }

  List<_ExplorerLiteNode> visibleRows({
    required Set<String> expandedCollectionUids,
    required Set<String> expandedFolderUids,
  }) {
    final rows = <_ExplorerLiteNode>[];
    for (final row in rootRows) {
      _appendVisibleRow(
        rows,
        row,
        expandedCollectionUids: expandedCollectionUids,
        expandedFolderUids: expandedFolderUids,
      );
    }
    return rows;
  }

  void _appendVisibleRow(
    List<_ExplorerLiteNode> rows,
    _ExplorerLiteNode row, {
    required Set<String> expandedCollectionUids,
    required Set<String> expandedFolderUids,
  }) {
    final expanded = row.kind == _ExplorerRowKind.collection
        ? expandedCollectionUids.contains(row.collectionUid)
        : row.kind == _ExplorerRowKind.folder
        ? expandedFolderUids.contains(row.folderUid!)
        : false;
    final visibleRow = row.withExpanded(expanded);
    rows.add(visibleRow);
    if (!expanded) return;
    for (final child
        in childrenByParentId[row.id] ?? const <_ExplorerLiteNode>[]) {
      _appendVisibleRow(
        rows,
        child,
        expandedCollectionUids: expandedCollectionUids,
        expandedFolderUids: expandedFolderUids,
      );
    }
  }
}

class _ExplorerFlatRowWeb extends StatelessWidget {
  const _ExplorerFlatRowWeb({
    required this.row,
    required this.selectedCollectionUid,
    required this.selectedExplorerItemId,
    required this.onSelectCollectionUid,
    required this.onToggleCollectionUid,
    required this.onToggleFolderUid,
    required this.onOpenNewRequestForUid,
    required this.onSelectRequestUid,
    required this.onOpenRequestUid,
    required this.onCollectionContextMenuUid,
    required this.onFolderContextMenuUid,
    required this.onRequestContextMenuUid,
  });

  final _ExplorerLiteNode row;
  final String? selectedCollectionUid;
  final String? selectedExplorerItemId;
  final void Function(String collectionUid) onSelectCollectionUid;
  final void Function(String collectionUid) onToggleCollectionUid;
  final void Function(String collectionUid, String folderUid) onToggleFolderUid;
  final void Function(String collectionUid, {String? folderUid})
  onOpenNewRequestForUid;
  final void Function(String collectionUid, String requestUid)
  onSelectRequestUid;
  final void Function(String collectionUid, String requestUid) onOpenRequestUid;
  final void Function(TapDownDetails details, String collectionUid)
  onCollectionContextMenuUid;
  final void Function(
    TapDownDetails details,
    String collectionUid,
    String folderUid,
  )
  onFolderContextMenuUid;
  final void Function(
    TapDownDetails details,
    String collectionUid,
    String requestUid,
  )
  onRequestContextMenuUid;

  @override
  Widget build(BuildContext context) {
    switch (row.kind) {
      case _ExplorerRowKind.collection:
        return _TreeRowWeb(
          depth: row.depth,
          icon: Icons.folder,
          label: row.displayName,
          isExpanded: row.isExpanded,
          hasChildren: row.hasChildren,
          isSelected:
              selectedCollectionUid == row.collectionUid ||
              selectedExplorerItemId == row.id,
          iconColor: _folderColor(context, row.depth),
          onTap: () => onSelectCollectionUid(row.collectionUid),
          onToggle: () => onToggleCollectionUid(row.collectionUid),
          onContextMenu: (details) =>
              onCollectionContextMenuUid(details, row.collectionUid),
          trailing: IconButton(
            tooltip: 'New Request',
            onPressed: () => onOpenNewRequestForUid(row.collectionUid),
            icon: const Icon(Icons.add, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        );
      case _ExplorerRowKind.folder:
        return _TreeRowWeb(
          depth: row.depth,
          icon: Icons.folder_outlined,
          label: row.displayName,
          hasChildren: row.hasChildren,
          isExpanded: row.isExpanded,
          isSelected: selectedExplorerItemId == row.id,
          iconColor: _folderColor(context, row.depth),
          onTap: () => onToggleFolderUid(row.collectionUid, row.folderUid!),
          onToggle: () => onToggleFolderUid(row.collectionUid, row.folderUid!),
          onContextMenu: (details) => onFolderContextMenuUid(
            details,
            row.collectionUid,
            row.folderUid!,
          ),
          trailing: IconButton(
            tooltip: 'New Request',
            onPressed: () => onOpenNewRequestForUid(
              row.collectionUid,
              folderUid: row.folderUid,
            ),
            icon: const Icon(Icons.add, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        );
      case _ExplorerRowKind.request:
        final method = row.requestMethod!;
        return _TreeRowWeb(
          depth: row.depth,
          icon: _methodIcon(method),
          label: row.displayName,
          hasChildren: false,
          isSelected: selectedExplorerItemId == row.id,
          iconColor: _methodColor(context, method),
          leadingBadge: _MethodBadgeWeb(method: method),
          hoverTooltip: row.displayName,
          hoverTooltipWait: _explorerRequestTooltipHoverWait,
          onTap: () => onSelectRequestUid(row.collectionUid, row.requestUid!),
          onDoubleTap: () =>
              onOpenRequestUid(row.collectionUid, row.requestUid!),
          onContextMenu: (details) => onRequestContextMenuUid(
            details,
            row.collectionUid,
            row.requestUid!,
          ),
        );
    }
  }
}

class _TreeRowWeb extends StatelessWidget {
  const _TreeRowWeb({
    required this.depth,
    required this.icon,
    required this.label,
    required this.hasChildren,
    required this.onTap,
    this.onToggle,
    this.onContextMenu,
    this.isExpanded = false,
    this.isSelected = false,
    this.iconColor,
    this.leadingBadge,
    this.trailing,
    this.hoverTooltip,
    this.hoverTooltipWait,
    this.onDoubleTap,
  });

  final int depth;
  final IconData icon;
  final String label;
  final bool hasChildren;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onToggle;
  final GestureTapDownCallback? onContextMenu;
  final bool isExpanded;
  final bool isSelected;
  final Color? iconColor;
  final Widget? leadingBadge;
  final Widget? trailing;

  /// When set (e.g. explorer requests), shown after [hoverTooltipWait] on hover.
  final String? hoverTooltip;
  final Duration? hoverTooltipWait;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onSecondaryTapDown: onContextMenu,
      borderRadius: BorderRadius.circular(6),
      hoverColor: scheme.primary.withValues(alpha: 0.06),
      focusColor: scheme.primary.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: _explorerRowAnimationDuration,
        curve: Curves.easeOutCubic,
        height: _explorerRowHeight,
        padding: EdgeInsets.only(left: 6.0 + (depth * 16), right: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: hasChildren
                  ? InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(9),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: _explorerBranchAnimationDuration,
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_right,
                          size: 18,
                          color: scheme.onSurface.withValues(alpha: 0.62),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Icon(icon, size: 16, color: iconColor ?? scheme.onSurface),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurface.withValues(alpha: 0.84),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (leadingBadge != null) ...[
              leadingBadge!,
              const SizedBox(width: 6),
            ],
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
    final tip = hoverTooltip?.trim();
    if (tip == null || tip.isEmpty) return row;
    return Tooltip(
      message: tip,
      waitDuration: hoverTooltipWait ?? _explorerRequestTooltipHoverWait,
      // Default RawTooltip long-press/tap routing can delay taps on some pointer
      // kinds; hover-only tooltips are enough for explorer rows.
      triggerMode: TooltipTriggerMode.manual,
      verticalOffset: 6,
      child: row,
    );
  }
}

class _MethodBadgeWeb extends StatelessWidget {
  const _MethodBadgeWeb({required this.method});

  final HttpMethod method;

  @override
  Widget build(BuildContext context) {
    final color = _methodColor(context, method);
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        method.value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontFamily: 'JetBrainsMono',
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

IconData _methodIcon(HttpMethod method) {
  return switch (method) {
    HttpMethod.get => Icons.description_outlined,
    HttpMethod.post => Icons.note_add_outlined,
    HttpMethod.put => Icons.drive_file_rename_outline,
    HttpMethod.patch => Icons.edit_document,
    HttpMethod.delete => Icons.delete_sweep_outlined,
    HttpMethod.head => Icons.subject_outlined,
    HttpMethod.options => Icons.rule_folder_outlined,
  };
}

Color _methodColor(BuildContext context, HttpMethod method) {
  return AppColors.methodColor(method.value);
}

Color _folderColor(BuildContext context, int depth) {
  final scheme = Theme.of(context).colorScheme;
  const colors = [
    Color(0xFFDB952C),
    Color(0xFF6C8EF7),
    Color(0xFF27A69A),
    Color(0xFF9C6ADE),
  ];
  return Color.alphaBlend(
    colors[depth % colors.length].withValues(alpha: 0.9),
    scheme.surface,
  );
}

class _RequestWorkspace extends StatelessWidget {
  const _RequestWorkspace({
    required this.tabs,
    required this.activeTabId,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onReportTabStatus,
  });

  final List<WebWorkspaceTab> tabs;
  final String? activeTabId;
  final ValueChanged<String> onSelectTab;
  final Future<void> Function(String tabId) onCloseTab;
  final void Function({
    required String tabId,
    required String title,
    required bool isDirty,
    required bool isSending,
    required bool hasResponse,
    String? requestUid,
  })
  onReportTabStatus;

  @override
  Widget build(BuildContext context) {
    final activeIndex = tabs.indexWhere((tab) => tab.id == activeTabId);
    return Column(
      children: [
        _RequestTabStripWeb(
          tabs: tabs,
          activeTabId: activeTabId,
          onSelectTab: onSelectTab,
          onCloseTab: onCloseTab,
        ),
        Expanded(
          child: activeIndex == -1
              ? const _EmptyRequestWorkspaceWeb()
              : IndexedStack(
                  index: activeIndex,
                  children: [
                    for (final tab in tabs)
                      ProviderScope(
                        key: ValueKey('request-tab-scope-${tab.id}'),
                        child: _RequestWorkspaceTabBodyWeb(
                          tab: tab,
                          onReportTabStatus: onReportTabStatus,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RequestWorkspaceTabBodyWeb extends ConsumerStatefulWidget {
  const _RequestWorkspaceTabBodyWeb({
    required this.tab,
    required this.onReportTabStatus,
  });

  final WebWorkspaceTab tab;
  final void Function({
    required String tabId,
    required String title,
    required bool isDirty,
    required bool isSending,
    required bool hasResponse,
    String? requestUid,
  })
  onReportTabStatus;

  @override
  ConsumerState<_RequestWorkspaceTabBodyWeb> createState() =>
      _RequestWorkspaceTabBodyWebState();
}

class _RequestWorkspaceTabBodyWebState
    extends ConsumerState<_RequestWorkspaceTabBodyWeb> {
  var _tabStatusListenersAttached = false;

  void _reportTabStatus() {
    if (!mounted) return;
    final builderState = ref.read(requestBuilderProvider);
    final executionState = ref.read(requestExecutionProvider);
    widget.onReportTabStatus(
      tabId: widget.tab.id,
      title: builderState.name,
      isDirty: builderState.isDirty,
      isSending: executionState.isLoading,
      hasResponse: executionState.hasValue && executionState.value != null,
      requestUid: builderState.loadedRequestUid ?? widget.tab.requestUid,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabStatusListenersAttached) return;
    _tabStatusListenersAttached = true;
    ref.listenManual<RequestBuilderState>(
      requestBuilderProvider,
      (_, __) => _reportTabStatus(),
    );
    ref.listenManual<AsyncValue<HttpResponse?>>(
      requestExecutionProvider,
      (_, __) => _reportTabStatus(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportTabStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RequestBuilderScreenMaterial(
      key: ValueKey('request-builder-${widget.tab.id}'),
      collectionUid: widget.tab.collectionUid,
      requestUid: widget.tab.requestUid,
      folderUid: widget.tab.folderUid,
      draftScopeId: widget.tab.id,
    );
  }
}

class _RequestTabStripWeb extends StatelessWidget {
  const _RequestTabStripWeb({
    required this.tabs,
    required this.activeTabId,
    required this.onSelectTab,
    required this.onCloseTab,
  });

  final List<WebWorkspaceTab> tabs;
  final String? activeTabId;
  final ValueChanged<String> onSelectTab;
  final Future<void> Function(String tabId) onCloseTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: tabs.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Open a request from Collections',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.48),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final tab in tabs)
                  _RequestTabWeb(
                    tab: tab,
                    isActive: tab.id == activeTabId,
                    onSelect: () => onSelectTab(tab.id),
                    onClose: () {
                      onCloseTab(tab.id);
                    },
                  ),
              ],
            ),
    );
  }
}

class _RequestTabWeb extends StatelessWidget {
  const _RequestTabWeb({
    required this.tab,
    required this.isActive,
    required this.onSelect,
    required this.onClose,
  });

  final WebWorkspaceTab tab;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onSelect,
      child: Container(
        width: 188,
        decoration: BoxDecoration(
          color: isActive
              ? scheme.surfaceContainerLow
              : scheme.surface.withValues(alpha: 0.6),
          border: Border(
            right: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            top: BorderSide(
              color: isActive ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
        child: Row(
          children: [
            Icon(
              tab.requestUid == null
                  ? Icons.add_circle_outline
                  : Icons.insert_drive_file_outlined,
              size: 15,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                tab.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (tab.isSending)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              )
            else if (tab.hasResponse)
              Icon(
                Icons.check_circle,
                size: 12,
                color: scheme.primary.withValues(alpha: 0.72),
              )
            else if (tab.isDirty)
              Icon(
                Icons.circle,
                size: 8,
                color: scheme.primary.withValues(alpha: 0.72),
              ),
            IconButton(
              tooltip: 'Close request tab',
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 14),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRequestWorkspaceWeb extends StatelessWidget {
  const _EmptyRequestWorkspaceWeb();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tab_outlined,
            size: 48,
            color: scheme.onSurface.withValues(alpha: 0.28),
          ),
          const SizedBox(height: 12),
          Text(
            'No request tab open',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.64),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a request in the collection explorer to open it here.',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.48),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseRequestTabDialogWeb extends StatelessWidget {
  const _CloseRequestTabDialogWeb();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close request tab?'),
      content: const Text(
        'This tab has unsaved changes, an unsaved request, or an in-flight send. '
        'Closing it will discard the tab state.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Close tab'),
        ),
      ],
    );
  }
}

class _ExplorerSearchEmptyState extends StatelessWidget {
  const _ExplorerSearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 38,
              color: scheme.onSurface.withValues(alpha: 0.36),
            ),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.76),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Nothing matches "${query.replaceAll('"', '')}"',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.54),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCollectionsExplorer extends StatelessWidget {
  const _EmptyCollectionsExplorer({required this.onCreateCollection});

  final VoidCallback onCreateCollection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 36,
              color: scheme.onSurface.withValues(alpha: 0.36),
            ),
            const SizedBox(height: 10),
            Text(
              'No collections',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onCreateCollection,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Collection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCollectionDialogWeb extends StatefulWidget {
  const _CreateCollectionDialogWeb();

  @override
  State<_CreateCollectionDialogWeb> createState() =>
      _CreateCollectionDialogWebState();
}

class _CreateCollectionDialogWebState
    extends State<_CreateCollectionDialogWeb> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Collection'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final description = _descriptionController.text.trim();
    Navigator.pop(context, (name, description.isEmpty ? null : description));
  }
}
