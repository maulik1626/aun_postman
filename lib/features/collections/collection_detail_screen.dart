import 'dart:io';

import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/app_haptics.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_importer.dart';
import 'package:aun_reqstudio/domain/models/collection.dart';
import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:aun_reqstudio/domain/models/folder.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/collections/widgets/collection_tree_dnd.dart';
import 'package:aun_reqstudio/features/collections/widgets/method_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

// Destination entry for the Move picker
typedef _MoveDest = ({String collectionUid, String? folderUid, String label});

class CollectionDetailScreen extends ConsumerStatefulWidget {
  const CollectionDetailScreen({super.key, required this.uid});
  final String uid;

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  static const _uuid = Uuid();

  // Tracks which folder UIDs are expanded (works at any nesting depth)
  final Set<String> _expandedFolders = {};

  CollectionTreeDragData? _draggingData;

  bool _selectionMode = false;

  /// Selection order for export (`true` = folder uid, `false` = request uid).
  final List<(bool isFolder, String uid)> _selectionOrder = [];

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectionOrder.clear();
    });
  }

  void _toggleSelectFolder(String uid) {
    setState(() {
      final i = _selectionOrder.indexWhere((e) => e.$1 && e.$2 == uid);
      if (i >= 0) {
        _selectionOrder.removeAt(i);
      } else {
        _selectionOrder.add((true, uid));
      }
    });
  }

  void _toggleSelectRequest(String uid) {
    setState(() {
      final i = _selectionOrder.indexWhere((e) => !e.$1 && e.$2 == uid);
      if (i >= 0) {
        _selectionOrder.removeAt(i);
      } else {
        _selectionOrder.add((false, uid));
      }
    });
  }

  void _longPressEnterSelectionForFolder(String uid) {
    AppHaptics.medium();
    setState(() {
      _selectionMode = true;
      _draggingData = null;
      if (!_selectionOrder.any((e) => e.$1 && e.$2 == uid)) {
        _selectionOrder.add((true, uid));
      }
    });
  }

  void _longPressEnterSelectionForRequest(String uid) {
    AppHaptics.medium();
    setState(() {
      _selectionMode = true;
      _draggingData = null;
      if (!_selectionOrder.any((e) => !e.$1 && e.$2 == uid)) {
        _selectionOrder.add((false, uid));
      }
    });
  }

  Set<String> _selectedFolderUids() =>
      {for (final e in _selectionOrder) if (e.$1) e.$2};

  Set<String> _selectedRequestUids() =>
      {for (final e in _selectionOrder) if (!e.$1) e.$2};

  bool _folderHasSelectedAncestor(Collection c, String folderUid) {
    final sel = _selectedFolderUids();
    final f = _findFolderByUid(c.folders, folderUid);
    if (f == null) return false;
    String? p = f.parentFolderUid;
    while (p != null) {
      if (sel.contains(p)) return true;
      final parent = _findFolderByUid(c.folders, p);
      p = parent?.parentFolderUid;
    }
    return false;
  }

  bool _requestCoveredBySelectedFolder(Collection c, HttpRequest req) {
    final sel = _selectedFolderUids();
    String? u = req.folderUid;
    while (u != null) {
      if (sel.contains(u)) return true;
      final fold = _findFolderByUid(c.folders, u);
      u = fold?.parentFolderUid;
    }
    return false;
  }

  HttpRequest? _findRequestByUid(Collection c, String uid) {
    for (final r in c.requests) {
      if (r.uid == uid) return r;
    }
    for (final f in c.folders) {
      final found = _findRequestInFolderSubtree(f, uid);
      if (found != null) return found;
    }
    return null;
  }

  HttpRequest? _findRequestInFolderSubtree(Folder folder, String uid) {
    for (final r in folder.requests) {
      if (r.uid == uid) return r;
    }
    for (final sf in folder.subFolders) {
      final x = _findRequestInFolderSubtree(sf, uid);
      if (x != null) return x;
    }
    return null;
  }

  /// Same inclusion rules as export: folder subtree dedupe, requests inside a
  /// selected folder omitted.
  void _forEachEffectiveSelection(
    Collection c, {
    required void Function(Folder folder) onFolder,
    required void Function(HttpRequest request) onRequest,
  }) {
    final selFolders = _selectedFolderUids();
    final selReqs = _selectedRequestUids();
    for (final (isFolder, uid) in _selectionOrder) {
      if (isFolder) {
        if (!selFolders.contains(uid)) continue;
        if (_folderHasSelectedAncestor(c, uid)) continue;
        final f = _findFolderByUid(c.folders, uid);
        if (f != null) onFolder(f);
      } else {
        if (!selReqs.contains(uid)) continue;
        final r = _findRequestByUid(c, uid);
        if (r == null) continue;
        if (_requestCoveredBySelectedFolder(c, r)) continue;
        onRequest(r);
      }
    }
  }

  List<CollectionV21FragmentEntry> _buildFragmentExportEntries(Collection c) {
    final out = <CollectionV21FragmentEntry>[];
    _forEachEffectiveSelection(
      c,
      onFolder: (f) => out.add(CollectionV21FragmentFolder(f)),
      onRequest: (r) => out.add(CollectionV21FragmentRequest(r)),
    );
    return out;
  }

  Rect _shareAnchorRect(BuildContext anchorContext) {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final topLeft = box.localToGlobal(Offset.zero);
      return topLeft & box.size;
    }
    final size = MediaQuery.sizeOf(anchorContext);
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 2,
      height: 2,
    );
  }

  Future<void> _exportSelectedFragment(Collection collection) async {
    final entries = _buildFragmentExportEntries(collection);
    if (entries.isEmpty) return;
    final title = entries.length == 1
        ? switch (entries.first) {
            CollectionV21FragmentFolder(:final folder) => folder.name,
            CollectionV21FragmentRequest(:final request) => request.name,
          }
        : '${collection.name} (${entries.length} items)';
    try {
      final json = CollectionV21Exporter.exportFragment(
        title: title,
        description: 'Exported from ${collection.name}',
        entries: entries,
      );
      final dir = await getTemporaryDirectory();
      final safe =
          title.replaceAll(RegExp(r'[^\w\s.-]'), '_').replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/$safe.json');
      await file.writeAsString(json);
      if (!mounted) return;
      final origin = Platform.isIOS ? _shareAnchorRect(context) : null;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '$title — AUN - ReqStudio',
        sharePositionOrigin: origin,
      );
      _exitSelectionMode();
    } catch (e) {
      if (!mounted) return;
      UserNotification.show(
        context: context,
        title: 'Export',
        body: e.toString(),
      );
    }
  }

  Future<void> _confirmAndDeleteSelection(Collection collection) async {
    final folders = <Folder>[];
    final requests = <HttpRequest>[];
    _forEachEffectiveSelection(
      collection,
      onFolder: folders.add,
      onRequest: requests.add,
    );
    if (folders.isEmpty && requests.isEmpty) return;

    final nFolders = folders.length;
    var reqsInsideFolders = 0;
    for (final f in folders) {
      reqsInsideFolders += _countRequests(f);
    }
    final nLoose = requests.length;

    late final String body;
    if (nFolders > 0 && nLoose > 0) {
      body =
          'Delete $nFolders folder(s) ($reqsInsideFolders request(s) inside) '
          'and $nLoose other request(s)? This cannot be undone.';
    } else if (nFolders > 0) {
      body = nFolders == 1
          ? 'Delete "${folders.first.name}" and $reqsInsideFolders request(s)? '
              'This cannot be undone.'
          : 'Delete $nFolders folders ($reqsInsideFolders request(s) inside)? '
              'This cannot be undone.';
    } else if (nLoose == 1) {
      body = 'Delete "${requests.first.name}"? This cannot be undone.';
    } else {
      body = 'Delete $nLoose requests? This cannot be undone.';
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete selected'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(body),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    var updated = collection;
    for (final r in requests) {
      updated = _removeRequestFrom(updated, r.uid, r.folderUid);
    }
    for (final f in folders) {
      updated = updated.copyWith(
        folders: _removeFolderFromTree(updated.folders, f.uid),
      );
    }

    await ref.read(collectionsProvider.notifier).update(updated);
    if (!mounted) return;
    setState(() {
      for (final f in folders) {
        _expandedFolders.remove(f.uid);
      }
    });
    _exitSelectionMode();
  }

  Future<void> _exportSingleFolder(Collection collection, Folder folder) async {
    try {
      final json = CollectionV21Exporter.exportFragment(
        title: folder.name,
        description: 'Exported from ${collection.name}',
        entries: [CollectionV21FragmentFolder(folder)],
      );
      final dir = await getTemporaryDirectory();
      final safe = folder.name
          .replaceAll(RegExp(r'[^\w\s.-]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/$safe.json');
      await file.writeAsString(json);
      if (!mounted) return;
      final origin = Platform.isIOS ? _shareAnchorRect(context) : null;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '${folder.name} — AUN - ReqStudio',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      UserNotification.show(
        context: context,
        title: 'Export',
        body: e.toString(),
      );
    }
  }

  Future<void> _exportSingleRequest(Collection collection, HttpRequest request) async {
    try {
      final json = CollectionV21Exporter.exportFragment(
        title: request.name,
        description: 'Exported from ${collection.name}',
        entries: [CollectionV21FragmentRequest(request)],
      );
      final dir = await getTemporaryDirectory();
      final safe = request.name
          .replaceAll(RegExp(r'[^\w\s.-]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final requestFile = File('${dir.path}/$safe.json');
      await requestFile.writeAsString(json);
      final files = <XFile>[
        XFile(requestFile.path, mimeType: 'application/json'),
      ];
      final variableNames = CollectionV21Importer.extractVariableNames(json);
      if (variableNames.isNotEmpty) {
        final now = DateTime.now();
        final env = Environment(
          uid: _uuid.v4(),
          name: '${request.name} Variables',
          variables: variableNames
              .map(
                (k) => EnvironmentVariable(
                  uid: _uuid.v4(),
                  key: k,
                  value: '',
                ),
              )
              .toList(),
          createdAt: now,
          updatedAt: now,
        );
        final envJson = CollectionV21Exporter.exportEnvironment(env);
        final envFile = File('${dir.path}/${safe}_variables.postman_environment.json');
        await envFile.writeAsString(envJson);
        files.add(XFile(envFile.path, mimeType: 'application/json'));
      }
      if (!mounted) return;
      final origin = Platform.isIOS ? _shareAnchorRect(context) : null;
      await Share.shareXFiles(
        files,
        subject: '${request.name} — AUN - ReqStudio',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      UserNotification.show(
        context: context,
        title: 'Export',
        body: e.toString(),
      );
    }
  }

  Future<void> _importCollectionFragment(
    Collection collection, {
    required String? parentFolderUid,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    try {
      final content = await File(result.files.single.path!).readAsString();
      final fragment = CollectionV21Importer.importFragment(content);
      await ref.read(collectionsProvider.notifier).mergeCollectionFragment(
            collectionUid: collection.uid,
            parentFolderUid: parentFolderUid,
            folders: fragment.folders,
            rootRequests: fragment.rootRequests,
          );
      final varNames = CollectionV21Importer.extractVariableNames(content);
      if (varNames.isNotEmpty) {
        final now = DateTime.now();
        final environment = Environment(
          uid: _uuid.v4(),
          name: '${fragment.name} Variables',
          variables: varNames
              .map(
                (k) => EnvironmentVariable(
                  uid: _uuid.v4(),
                  key: k,
                  value: '',
                ),
              )
              .toList(),
          createdAt: now,
          updatedAt: now,
        );
        await ref
            .read(environmentsProvider.notifier)
            .importEnvironment(environment);
        if (mounted) {
          UserNotification.show(
            context: context,
            title: 'Import',
            body:
                'Merged ${fragment.folders.length} folder(s), ${fragment.rootRequests.length} request(s). '
                'Created environment with ${varNames.length} variables.',
          );
        }
      } else if (mounted) {
        UserNotification.show(
          context: context,
          title: 'Import',
          body:
              'Merged ${fragment.folders.length} folder(s), ${fragment.rootRequests.length} request(s).',
        );
      }
    } catch (e) {
      if (!mounted) return;
      UserNotification.show(
        context: context,
        title: 'Import',
        body: e.toString(),
      );
    }
  }

  void _endTreeDragSession() {
    if (!mounted) return;
    if (_draggingData == null) return;
    setState(() => _draggingData = null);
  }

  // ── Tree helpers ─────────────────────────────────────────────────────────────

  List<Folder> _updateFolderInTree(
    List<Folder> folders,
    String uid,
    Folder Function(Folder) updater,
  ) {
    return folders.map((f) {
      if (f.uid == uid) return updater(f);
      return f.copyWith(
          subFolders: _updateFolderInTree(f.subFolders, uid, updater));
    }).toList();
  }

  List<Folder> _removeFolderFromTree(List<Folder> folders, String uid) {
    return folders
        .where((f) => f.uid != uid)
        .map((f) => f.copyWith(
            subFolders: _removeFolderFromTree(f.subFolders, uid)))
        .toList();
  }

  List<Widget> _collectionTreeListChildren(
    BuildContext context,
    Collection collection,
  ) {
    return [
      if (collection.requests.isNotEmpty) ...[
        _sectionHeader(context, 'REQUESTS'),
        ...List.generate(
          collection.requests.length,
          (i) => _rootRequestTile(context, collection, i),
        ),
      ] else if (collection.folders.isNotEmpty &&
          _draggingData is CollectionTreeDragRequest &&
          (_draggingData! as CollectionTreeDragRequest).fromFolderUid !=
              null) ...[
        _sectionHeader(context, 'REQUESTS'),
        _emptyRootRequestsDropStrip(context),
      ],
      if (collection.folders.isNotEmpty) ...[
        _sectionHeader(context, 'FOLDERS'),
        _buildFolderDnDList(
          context,
          collection,
          collection.folders,
          indent: 0,
          parentFolderUid: null,
        ),
      ],
    ];
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final collection =
        collections.where((c) => c.uid == widget.uid).firstOrNull;

    // Collection was deleted while this screen was open — pop back gracefully.
    if (collection == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final descriptionText = collection.description?.trim();
    final isEmpty =
        collection.requests.isEmpty && collection.folders.isEmpty;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final effectiveSelectionCount = _selectionMode
        ? _buildFragmentExportEntries(collection).length
        : 0;

    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(collection.name),
                  leading: _selectionMode
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 44,
                          onPressed: _exitSelectionMode,
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 17,
                              color: CupertinoTheme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectionMode)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 44,
                          onPressed: effectiveSelectionCount == 0
                              ? null
                              : () => _confirmAndDeleteSelection(collection),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: effectiveSelectionCount == 0
                                  ? CupertinoColors.tertiaryLabel
                                      .resolveFrom(context)
                                  : CupertinoColors.destructiveRed
                                      .resolveFrom(context),
                            ),
                          ),
                        )
                      else ...[
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 44,
                          onPressed: () => setState(() {
                            _selectionMode = true;
                            _draggingData = null;
                          }),
                          child: const Icon(
                            CupertinoIcons.check_mark_circled,
                            size: 22,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 44,
                          onPressed: () => _importCollectionFragment(
                            collection,
                            parentFolderUid: null,
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_down_doc,
                            size: 22,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 44,
                          onPressed: () => _showCreateFolderDialog(
                            context,
                            collection,
                            parentUid: null,
                          ),
                          child: const Icon(
                            CupertinoIcons.folder_badge_plus,
                            size: 22,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 44,
                          onPressed: () => context.push(
                            '${AppRoutes.collections}/${widget.uid}/auth',
                          ),
                          child: const Icon(CupertinoIcons.lock_shield, size: 22),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 44,
                          onPressed: () => context.push(
                            '/collections/${widget.uid}/request/new',
                          ),
                          child: const Icon(CupertinoIcons.add),
                        ),
                      ],
                    ],
                  ),
                ),
          if (descriptionText != null && descriptionText.isNotEmpty)
            SliverToBoxAdapter(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _selectionMode ? _exitSelectionMode : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    descriptionText,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
              ),
            ),
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: CupertinoTheme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                CupertinoIcons.arrow_up_right_diamond,
                                size: 36,
                                color: CupertinoTheme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No requests yet',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a request or create a folder to organise',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width - 48,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppGradientButton.secondary(
                                    fullWidth: true,
                                    onPressed: () => _showCreateFolderDialog(
                                      context,
                                      collection,
                                      parentUid: null,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.folder_badge_plus,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text('New Folder'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  AppGradientButton(
                                    fullWidth: true,
                                    onPressed: () => context.push(
                                      '/collections/${widget.uid}/request/new',
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(CupertinoIcons.add, size: 18),
                                        SizedBox(width: 8),
                                        Text('Add Request'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  AppGradientButton.secondary(
                                    fullWidth: true,
                                    onPressed: () => _importCollectionFragment(
                                      collection,
                                      parentFolderUid: null,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.arrow_down_doc,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Import collection JSON'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: bottomInset + 8),
                ],
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CollectionTreeDnDScope(
                      dragging: _selectionMode ? null : _draggingData,
                      child: Builder(
                        builder: (scopedContext) {
                          final children =
                              _collectionTreeListChildren(scopedContext, collection);
                          if (_selectionMode) {
                            return Stack(
                              fit: StackFit.expand,
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _exitSelectionMode,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                ListView(
                                  shrinkWrap: true,
                                  primary: false,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  children: children,
                                ),
                              ],
                            );
                          }
                          return ListView(
                            padding: EdgeInsets.zero,
                            children: children,
                          );
                        },
                      ),
                    ),
                  ),
                  // Safe-area gap for home indicator when no toolbar; with selection
                  // toolbar, the bar handles inset — this spacer only wastes list height.
                  SizedBox(
                    height: _selectionMode ? 0 : bottomInset + 8,
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
          if (_selectionMode)
            _selectionBottomBar(context, collection, bottomInset),
        ],
      ),
    );
  }

  Widget _selectionBottomBar(
    BuildContext context,
    Collection collection,
    double bottomInset,
  ) {
    final effective = _buildFragmentExportEntries(collection).length;
    final sep = CupertinoColors.separator.resolveFrom(context);
    // Column gives this child unbounded max height; Row + Expanded must not use
    // SizedBox.expand() (infinite cross-axis). Fixed inner height bounds the Row.
    const barContentHeight = 52.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, 6, 12, bottomInset + 8),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        border: Border(top: BorderSide(color: sep, width: 0.5)),
      ),
      child: SizedBox(
        height: barContentHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _exitSelectionMode,
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _exitSelectionMode,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 2),
                  child: Text(
                    '${_selectionOrder.length} selected',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.center,
              child: effective == 0
                  ? AppGradientButton.secondary(
                      onPressed: null,
                      child: const Text('Export'),
                    )
                  : AppGradientButton(
                      onPressed: () => _exportSelectedFragment(collection),
                      child: Text(
                        effective == 1 ? 'Export' : 'Export ($effective)',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static const _folderSiblingBandHeight = 16.0;

  /// Nested folder branches with drag-and-drop (reorder, reparent, move requests).
  Widget _buildFolderDnDList(
    BuildContext context,
    Collection collection,
    List<Folder> folders, {
    required int indent,
    required String? parentFolderUid,
  }) {
    if (folders.isEmpty) return const SizedBox.shrink();

    return Column(
      key: ValueKey('folders_${parentFolderUid ?? 'root'}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(folders.length, (index) {
        final folder = folders[index];
        final isExpanded = _expandedFolders.contains(folder.uid);

        final header = _FolderHeader(
          folder: folder,
          isExpanded: isExpanded,
          indent: indent,
          selectionMode: _selectionMode,
          isSelected: _selectedFolderUids().contains(folder.uid),
          onToggleSelect: () => _toggleSelectFolder(folder.uid),
          dragData: CollectionTreeDragFolder(
            collectionUid: widget.uid,
            folder: folder,
            parentFolderUid: parentFolderUid,
          ),
          onDragStarted: () => setState(() {
            _draggingData = CollectionTreeDragFolder(
              collectionUid: widget.uid,
              folder: folder,
              parentFolderUid: parentFolderUid,
            );
          }),
          onDragEnd: _endTreeDragSession,
          onDragCanceled: _endTreeDragSession,
          onToggle: () => setState(() {
            if (isExpanded) {
              _expandedFolders.remove(folder.uid);
            } else {
              _expandedFolders.add(folder.uid);
            }
          }),
          onRename: () =>
              _showRenameFolderDialog(context, collection, folder),
          onDelete: () => _deleteFolder(collection, folder),
          onAddRequest: () => context.push(
            '/collections/${widget.uid}/request/new',
            extra: folder.uid,
          ),
          onAddSubFolder: () => _showCreateFolderDialog(
            context,
            collection,
            parentUid: folder.uid,
          ),
          onImportCollectionJson: () => _importCollectionFragment(
            collection,
            parentFolderUid: folder.uid,
          ),
          onExportFolder: () => _exportSingleFolder(collection, folder),
          onLongPressSelect: () =>
              _longPressEnterSelectionForFolder(folder.uid),
        );

        final expandedBody = isExpanded
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFolderDnDList(
                    context,
                    collection,
                    folder.subFolders,
                    indent: indent + 1,
                    parentFolderUid: folder.uid,
                  ),
                  if (folder.requests.isNotEmpty)
                    ...List.generate(
                      folder.requests.length,
                      (reqIndex) => _folderRequestTile(
                        context,
                        collection,
                        folder,
                        indent + 1,
                        reqIndex,
                      ),
                    )
                  else if (_draggingData is CollectionTreeDragRequest)
                    _emptyFolderRequestsDropStrip(
                      context,
                      folder,
                      indent + 1,
                    ),
                ],
              )
            : null;

        final folderCore = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (expandedBody != null) expandedBody,
          ],
        );

        if (CollectionTreeDnDScope.maybeDraggingOf(context) == null) {
          return Column(
            key: ValueKey('folder_branch_${folder.uid}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [folderCore],
          );
        }

        final primary = CupertinoTheme.of(context).primaryColor;
        return Column(
          key: ValueKey('folder_branch_${folder.uid}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _folderSiblingBandHeight,
              child: DragTarget<CollectionTreeDragData>(
                onWillAcceptWithDetails: (details) => _willAcceptFolderSibling(
                  details.data,
                  parentFolderUid,
                  index,
                ),
                onAcceptWithDetails: (details) async {
                  _endTreeDragSession();
                  final d = details.data;
                  if (d is CollectionTreeDragFolder) {
                    await _relocateFolderSibling(
                      d,
                      parentFolderUid,
                      index,
                    );
                    AppHaptics.medium();
                  }
                },
                builder: (context, candidate, _) {
                  final show = candidate.isNotEmpty;
                  return IgnorePointer(
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: show ? primary : const Color(0x00000000),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            DragTarget<CollectionTreeDragData>(
              onWillAcceptWithDetails: (details) {
                if (details.data is CollectionTreeDragRequest) {
                  return _willAcceptRequestIntoFolder(details.data, folder);
                }
                if (details.data is CollectionTreeDragFolder) {
                  return _willAcceptFolderIntoFolder(details.data, folder);
                }
                return false;
              },
              onAcceptWithDetails: (details) async {
                _endTreeDragSession();
                final d = details.data;
                if (d is CollectionTreeDragRequest) {
                  await _relocateRequestIntoFolder(d, folder.uid);
                  AppHaptics.medium();
                } else if (d is CollectionTreeDragFolder) {
                  await _relocateFolderInto(d, folder);
                  AppHaptics.medium();
                }
              },
              builder: (context, candidate, _) {
                final active = candidate.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: active
                        ? Border.all(color: primary, width: 2)
                        : null,
                    color: active ? primary.withValues(alpha: 0.04) : null,
                  ),
                  clipBehavior: active ? Clip.antiAlias : Clip.none,
                  child: folderCore,
                );
              },
            ),
            SizedBox(
              height: _folderSiblingBandHeight,
              child: DragTarget<CollectionTreeDragData>(
                onWillAcceptWithDetails: (details) => _willAcceptFolderSibling(
                  details.data,
                  parentFolderUid,
                  index + 1,
                ),
                onAcceptWithDetails: (details) async {
                  _endTreeDragSession();
                  final d = details.data;
                  if (d is CollectionTreeDragFolder) {
                    await _relocateFolderSibling(
                      d,
                      parentFolderUid,
                      index + 1,
                    );
                    AppHaptics.medium();
                  }
                },
                builder: (context, candidate, _) {
                  final show = candidate.isNotEmpty;
                  return IgnorePointer(
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: show ? primary : const Color(0x00000000),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _rootRequestTile(
    BuildContext context,
    Collection collection,
    int index,
  ) {
    final request = collection.requests[index];
    return _wrapRequestDropTargets(
      context,
      collection: collection,
      parentFolderUid: null,
      rowIndex: index,
      child: _RequestRow(
        key: ValueKey(request.uid),
        request: request,
        collectionUid: widget.uid,
        indent: 0,
        folderUid: null,
        selectionMode: _selectionMode,
        isSelected: _selectedRequestUids().contains(request.uid),
        onToggleSelect: () => _toggleSelectRequest(request.uid),
        dragData: CollectionTreeDragRequest(
          collectionUid: widget.uid,
          request: request,
          fromFolderUid: null,
        ),
        onDragStarted: () => setState(() {
          _draggingData = CollectionTreeDragRequest(
            collectionUid: widget.uid,
            request: request,
            fromFolderUid: null,
          );
        }),
        onDragEnd: _endTreeDragSession,
        onDragCanceled: _endTreeDragSession,
        onDelete: () => _deleteRequest(collection, request, null),
        onDuplicate: () => _duplicateRequest(collection, request, null),
        onRename: () =>
            _showRenameRequestDialog(context, collection, request, null),
        onMove: () => _showMoveDialog(collection, request, null),
        onExportCollectionJson: () => _exportSingleRequest(collection, request),
        onLongPressSelect: () =>
            _longPressEnterSelectionForRequest(request.uid),
      ),
    );
  }

  Widget _folderRequestTile(
    BuildContext context,
    Collection collection,
    Folder folder,
    int indent,
    int reqIndex,
  ) {
    final request = folder.requests[reqIndex];
    return _wrapRequestDropTargets(
      context,
      collection: collection,
      parentFolderUid: folder.uid,
      rowIndex: reqIndex,
      child: _RequestRow(
        key: ValueKey('req_${request.uid}'),
        request: request,
        collectionUid: widget.uid,
        indent: indent,
        folderUid: folder.uid,
        selectionMode: _selectionMode,
        isSelected: _selectedRequestUids().contains(request.uid),
        onToggleSelect: () => _toggleSelectRequest(request.uid),
        dragData: CollectionTreeDragRequest(
          collectionUid: widget.uid,
          request: request,
          fromFolderUid: folder.uid,
        ),
        onDragStarted: () => setState(() {
          _draggingData = CollectionTreeDragRequest(
            collectionUid: widget.uid,
            request: request,
            fromFolderUid: folder.uid,
          );
        }),
        onDragEnd: _endTreeDragSession,
        onDragCanceled: _endTreeDragSession,
        onDelete: () => _deleteRequest(collection, request, folder.uid),
        onDuplicate: () => _duplicateRequest(collection, request, folder.uid),
        onRename: () =>
            _showRenameRequestDialog(context, collection, request, folder.uid),
        onMove: () => _showMoveDialog(collection, request, folder.uid),
        onExportCollectionJson: () => _exportSingleRequest(collection, request),
        onLongPressSelect: () =>
            _longPressEnterSelectionForRequest(request.uid),
      ),
    );
  }

  Widget _wrapRequestDropTargets(
    BuildContext context, {
    required Collection collection,
    required String? parentFolderUid,
    required int rowIndex,
    required Widget child,
  }) {
    if (CollectionTreeDnDScope.maybeDraggingOf(context) == null) {
      return child;
    }
    final primary = CupertinoTheme.of(context).primaryColor;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: DragTarget<CollectionTreeDragData>(
                  onWillAcceptWithDetails: (details) => _willAcceptRequestAt(
                    details.data,
                    parentFolderUid,
                    rowIndex,
                  ),
                  onAcceptWithDetails: (details) async {
                    _endTreeDragSession();
                    final d = details.data;
                    if (d is CollectionTreeDragRequest) {
                      await _relocateRequest(d, parentFolderUid, rowIndex);
                      AppHaptics.medium();
                    }
                  },
                  builder: (context, candidate, _) {
                    final show = candidate.isNotEmpty;
                    return IgnorePointer(
                      child: show
                          ? Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.expand(),
                    );
                  },
                ),
              ),
              Expanded(
                child: DragTarget<CollectionTreeDragData>(
                  onWillAcceptWithDetails: (details) => _willAcceptRequestAt(
                    details.data,
                    parentFolderUid,
                    rowIndex + 1,
                  ),
                  onAcceptWithDetails: (details) async {
                    _endTreeDragSession();
                    final d = details.data;
                    if (d is CollectionTreeDragRequest) {
                      await _relocateRequest(d, parentFolderUid, rowIndex + 1);
                      AppHaptics.medium();
                    }
                  },
                  builder: (context, candidate, _) {
                    final show = candidate.isNotEmpty;
                    return IgnorePointer(
                      child: show
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyRootRequestsDropStrip(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DragTarget<CollectionTreeDragData>(
        onWillAcceptWithDetails: (details) {
          if (details.data is! CollectionTreeDragRequest) return false;
          final d = details.data as CollectionTreeDragRequest;
          return d.fromFolderUid != null;
        },
        onAcceptWithDetails: (details) async {
          _endTreeDragSession();
          final d = details.data;
          if (d is CollectionTreeDragRequest) {
            await _relocateRequest(d, null, 0);
            AppHaptics.medium();
          }
        },
        builder: (context, candidate, _) {
          final active = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? primary : CupertinoColors.separator.resolveFrom(context),
                width: active ? 2 : 0.5,
              ),
              color: active
                  ? primary.withValues(alpha: 0.08)
                  : CupertinoColors.tertiarySystemFill.resolveFrom(context),
            ),
            child: Text(
              'Release to move request to collection root',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: active
                    ? primary
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyFolderRequestsDropStrip(
    BuildContext context,
    Folder folder,
    int indent,
  ) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0 + indent * 20.0,
        right: 16,
        top: 4,
        bottom: 8,
      ),
      child: DragTarget<CollectionTreeDragData>(
        onWillAcceptWithDetails: (details) =>
            _willAcceptRequestIntoFolder(details.data, folder),
        onAcceptWithDetails: (details) async {
          _endTreeDragSession();
          final d = details.data;
          if (d is CollectionTreeDragRequest) {
            await _relocateRequestIntoFolder(d, folder.uid);
            AppHaptics.medium();
          }
        },
        builder: (context, candidate, _) {
          final active = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? primary : CupertinoColors.separator.resolveFrom(context),
                width: active ? 2 : 0.5,
              ),
              color: active
                  ? primary.withValues(alpha: 0.06)
                  : CupertinoColors.tertiarySystemFill.resolveFrom(context),
            ),
            child: Text(
              'Drop requests here',
              style: TextStyle(
                fontSize: 12,
                color: active
                    ? primary
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Collection _collectionSnapshot() {
    final collections = ref.read(collectionsProvider);
    return collections.firstWhere((c) => c.uid == widget.uid);
  }

  int? _requestIndex(Collection c, String requestUid, String? folderUid) {
    if (folderUid == null) {
      final i = c.requests.indexWhere((r) => r.uid == requestUid);
      return i >= 0 ? i : null;
    }
    final f = _findFolderByUid(c.folders, folderUid);
    if (f == null) return null;
    final i = f.requests.indexWhere((r) => r.uid == requestUid);
    return i >= 0 ? i : null;
  }

  int? _folderSiblingIndex(Collection c, String folderUid, String? parentUid) {
    if (parentUid == null) {
      final i = c.folders.indexWhere((f) => f.uid == folderUid);
      return i >= 0 ? i : null;
    }
    final p = _findFolderByUid(c.folders, parentUid);
    if (p == null) return null;
    final i = p.subFolders.indexWhere((f) => f.uid == folderUid);
    return i >= 0 ? i : null;
  }

  Folder? _findFolderByUid(List<Folder> folders, String uid) {
    for (final f in folders) {
      if (f.uid == uid) return f;
      final nested = _findFolderByUid(f.subFolders, uid);
      if (nested != null) return nested;
    }
    return null;
  }

  bool _folderSubtreeContainsUid(Folder root, String uid) {
    if (root.uid == uid) return true;
    for (final s in root.subFolders) {
      if (_folderSubtreeContainsUid(s, uid)) return true;
    }
    return false;
  }

  bool _isTargetInsideDraggedFolderSubtree(
    Collection c,
    String draggedFolderUid,
    String targetFolderUid,
  ) {
    final dragged = _findFolderByUid(c.folders, draggedFolderUid);
    if (dragged == null) return false;
    return _folderSubtreeContainsUid(dragged, targetFolderUid);
  }

  Collection _removeRequestFrom(
    Collection c,
    String requestUid,
    String? folderUid,
  ) {
    if (folderUid == null) {
      return c.copyWith(
        requests: c.requests.where((r) => r.uid != requestUid).toList(),
      );
    }
    return c.copyWith(
      folders: _updateFolderInTree(c.folders, folderUid, (f) {
        return f.copyWith(
          requests: f.requests.where((r) => r.uid != requestUid).toList(),
        );
      }),
    );
  }

  Collection _insertRequestAt(
    Collection c,
    HttpRequest req,
    String? folderUid,
    int index,
  ) {
    if (folderUid == null) {
      final list = [...c.requests];
      list.insert(index.clamp(0, list.length), req);
      return c.copyWith(requests: list);
    }
    return c.copyWith(
      folders: _updateFolderInTree(c.folders, folderUid, (f) {
        final list = [...f.requests];
        list.insert(index.clamp(0, list.length), req);
        return f.copyWith(requests: list);
      }),
    );
  }

  (Folder? removed, List<Folder> tree) _pluckFolderRecursive(
    List<Folder> folders,
    String uid,
  ) {
    for (var i = 0; i < folders.length; i++) {
      if (folders[i].uid == uid) {
        final f = folders[i];
        return (f, [...folders.sublist(0, i), ...folders.sublist(i + 1)]);
      }
      final sub = _pluckFolderRecursive(folders[i].subFolders, uid);
      if (sub.$1 != null) {
        final updated = folders[i].copyWith(subFolders: sub.$2);
        return (
          sub.$1,
          [...folders.sublist(0, i), updated, ...folders.sublist(i + 1)],
        );
      }
    }
    return (null, folders);
  }

  Collection _insertFolderSibling(
    Collection c,
    Folder folder,
    String? parentUid,
    int index,
  ) {
    if (parentUid == null) {
      final list = [...c.folders];
      list.insert(index.clamp(0, list.length), folder);
      return c.copyWith(folders: list);
    }
    return c.copyWith(
      folders: _updateFolderInTree(c.folders, parentUid, (p) {
        final list = [...p.subFolders];
        list.insert(index.clamp(0, list.length), folder);
        return p.copyWith(subFolders: list);
      }),
    );
  }

  Collection _renumberRequestSortOrders(Collection c) {
    final now = DateTime.now();
    Folder walk(Folder f) {
      return f.copyWith(
        requests: [
          for (var i = 0; i < f.requests.length; i++)
            f.requests[i].copyWith(sortOrder: i, updatedAt: now),
        ],
        subFolders: f.subFolders.map(walk).toList(),
        updatedAt: now,
      );
    }

    return c.copyWith(
      requests: [
        for (var i = 0; i < c.requests.length; i++)
          c.requests[i].copyWith(sortOrder: i, updatedAt: now),
      ],
      folders: c.folders.map(walk).toList(),
      updatedAt: now,
    );
  }

  List<Folder> _renumberFolderSiblingOrders(List<Folder> folders) {
    final now = DateTime.now();
    return [
      for (var i = 0; i < folders.length; i++)
        folders[i].copyWith(
          sortOrder: i,
          updatedAt: now,
          subFolders: _renumberFolderSiblingOrders(folders[i].subFolders),
        ),
    ];
  }

  Collection _renumberAllFolderOrders(Collection c) {
    return c.copyWith(folders: _renumberFolderSiblingOrders(c.folders));
  }

  bool _willAcceptRequestAt(
    CollectionTreeDragData? data,
    String? parentFolderUid,
    int rawSlot,
  ) {
    if (data is! CollectionTreeDragRequest) return false;
    final c = _collectionSnapshot();
    final oldIdx = _requestIndex(c, data.request.uid, data.fromFolderUid);
    if (oldIdx == null) return false;
    if (data.fromFolderUid == parentFolderUid) {
      if (rawSlot == oldIdx || rawSlot == oldIdx + 1) return false;
    }
    return true;
  }

  bool _willAcceptFolderSibling(
    CollectionTreeDragData? data,
    String? parentFolderUid,
    int rawSlot,
  ) {
    if (data is! CollectionTreeDragFolder) return false;
    final c = _collectionSnapshot();
    final oldIdx = _folderSiblingIndex(c, data.folder.uid, data.parentFolderUid);
    if (oldIdx == null) return false;
    if (data.parentFolderUid == parentFolderUid) {
      if (rawSlot == oldIdx || rawSlot == oldIdx + 1) return false;
    }
    return true;
  }

  bool _willAcceptRequestIntoFolder(
    CollectionTreeDragData? data,
    Folder target,
  ) {
    return data is CollectionTreeDragRequest;
  }

  bool _willAcceptFolderIntoFolder(
    CollectionTreeDragData? data,
    Folder target,
  ) {
    if (data is! CollectionTreeDragFolder) return false;
    final d = data;
    final c = _collectionSnapshot();
    if (d.folder.uid == target.uid) return false;
    return !_isTargetInsideDraggedFolderSubtree(c, d.folder.uid, target.uid);
  }

  Future<void> _relocateRequest(
    CollectionTreeDragRequest drag,
    String? toFolderUid,
    int rawSlot,
  ) async {
    var c = _collectionSnapshot();
    final fromFolder = drag.fromFolderUid;
    final uid = drag.request.uid;

    final oldIdx = _requestIndex(c, uid, fromFolder);
    if (oldIdx == null) return;

    final sameParent = fromFolder == toFolderUid;
    var moved = drag.request.copyWith(
      folderUid: toFolderUid,
      collectionUid: c.uid,
      updatedAt: DateTime.now(),
    );

    var next = _removeRequestFrom(c, uid, fromFolder);

    var insertAt = rawSlot;
    if (sameParent) {
      if (oldIdx < rawSlot) insertAt = rawSlot - 1;
    }
    final destLen = toFolderUid == null
        ? next.requests.length
        : (_findFolderByUid(next.folders, toFolderUid)?.requests.length ?? 0);
    insertAt = insertAt.clamp(0, destLen);

    next = _insertRequestAt(next, moved, toFolderUid, insertAt);
    next = _renumberRequestSortOrders(next);

    if (toFolderUid != null) {
      setState(() => _expandedFolders.add(toFolderUid));
    }
    await ref.read(collectionsProvider.notifier).update(next);
  }

  Future<void> _relocateRequestIntoFolder(
    CollectionTreeDragRequest drag,
    String targetFolderUid,
  ) async {
    var c = _collectionSnapshot();
    final fromFolder = drag.fromFolderUid;
    final uid = drag.request.uid;

    final oldIdx = _requestIndex(c, uid, fromFolder);
    if (oldIdx == null) return;

    var next = _removeRequestFrom(c, uid, fromFolder);
    final host = _findFolderByUid(next.folders, targetFolderUid);
    if (host == null) return;

    final insertAt = host.requests.length;
    final moved = drag.request.copyWith(
      folderUid: targetFolderUid,
      collectionUid: c.uid,
      updatedAt: DateTime.now(),
    );

    next = _insertRequestAt(next, moved, targetFolderUid, insertAt);
    next = _renumberRequestSortOrders(next);

    setState(() => _expandedFolders.add(targetFolderUid));
    await ref.read(collectionsProvider.notifier).update(next);
  }

  Future<void> _relocateFolderSibling(
    CollectionTreeDragFolder drag,
    String? newParentUid,
    int rawSlot,
  ) async {
    var c = _collectionSnapshot();
    final uid = drag.folder.uid;
    final fromParent = drag.parentFolderUid;

    final oldIdx = _folderSiblingIndex(c, uid, fromParent);
    if (oldIdx == null) return;

    final plucked = _pluckFolderRecursive(c.folders, uid);
    if (plucked.$1 == null) return;
    var next = c.copyWith(folders: plucked.$2);
    var moved = plucked.$1!.copyWith(
      parentFolderUid: newParentUid,
      updatedAt: DateTime.now(),
    );

    var insertAt = rawSlot;
    if (fromParent == newParentUid) {
      if (oldIdx < rawSlot) insertAt = rawSlot - 1;
    }
    final destCount = newParentUid == null
        ? next.folders.length
        : (_findFolderByUid(next.folders, newParentUid)?.subFolders.length ?? 0);
    insertAt = insertAt.clamp(0, destCount);

    next = _insertFolderSibling(next, moved, newParentUid, insertAt);
    next = _renumberAllFolderOrders(next);
    next = _renumberRequestSortOrders(next);

    await ref.read(collectionsProvider.notifier).update(next);
  }

  Future<void> _relocateFolderInto(
    CollectionTreeDragFolder drag,
    Folder targetFolder,
  ) async {
    var c = _collectionSnapshot();
    final uid = drag.folder.uid;
    if (uid == targetFolder.uid) return;
    if (_isTargetInsideDraggedFolderSubtree(c, uid, targetFolder.uid)) return;

    final plucked = _pluckFolderRecursive(c.folders, uid);
    if (plucked.$1 == null) return;
    var next = c.copyWith(folders: plucked.$2);
    final moved = plucked.$1!.copyWith(
      parentFolderUid: targetFolder.uid,
      updatedAt: DateTime.now(),
    );

    final host = _findFolderByUid(next.folders, targetFolder.uid);
    if (host == null) return;
    final insertAt = host.subFolders.length;

    next = _insertFolderSibling(next, moved, targetFolder.uid, insertAt);
    next = _renumberAllFolderOrders(next);
    next = _renumberRequestSortOrders(next);

    setState(() => _expandedFolders.add(targetFolder.uid));
    await ref.read(collectionsProvider.notifier).update(next);
  }

  // ── Folder CRUD ──────────────────────────────────────────────────────────────

  Future<void> _showCreateFolderDialog(
    BuildContext context,
    Collection collection, {
    required String? parentUid,
  }) async {
    final controller = TextEditingController();
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(parentUid == null ? 'New Folder' : 'New Sub-folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Folder name',
            autofocus: true,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(ctx),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final now = DateTime.now();
    final folder = Folder(
      uid: _uuid.v4(),
      name: name,
      collectionUid: collection.uid,
      parentFolderUid: parentUid,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    late Collection updated;
    if (parentUid == null) {
      updated = collection.copyWith(
        folders: [...collection.folders, folder],
      );
    } else {
      updated = collection.copyWith(
        folders: _updateFolderInTree(
          collection.folders,
          parentUid,
          (f) => f.copyWith(subFolders: [...f.subFolders, folder]),
        ),
      );
      // Ensure parent is expanded so the new sub-folder is visible
      setState(() => _expandedFolders.add(parentUid));
    }

    await ref.read(collectionsProvider.notifier).update(updated);
    setState(() => _expandedFolders.add(folder.uid));
  }

  Future<void> _showRenameFolderDialog(
    BuildContext context,
    Collection collection,
    Folder folder,
  ) async {
    final controller = TextEditingController(text: folder.name);
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Rename Folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Folder name',
            autofocus: true,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(ctx),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final updated = collection.copyWith(
      folders: _updateFolderInTree(
        collection.folders,
        folder.uid,
        (f) => f.copyWith(name: name),
      ),
    );
    await ref.read(collectionsProvider.notifier).update(updated);
  }

  Future<void> _deleteFolder(
    Collection collection,
    Folder folder,
  ) async {
    final totalRequests = _countRequests(folder);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          totalRequests > 0
              ? 'Delete "${folder.name}" and its $totalRequests request(s)?'
              : 'Delete "${folder.name}"?',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final updated = collection.copyWith(
      folders: _removeFolderFromTree(collection.folders, folder.uid),
    );
    await ref.read(collectionsProvider.notifier).update(updated);
    setState(() => _expandedFolders.remove(folder.uid));
  }

  int _countRequests(Folder folder) {
    var count = folder.requests.length;
    for (final sub in folder.subFolders) {
      count += _countRequests(sub);
    }
    return count;
  }

  // ── Request CRUD ─────────────────────────────────────────────────────────────

  Future<void> _deleteRequest(
    Collection collection,
    HttpRequest request,
    String? folderUid,
  ) async {
    late Collection updated;
    if (folderUid == null) {
      updated = collection.copyWith(
        requests:
            collection.requests.where((r) => r.uid != request.uid).toList(),
      );
    } else {
      updated = collection.copyWith(
        folders: _updateFolderInTree(
          collection.folders,
          folderUid,
          (f) => f.copyWith(
            requests:
                f.requests.where((r) => r.uid != request.uid).toList(),
          ),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updated);
  }

  Future<void> _duplicateRequest(
    Collection collection,
    HttpRequest request,
    String? folderUid,
  ) async {
    final now = DateTime.now();
    final copy = request.copyWith(
      uid: _uuid.v4(),
      name: '${request.name} (copy)',
      createdAt: now,
      updatedAt: now,
    );
    late Collection updated;
    if (folderUid == null) {
      updated =
          collection.copyWith(requests: [...collection.requests, copy]);
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
  }

  Future<void> _showRenameRequestDialog(
    BuildContext context,
    Collection collection,
    HttpRequest request,
    String? folderUid,
  ) async {
    final controller = TextEditingController(text: request.name);
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Rename Request'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Request name',
            autofocus: true,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(ctx),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final renamed = request.copyWith(name: name);
    late Collection updated;
    if (folderUid == null) {
      updated = collection.copyWith(
        requests: collection.requests
            .map((r) => r.uid == request.uid ? renamed : r)
            .toList(),
      );
    } else {
      updated = collection.copyWith(
        folders: _updateFolderInTree(
          collection.folders,
          folderUid,
          (f) => f.copyWith(
            requests: f.requests
                .map((r) => r.uid == request.uid ? renamed : r)
                .toList(),
          ),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updated);
  }

  // ── Move request ─────────────────────────────────────────────────────────────

  Future<void> _showMoveDialog(
    Collection collection,
    HttpRequest request,
    String? fromFolderUid,
  ) async {
    final dests = _buildMoveDestinations(collection.uid, fromFolderUid);
    if (dests.isEmpty) return;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.55,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(ctx),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.separator.resolveFrom(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Text(
                      'Move to',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
              Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(ctx)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: dests.length,
                  separatorBuilder: (_, __) => Container(
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 52),
                    color: CupertinoColors.separator.resolveFrom(ctx),
                  ),
                  itemBuilder: (_, i) {
                    final dest = dests[i];
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _moveRequest(collection, request, fromFolderUid,
                            dest.collectionUid, dest.folderUid);
                      },
                      child: Row(
                        children: [
                          Icon(
                            dest.folderUid == null
                                ? CupertinoIcons.tray
                                : CupertinoIcons.folder_fill,
                            size: 18,
                            color: dest.folderUid == null
                                ? CupertinoColors.secondaryLabel
                                    .resolveFrom(ctx)
                                : CupertinoTheme.of(ctx).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dest.label,
                              style: TextStyle(
                                fontSize: 15,
                                color:
                                    CupertinoColors.label.resolveFrom(ctx),
                              ),
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
        );
      },
    );
  }

  List<_MoveDest> _buildMoveDestinations(
    String currentCollectionUid,
    String? currentFolderUid,
  ) {
    final collections = ref.read(collectionsProvider);
    final dests = <_MoveDest>[];
    for (final col in collections) {
      dests.add((
        collectionUid: col.uid,
        folderUid: null,
        label: col.name,
      ));
      _addFolderDests(dests, col.folders, col.uid, '');
    }
    // Exclude current location
    return dests
        .where((d) =>
            !(d.collectionUid == currentCollectionUid &&
              d.folderUid == currentFolderUid))
        .toList();
  }

  void _addFolderDests(
    List<_MoveDest> list,
    List<Folder> folders,
    String collectionUid,
    String prefix,
  ) {
    for (final f in folders) {
      final label = prefix.isEmpty ? f.name : '$prefix / ${f.name}';
      list.add((
        collectionUid: collectionUid,
        folderUid: f.uid,
        label: label,
      ));
      _addFolderDests(list, f.subFolders, collectionUid, label);
    }
  }

  Future<void> _moveRequest(
    Collection sourceCollection,
    HttpRequest request,
    String? fromFolderUid,
    String toCollectionUid,
    String? toFolderUid,
  ) async {
    final collections = ref.read(collectionsProvider);
    final now = DateTime.now();
    final movedRequest = request.copyWith(
      collectionUid: toCollectionUid,
      folderUid: toFolderUid,
      updatedAt: now,
    );

    // Remove from source
    Collection removedSrc;
    if (fromFolderUid == null) {
      removedSrc = sourceCollection.copyWith(
        requests: sourceCollection.requests
            .where((r) => r.uid != request.uid)
            .toList(),
      );
    } else {
      removedSrc = sourceCollection.copyWith(
        folders: _updateFolderInTree(
          sourceCollection.folders,
          fromFolderUid,
          (f) => f.copyWith(
            requests:
                f.requests.where((r) => r.uid != request.uid).toList(),
          ),
        ),
      );
    }

    if (sourceCollection.uid == toCollectionUid) {
      // Same collection — work on the already-pruned copy
      final Collection addedDst;
      if (toFolderUid == null) {
        addedDst = removedSrc.copyWith(
            requests: [...removedSrc.requests, movedRequest]);
      } else {
        addedDst = removedSrc.copyWith(
          folders: _updateFolderInTree(
            removedSrc.folders,
            toFolderUid,
            (f) => f.copyWith(requests: [...f.requests, movedRequest]),
          ),
        );
      }
      // Expand destination folder so user sees the moved request
      if (toFolderUid != null) {
        setState(() => _expandedFolders.add(toFolderUid));
      }
      await ref.read(collectionsProvider.notifier).update(addedDst);
    } else {
      // Cross-collection
      final destCollection =
          collections.firstWhere((c) => c.uid == toCollectionUid);
      final Collection addedDst;
      if (toFolderUid == null) {
        addedDst = destCollection.copyWith(
            requests: [...destCollection.requests, movedRequest]);
      } else {
        addedDst = destCollection.copyWith(
          folders: _updateFolderInTree(
            destCollection.folders,
            toFolderUid,
            (f) => f.copyWith(requests: [...f.requests, movedRequest]),
          ),
        );
      }
      await ref.read(collectionsProvider.notifier).update(removedSrc);
      await ref.read(collectionsProvider.notifier).update(addedDst);
    }
  }
}

class _FolderDragFeedbackCard extends StatelessWidget {
  const _FolderDragFeedbackCard({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.88,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.folder_fill,
                color: CupertinoTheme.of(context).primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

class _RequestDragFeedbackCard extends StatelessWidget {
  const _RequestDragFeedbackCard({required this.request});

  final HttpRequest request;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.88,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MethodBadge(method: request.method.value),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  request.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

// ── _FolderHeader ─────────────────────────────────────────────────────────────

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    required this.folder,
    required this.isExpanded,
    required this.indent,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelect,
    required this.dragData,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragCanceled,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    required this.onAddRequest,
    required this.onAddSubFolder,
    required this.onImportCollectionJson,
    required this.onExportFolder,
    required this.onLongPressSelect,
  });

  final Folder folder;
  final bool isExpanded;
  final int indent;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final CollectionTreeDragFolder dragData;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCanceled;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAddRequest;
  final VoidCallback onAddSubFolder;
  final VoidCallback onImportCollectionJson;
  final VoidCallback onExportFolder;
  final VoidCallback onLongPressSelect;

  @override
  Widget build(BuildContext context) {
    final directCount = folder.requests.length;
    final hasSubFolders = folder.subFolders.isNotEmpty;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
      padding: EdgeInsets.only(
        left: 16.0 + indent * 20.0,
        right: 8,
        top: 10,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (selectionMode) ...[
            CupertinoButton(
              padding: const EdgeInsets.only(right: 2),
              minimumSize: const Size(36, 36),
              onPressed: onToggleSelect,
              child: Icon(
                isSelected
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                size: 22,
                color: isSelected
                    ? CupertinoTheme.of(context).primaryColor
                    : secondary,
              ),
            ),
          ],
          Expanded(
            child: selectionMode
                ? GestureDetector(
                    onTap: onToggleSelect,
                    onLongPress: onLongPressSelect,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 32),
                          onPressed: onToggle,
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded
                              ? CupertinoIcons.folder_open
                              : CupertinoIcons.folder_fill,
                          size: 16,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            folder.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasSubFolders || directCount > 0)
                          Text(
                            hasSubFolders
                                ? '${folder.subFolders.length}f · ${directCount}r'
                                : '$directCount',
                            style: TextStyle(
                              fontSize: 11,
                              color: secondary,
                            ),
                          ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: onToggle,
                    onLongPress: onLongPressSelect,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            CupertinoIcons.chevron_right,
                            size: 14,
                            color: secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded
                              ? CupertinoIcons.folder_open
                              : CupertinoIcons.folder_fill,
                          size: 16,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            folder.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasSubFolders || directCount > 0)
                          Text(
                            hasSubFolders
                                ? '${folder.subFolders.length}f · ${directCount}r'
                                : '$directCount',
                            style: TextStyle(
                              fontSize: 11,
                              color: secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          if (!selectionMode)
            LongPressDraggable<CollectionTreeDragData>(
              data: dragData,
              hapticFeedbackOnStart: true,
              onDragStarted: onDragStarted,
              onDragEnd: (_) => onDragEnd(),
              onDraggableCanceled: (_, __) => onDragCanceled(),
              feedback: _FolderDragFeedbackCard(folder: folder),
              childWhenDragging: Padding(
                padding: const EdgeInsets.only(left: 4, right: 2),
                child: Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 18,
                  color: CupertinoColors.tertiaryLabel
                      .resolveFrom(context)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 2),
                child: Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 18,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ),
          if (!selectionMode)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => _showContextMenu(context),
              child: Icon(
                CupertinoIcons.ellipsis_circle,
                size: 18,
                color: secondary,
              ),
            ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(folder.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onAddRequest();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.add_circled),
                SizedBox(width: 8),
                Text('Add Request'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onAddSubFolder();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder_badge_plus),
                SizedBox(width: 8),
                Text('Add Sub-folder'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onRename();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onImportCollectionJson();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_down_doc),
                SizedBox(width: 8),
                Text('Import collection JSON…'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onExportFolder();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share_up),
                SizedBox(width: 8),
                Text('Export collection JSON…'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.destructiveRed.resolveFrom(ctx),
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete Folder',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed.resolveFrom(ctx),
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ── _RequestRow ───────────────────────────────────────────────────────────────

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    super.key,
    required this.request,
    required this.collectionUid,
    required this.indent,
    required this.folderUid,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelect,
    required this.dragData,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragCanceled,
    required this.onDelete,
    required this.onDuplicate,
    required this.onRename,
    required this.onMove,
    required this.onExportCollectionJson,
    required this.onLongPressSelect,
  });

  final HttpRequest request;
  final String collectionUid;
  final int indent;
  final String? folderUid;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final CollectionTreeDragRequest dragData;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCanceled;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onExportCollectionJson;
  final VoidCallback onLongPressSelect;

  void _showRequestContextMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(request.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onRename();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onMove();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_right_arrow_left),
                SizedBox(width: 8),
                Text('Move'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onDuplicate();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_on_doc),
                SizedBox(width: 8),
                Text('Duplicate'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onExportCollectionJson();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share_up),
                SizedBox(width: 8),
                Text('Export collection JSON…'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.destructiveRed.resolveFrom(ctx),
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed.resolveFrom(ctx),
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Slidable(
      key: ValueKey(request.uid),
      enabled: !selectionMode,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.94,
        children: [
          SlidableAction(
            onPressed: (_) => onRename(),
            backgroundColor: CupertinoColors.systemBlue,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.pencil,
            spacing: 2,
            label: 'Rename',
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
          SlidableAction(
            onPressed: (_) => onMove(),
            backgroundColor: CupertinoColors.systemOrange,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.arrow_right_arrow_left,
            spacing: 2,
            label: 'Move',
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
          SlidableAction(
            onPressed: (_) => onDuplicate(),
            backgroundColor: CupertinoColors.systemIndigo,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.doc_on_doc,
            spacing: 2,
            label: 'Copy',
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: CupertinoColors.destructiveRed,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.trash,
            spacing: 2,
            label: 'Delete',
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + indent * 20.0,
          right: 8,
          top: 10,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selectionMode)
              CupertinoButton(
                padding: const EdgeInsets.only(right: 2),
                minimumSize: const Size(36, 36),
                onPressed: onToggleSelect,
                child: Icon(
                  isSelected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  size: 22,
                  color: isSelected
                      ? CupertinoTheme.of(context).primaryColor
                      : secondary,
                ),
              ),
            Expanded(
              child: GestureDetector(
                onTap: selectionMode
                    ? onToggleSelect
                    : () => context.push(
                          '/collections/$collectionUid/request/${request.uid}',
                        ),
                onLongPress: onLongPressSelect,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    MethodBadge(method: request.method.value),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (request.url.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              request.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                color: secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!selectionMode)
              LongPressDraggable<CollectionTreeDragData>(
                data: dragData,
                hapticFeedbackOnStart: true,
                onDragStarted: onDragStarted,
                onDragEnd: (_) => onDragEnd(),
                onDraggableCanceled: (_, __) => onDragCanceled(),
                feedback: _RequestDragFeedbackCard(request: request),
                childWhenDragging: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    CupertinoIcons.line_horizontal_3,
                    size: 18,
                    color: CupertinoColors.tertiaryLabel
                        .resolveFrom(context)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    CupertinoIcons.line_horizontal_3,
                    size: 18,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            if (!selectionMode)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
                onPressed: () => _showRequestContextMenu(context),
                child: Icon(
                  CupertinoIcons.ellipsis_circle,
                  size: 18,
                  color: secondary,
                ),
              ),
            if (!selectionMode)
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
          ],
        ),
      ),
    );
  }
}
