import 'dart:io';

import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/theme/app_colors.dart';
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
import 'package:aun_reqstudio/features/collections/widgets/collection_tree_dnd.dart';
import 'package:aun_reqstudio/features/collections/widgets/method_badge.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

typedef _MoveDest = ({String collectionUid, String? folderUid, String label});

/// Material 3 equivalent of [CollectionDetailScreen].
///
/// [isEmbedded] — when `true` the widget renders without its own [Scaffold],
/// suitable for use as the right pane of a tablet two-pane layout.
class CollectionDetailScreenMaterial extends ConsumerStatefulWidget {
  const CollectionDetailScreenMaterial({
    super.key,
    required this.uid,
    this.isEmbedded = false,
  });

  final String uid;
  final bool isEmbedded;

  @override
  ConsumerState<CollectionDetailScreenMaterial> createState() =>
      _CollectionDetailScreenMaterialState();
}

class _CollectionDetailScreenMaterialState
    extends ConsumerState<CollectionDetailScreenMaterial> {
  static const _uuid = Uuid();

  final Set<String> _expandedFolders = {};
  CollectionTreeDragData? _draggingData;
  bool _selectionMode = false;
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
      final safe = title
          .replaceAll(RegExp(r'[^\w\s.-]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/$safe.json');
      await file.writeAsString(json);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '$title — AUN - ReqStudio',
      );
      _exitSelectionMode();
    } catch (e) {
      if (!mounted) return;
      UserNotification.show(context: context, title: 'Export', body: e.toString());
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
      body = 'Delete $nFolders folder(s) ($reqsInsideFolders request(s) inside) '
          'and $nLoose other request(s)? This cannot be undone.';
    } else if (nFolders > 0) {
      body = nFolders == 1
          ? 'Delete "${folders.first.name}" and $reqsInsideFolders request(s)? This cannot be undone.'
          : 'Delete $nFolders folders ($reqsInsideFolders request(s) inside)? This cannot be undone.';
    } else if (nLoose == 1) {
      body = 'Delete "${requests.first.name}"? This cannot be undone.';
    } else {
      body = 'Delete $nLoose requests? This cannot be undone.';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected'),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
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

  Future<void> _exportSingleFolder(
      Collection collection, Folder folder) async {
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
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '${folder.name} — AUN - ReqStudio',
      );
    } catch (e) {
      if (!mounted) return;
      UserNotification.show(context: context, title: 'Export', body: e.toString());
    }
  }

  Future<void> _exportSingleRequest(
      Collection collection, HttpRequest request) async {
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
      final file = File('${dir.path}/$safe.json');
      await file.writeAsString(json);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '${request.name} — AUN - ReqStudio',
      );
    } catch (e) {
      if (!mounted) return;
      UserNotification.show(context: context, title: 'Export', body: e.toString());
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
              .map((k) => EnvironmentVariable(uid: _uuid.v4(), key: k, value: ''))
              .toList(),
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(environmentsProvider.notifier).importEnvironment(environment);
        if (mounted) {
          UserNotification.show(
            context: context,
            title: 'Import',
            body: 'Merged ${fragment.folders.length} folder(s), '
                '${fragment.rootRequests.length} request(s). '
                'Created environment with ${varNames.length} variables.',
          );
        }
      } else if (mounted) {
        UserNotification.show(
          context: context,
          title: 'Import',
          body: 'Merged ${fragment.folders.length} folder(s), '
              '${fragment.rootRequests.length} request(s).',
        );
      }
    } catch (e) {
      if (!mounted) return;
      UserNotification.show(context: context, title: 'Import', body: e.toString());
    }
  }

  void _endTreeDragSession() {
    if (!mounted) return;
    if (_draggingData == null) return;
    setState(() => _draggingData = null);
  }

  // ── Tree helpers ──────────────────────────────────────────────────────────

  List<Folder> _updateFolderInTree(
    List<Folder> folders,
    String uid,
    Folder Function(Folder) updater,
  ) {
    return folders.map((f) {
      if (f.uid == uid) return updater(f);
      return f.copyWith(subFolders: _updateFolderInTree(f.subFolders, uid, updater));
    }).toList();
  }

  List<Folder> _removeFolderFromTree(List<Folder> folders, String uid) {
    return folders
        .where((f) => f.uid != uid)
        .map((f) => f.copyWith(subFolders: _removeFolderFromTree(f.subFolders, uid)))
        .toList();
  }

  Folder? _findFolderByUid(List<Folder> folders, String uid) {
    for (final f in folders) {
      if (f.uid == uid) return f;
      final found = _findFolderByUid(f.subFolders, uid);
      if (found != null) return found;
    }
    return null;
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
          (_draggingData! as CollectionTreeDragRequest).fromFolderUid != null) ...[
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final collection = collections.where((c) => c.uid == widget.uid).firstOrNull;

    if (collection == null) {
      if (!widget.isEmbedded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pop();
        });
      }
      return const Center(child: CircularProgressIndicator());
    }

    final descriptionText = collection.description?.trim();
    final isEmpty = collection.requests.isEmpty && collection.folders.isEmpty;
    final effectiveSelectionCount =
        _selectionMode ? _buildFragmentExportEntries(collection).length : 0;

    // Build AppBar for non-embedded mode
    final nonEmbeddedAppBar = AppBar(
      title: Text(
        collection.name,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      leading: _selectionMode
          ? TextButton(
              onPressed: _exitSelectionMode,
              child: const Text('Cancel'),
            )
          : null,
      actions: _selectionMode
          ? [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: effectiveSelectionCount == 0
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.38)
                      : Colors.red,
                ),
                onPressed: effectiveSelectionCount == 0
                    ? null
                    : () => _confirmAndDeleteSelection(collection),
                child: const Text('Delete'),
              ),
            ]
          : [
              IconButton(
                tooltip: 'Select items',
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => setState(() {
                  _selectionMode = true;
                  _draggingData = null;
                }),
              ),
              IconButton(
                tooltip: 'Add request',
                icon: const Icon(Icons.add),
                onPressed: () =>
                    context.push('/collections/${widget.uid}/request/new'),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More options',
                onSelected: (value) {
                  switch (value) {
                    case 'import':
                      _importCollectionFragment(
                        collection,
                        parentFolderUid: null,
                      );
                    case 'new_folder':
                      _showCreateFolderDialog(context, collection, parentUid: null);
                    case 'auth':
                      context.push(
                        '${AppRoutes.collections}/${widget.uid}/auth',
                      );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'new_folder',
                    child: ListTile(
                      leading: Icon(Icons.create_new_folder_outlined),
                      title: Text('New folder'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'import',
                    child: ListTile(
                      leading: Icon(Icons.file_download_outlined),
                      title: Text('Import collection JSON'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'auth',
                    child: ListTile(
                      leading: Icon(Icons.lock_outlined),
                      title: Text('Collection auth'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
    );

    // Build AppBar for embedded mode
    final embeddedAppBar = AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        collection.name,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      actions: _selectionMode
          ? [
              TextButton(
                onPressed: _exitSelectionMode,
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: effectiveSelectionCount == 0
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.38)
                      : Colors.red,
                ),
                onPressed: effectiveSelectionCount == 0
                    ? null
                    : () => _confirmAndDeleteSelection(collection),
                child: const Text('Delete'),
              ),
            ]
          : [
              IconButton(
                tooltip: 'Select',
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => setState(() {
                  _selectionMode = true;
                  _draggingData = null;
                }),
              ),
              IconButton(
                tooltip: 'Add request',
                icon: const Icon(Icons.add),
                onPressed: () =>
                    context.push('/collections/${widget.uid}/request/new'),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More options',
                onSelected: (value) {
                  switch (value) {
                    case 'import':
                      _importCollectionFragment(
                        collection,
                        parentFolderUid: null,
                      );
                    case 'new_folder':
                      _showCreateFolderDialog(context, collection, parentUid: null);
                    case 'auth':
                      context.push(
                        '${AppRoutes.collections}/${widget.uid}/auth',
                      );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'new_folder',
                    child: ListTile(
                      leading: Icon(Icons.create_new_folder_outlined),
                      title: Text('New folder'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'import',
                    child: ListTile(
                      leading: Icon(Icons.file_download_outlined),
                      title: Text('Import collection JSON'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'auth',
                    child: ListTile(
                      leading: Icon(Icons.lock_outlined),
                      title: Text('Collection auth'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
    );

    final bodyContent = Column(
      children: [
        if (descriptionText != null && descriptionText.isNotEmpty)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _selectionMode ? _exitSelectionMode : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                descriptionText,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        if (isEmpty)
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
                              color: AppColors.seedColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.api_outlined,
                              size: 36,
                              color: AppColors.seedColor,
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
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width - 48,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppGradientButton.materialSecondary(
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
                                      Icon(Icons.create_new_folder_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('New Folder'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppGradientButton.material(
                                  fullWidth: true,
                                  onPressed: () => context.push(
                                    '/collections/${widget.uid}/request/new',
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 18),
                                      SizedBox(width: 8),
                                      Text('Add Request'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppGradientButton.materialSecondary(
                                  fullWidth: true,
                                  onPressed: () => _importCollectionFragment(
                                    collection,
                                    parentFolderUid: null,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.file_download_outlined, size: 18),
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
                )
        else
          Expanded(
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
                SizedBox(height: _selectionMode ? 0 : MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        if (_selectionMode) _selectionBottomBar(context, collection),
      ],
    );

    final body = widget.isEmbedded
        ? Column(
            children: [embeddedAppBar, Expanded(child: bodyContent)],
          )
        : bodyContent;

    if (widget.isEmbedded) return body;

    return Scaffold(
      appBar: nonEmbeddedAppBar,
      body: body,
    );
  }

  Widget _selectionBottomBar(BuildContext context, Collection collection) {
    final effective = _buildFragmentExportEntries(collection).length;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, 6, 12, bottomInset + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: 52,
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
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Text(
                  '${_selectionOrder.length} selected',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: effective == 0
                  ? AppGradientButton.materialSecondary(
                      onPressed: null,
                      child: const Text('Export'),
                    )
                  : AppGradientButton.material(
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

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  // ── Folder DnD tree ───────────────────────────────────────────────────────

  static const _folderSiblingBandHeight = 16.0;

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

        final header = _FolderHeaderMaterial(
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
          onRename: () => _showRenameFolderDialog(context, collection, folder),
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
          onLongPressSelect: () => _longPressEnterSelectionForFolder(folder.uid),
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
                    _emptyFolderRequestsDropStrip(context, folder, indent + 1),
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

        final primary = Theme.of(context).colorScheme.primary;

        if (CollectionTreeDnDScope.maybeDraggingOf(context) == null) {
          return Column(
            key: ValueKey('folder_branch_${folder.uid}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [folderCore],
          );
        }

        return Column(
          key: ValueKey('folder_branch_${folder.uid}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _folderSiblingBandHeight,
              child: DragTarget<CollectionTreeDragData>(
                onWillAcceptWithDetails: (details) =>
                    _willAcceptFolderSibling(details.data, parentFolderUid, index),
                onAcceptWithDetails: (details) async {
                  _endTreeDragSession();
                  final d = details.data;
                  if (d is CollectionTreeDragFolder) {
                    await _relocateFolderSibling(d, parentFolderUid, index);
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
                    border: active ? Border.all(color: primary, width: 2) : null,
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
                onWillAcceptWithDetails: (details) =>
                    _willAcceptFolderSibling(details.data, parentFolderUid, index + 1),
                onAcceptWithDetails: (details) async {
                  _endTreeDragSession();
                  final d = details.data;
                  if (d is CollectionTreeDragFolder) {
                    await _relocateFolderSibling(d, parentFolderUid, index + 1);
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

  Widget _rootRequestTile(BuildContext context, Collection collection, int index) {
    final request = collection.requests[index];
    return _wrapRequestDropTargets(
      context,
      collection: collection,
      parentFolderUid: null,
      rowIndex: index,
      child: _RequestRowMaterial(
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
        onRename: () => _showRenameRequestDialog(context, collection, request, null),
        onMove: () => _showMoveDialog(collection, request, null),
        onExportCollectionJson: () => _exportSingleRequest(collection, request),
        onLongPressSelect: () => _longPressEnterSelectionForRequest(request.uid),
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
      child: _RequestRowMaterial(
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
        onLongPressSelect: () => _longPressEnterSelectionForRequest(request.uid),
      ),
    );
  }

  Widget _emptyRootRequestsDropStrip(BuildContext context) {
    return DragTarget<CollectionTreeDragData>(
      onWillAcceptWithDetails: (d) =>
          d.data is CollectionTreeDragRequest &&
          (d.data as CollectionTreeDragRequest).fromFolderUid != null,
      onAcceptWithDetails: (details) async {
        _endTreeDragSession();
        if (details.data is CollectionTreeDragRequest) {
          await _relocateRequest(details.data as CollectionTreeDragRequest, null, 0);
          AppHaptics.medium();
        }
      },
      builder: (context, candidate, _) => Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: candidate.isNotEmpty
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: candidate.isNotEmpty ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            'Drop here',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyFolderRequestsDropStrip(
    BuildContext context,
    Folder folder,
    int indent,
  ) {
    return DragTarget<CollectionTreeDragData>(
      onWillAcceptWithDetails: (d) => d.data is CollectionTreeDragRequest,
      onAcceptWithDetails: (details) async {
        _endTreeDragSession();
        if (details.data is CollectionTreeDragRequest) {
          await _relocateRequestIntoFolder(
              details.data as CollectionTreeDragRequest, folder.uid);
          AppHaptics.medium();
        }
      },
      builder: (context, candidate, _) => Padding(
        padding: EdgeInsets.only(left: 16.0 + indent * 20.0, right: 16),
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: candidate.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: candidate.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              'Drop into folder',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
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
    if (CollectionTreeDnDScope.maybeDraggingOf(context) == null) return child;
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: DragTarget<CollectionTreeDragData>(
                  onWillAcceptWithDetails: (details) =>
                      _willAcceptRequestAt(details.data, parentFolderUid, rowIndex),
                  onAcceptWithDetails: (details) async {
                    _endTreeDragSession();
                    if (details.data is CollectionTreeDragRequest) {
                      await _relocateRequest(
                          details.data as CollectionTreeDragRequest,
                          parentFolderUid,
                          rowIndex);
                      AppHaptics.medium();
                    }
                  },
                  builder: (context, candidate, _) => IgnorePointer(
                    child: candidate.isNotEmpty
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  ),
                ),
              ),
              Expanded(
                child: DragTarget<CollectionTreeDragData>(
                  onWillAcceptWithDetails: (details) => _willAcceptRequestAt(
                      details.data, parentFolderUid, rowIndex + 1),
                  onAcceptWithDetails: (details) async {
                    _endTreeDragSession();
                    if (details.data is CollectionTreeDragRequest) {
                      await _relocateRequest(
                          details.data as CollectionTreeDragRequest,
                          parentFolderUid,
                          rowIndex + 1);
                      AppHaptics.medium();
                    }
                  },
                  builder: (context, candidate, _) => IgnorePointer(
                    child: candidate.isNotEmpty
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Folder CRUD ───────────────────────────────────────────────────────────

  Future<void> _showCreateFolderDialog(
    BuildContext context,
    Collection collection, {
    required String? parentUid,
  }) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final now = DateTime.now();
    final newFolder = Folder(
      uid: _uuid.v4(),
      name: name,
      requests: [],
      subFolders: [],
      parentFolderUid: parentUid,
      collectionUid: collection.uid,
      createdAt: now,
      updatedAt: now,
    );

    late final Collection updated;
    if (parentUid == null) {
      updated = collection.copyWith(folders: [...collection.folders, newFolder]);
    } else {
      updated = collection.copyWith(
        folders: _updateFolderInTree(
          collection.folders,
          parentUid,
          (f) => f.copyWith(subFolders: [...f.subFolders, newFolder]),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updated);
    setState(() => _expandedFolders.add(newFolder.uid));
  }

  Future<void> _showRenameFolderDialog(
    BuildContext context,
    Collection collection,
    Folder folder,
  ) async {
    final controller = TextEditingController(text: folder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
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

  Future<void> _deleteFolder(Collection collection, Folder folder) async {
    final totalRequests = _countRequests(folder);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          totalRequests > 0
              ? 'Delete "${folder.name}" and its $totalRequests request(s)?'
              : 'Delete "${folder.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
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

  // ── Request CRUD ──────────────────────────────────────────────────────────

  Future<void> _deleteRequest(
      Collection collection, HttpRequest request, String? folderUid) async {
    late Collection updated;
    if (folderUid == null) {
      updated = collection.copyWith(
        requests: collection.requests.where((r) => r.uid != request.uid).toList(),
      );
    } else {
      updated = collection.copyWith(
        folders: _updateFolderInTree(
          collection.folders,
          folderUid,
          (f) => f.copyWith(
            requests: f.requests.where((r) => r.uid != request.uid).toList(),
          ),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updated);
  }

  Future<void> _duplicateRequest(
      Collection collection, HttpRequest request, String? folderUid) async {
    final now = DateTime.now();
    final copy = request.copyWith(
      uid: _uuid.v4(),
      name: '${request.name} (copy)',
      createdAt: now,
      updatedAt: now,
    );
    late Collection updated;
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
  }

  Future<void> _showRenameRequestDialog(
    BuildContext context,
    Collection collection,
    HttpRequest request,
    String? folderUid,
  ) async {
    final controller = TextEditingController(text: request.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Request name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
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
            requests:
                f.requests.map((r) => r.uid == request.uid ? renamed : r).toList(),
          ),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updated);
  }

  // ── Move request ──────────────────────────────────────────────────────────

  Future<void> _showMoveDialog(
    Collection collection,
    HttpRequest request,
    String? fromFolderUid,
  ) async {
    final dests = _buildMoveDestinations(collection.uid, fromFolderUid);
    if (dests.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Move to',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.45,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                shrinkWrap: true,
                itemCount: dests.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 52),
                itemBuilder: (_, i) {
                  final dest = dests[i];
                  return ListTile(
                    leading: Icon(
                      dest.folderUid == null
                          ? Icons.inbox_outlined
                          : Icons.folder,
                      color: dest.folderUid == null
                          ? Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.55)
                          : AppColors.seedColor,
                    ),
                    title: Text(dest.label),
                    onTap: () {
                      Navigator.pop(ctx);
                      _moveRequest(collection, request, fromFolderUid,
                          dest.collectionUid, dest.folderUid);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MoveDest> _buildMoveDestinations(
      String collectionUid, String? fromFolderUid) {
    final collections = ref.read(collectionsProvider);
    final dests = <_MoveDest>[];

    for (final c in collections) {
      if (fromFolderUid != null || c.uid != collectionUid) {
        dests.add((
          collectionUid: c.uid,
          folderUid: null,
          label: c.uid == collectionUid ? 'Top level' : c.name,
        ));
      }
      void addFolders(List<Folder> folders, String prefix) {
        for (final f in folders) {
          if (f.uid != fromFolderUid) {
            dests.add((
              collectionUid: c.uid,
              folderUid: f.uid,
              label: '$prefix${f.name}',
            ));
          }
          addFolders(f.subFolders, '$prefix${f.name} / ');
        }
      }
      addFolders(c.folders, '');
    }
    return dests;
  }

  Future<void> _moveRequest(
    Collection sourceCollection,
    HttpRequest request,
    String? fromFolderUid,
    String toCollectionUid,
    String? toFolderUid,
  ) async {
    final collections = ref.read(collectionsProvider);
    final targetCollection =
        collections.where((c) => c.uid == toCollectionUid).firstOrNull;
    if (targetCollection == null) return;

    final now = DateTime.now();
    final moved = request.copyWith(
      folderUid: toFolderUid,
      collectionUid: toCollectionUid,
      updatedAt: now,
    );

    var updatedSource = _removeRequestFrom(sourceCollection, request.uid, fromFolderUid);
    await ref.read(collectionsProvider.notifier).update(updatedSource);

    late Collection updatedTarget;
    if (toFolderUid == null) {
      updatedTarget = targetCollection.copyWith(requests: [
        ...targetCollection.requests,
        moved,
      ]);
    } else {
      updatedTarget = targetCollection.copyWith(
        folders: _updateFolderInTree(
          targetCollection.folders,
          toFolderUid,
          (f) => f.copyWith(requests: [...f.requests, moved]),
        ),
      );
    }
    await ref.read(collectionsProvider.notifier).update(updatedTarget);
  }

  // ── DnD logic (unchanged from iOS) ───────────────────────────────────────

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

  int? _folderSiblingIndex(
      Collection c, String folderUid, String? parentFolderUid) {
    final siblings = parentFolderUid == null
        ? c.folders
        : (_findFolderByUid(c.folders, parentFolderUid)?.subFolders ?? []);
    final i = siblings.indexWhere((f) => f.uid == folderUid);
    return i >= 0 ? i : null;
  }

  bool _willAcceptRequestAt(
      CollectionTreeDragData? data, String? parentFolderUid, int rawSlot) {
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
      CollectionTreeDragData? data, String? parentFolderUid, int rawSlot) {
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
      CollectionTreeDragData? data, Folder target) =>
      data is CollectionTreeDragRequest;

  bool _willAcceptFolderIntoFolder(
      CollectionTreeDragData? data, Folder target) {
    if (data is! CollectionTreeDragFolder) return false;
    final c = _collectionSnapshot();
    if (data.folder.uid == target.uid) return false;
    return !_isTargetInsideDraggedFolderSubtree(c, data.folder.uid, target.uid);
  }

  bool _folderSubtreeContainsUid(Folder root, String uid) {
    if (root.uid == uid) return true;
    for (final s in root.subFolders) {
      if (_folderSubtreeContainsUid(s, uid)) return true;
    }
    return false;
  }

  bool _isTargetInsideDraggedFolderSubtree(
      Collection c, String draggedFolderUid, String targetFolderUid) {
    final dragged = _findFolderByUid(c.folders, draggedFolderUid);
    if (dragged == null) return false;
    return _folderSubtreeContainsUid(dragged, targetFolderUid);
  }

  Collection _removeRequestFrom(
      Collection c, String requestUid, String? folderUid) {
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
      Collection c, HttpRequest req, String? folderUid, int index) {
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
      List<Folder> folders, String uid) {
    for (var i = 0; i < folders.length; i++) {
      if (folders[i].uid == uid) {
        final f = folders[i];
        return (f, [...folders.sublist(0, i), ...folders.sublist(i + 1)]);
      }
      final sub = _pluckFolderRecursive(folders[i].subFolders, uid);
      if (sub.$1 != null) {
        final updated = folders[i].copyWith(subFolders: sub.$2);
        return (sub.$1, [
          ...folders.sublist(0, i),
          updated,
          ...folders.sublist(i + 1)
        ]);
      }
    }
    return (null, folders);
  }

  Collection _insertFolderSibling(
      Collection c, Folder folder, String? parentUid, int index) {
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

  Future<void> _relocateRequest(CollectionTreeDragRequest drag,
      String? toFolderUid, int rawSlot) async {
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
    if (sameParent && oldIdx < rawSlot) insertAt = rawSlot - 1;

    final destLen = toFolderUid == null
        ? next.requests.length
        : (_findFolderByUid(next.folders, toFolderUid)?.requests.length ?? 0);
    insertAt = insertAt.clamp(0, destLen);

    next = _insertRequestAt(next, moved, toFolderUid, insertAt);
    next = _renumberRequestSortOrders(next);

    if (toFolderUid != null) setState(() => _expandedFolders.add(toFolderUid));
    await ref.read(collectionsProvider.notifier).update(next);
  }

  Future<void> _relocateRequestIntoFolder(
      CollectionTreeDragRequest drag, String targetFolderUid) async {
    var c = _collectionSnapshot();
    final uid = drag.request.uid;
    final oldIdx = _requestIndex(c, uid, drag.fromFolderUid);
    if (oldIdx == null) return;

    var next = _removeRequestFrom(c, uid, drag.fromFolderUid);
    final host = _findFolderByUid(next.folders, targetFolderUid);
    if (host == null) return;

    final moved = drag.request.copyWith(
      folderUid: targetFolderUid,
      collectionUid: c.uid,
      updatedAt: DateTime.now(),
    );
    next = _insertRequestAt(next, moved, targetFolderUid, host.requests.length);
    next = _renumberRequestSortOrders(next);

    setState(() => _expandedFolders.add(targetFolderUid));
    await ref.read(collectionsProvider.notifier).update(next);
  }

  Future<void> _relocateFolderSibling(CollectionTreeDragFolder drag,
      String? toParentUid, int rawSlot) async {
    var c = _collectionSnapshot();
    final (plucked, treeWithout) = _pluckFolderRecursive(c.folders, drag.folder.uid);
    if (plucked == null) return;

    var next = c.copyWith(folders: treeWithout);
    final updated = plucked.copyWith(
      parentFolderUid: toParentUid,
      updatedAt: DateTime.now(),
    );

    final sameParent = drag.parentFolderUid == toParentUid;
    final oldIdx = _folderSiblingIndex(c, drag.folder.uid, drag.parentFolderUid);

    var insertAt = rawSlot;
    if (sameParent && oldIdx != null && oldIdx < rawSlot) insertAt = rawSlot - 1;

    next = _insertFolderSibling(next, updated, toParentUid, insertAt);
    next = _renumberAllFolderOrders(next);
    await ref.read(collectionsProvider.notifier).update(next);
  }

  Future<void> _relocateFolderInto(
      CollectionTreeDragFolder drag, Folder target) async {
    var c = _collectionSnapshot();
    final (plucked, treeWithout) = _pluckFolderRecursive(c.folders, drag.folder.uid);
    if (plucked == null) return;

    var next = c.copyWith(folders: treeWithout);
    final updated = plucked.copyWith(
      parentFolderUid: target.uid,
      updatedAt: DateTime.now(),
    );
    next = next.copyWith(
      folders: _updateFolderInTree(next.folders, target.uid, (f) {
        return f.copyWith(subFolders: [...f.subFolders, updated]);
      }),
    );
    next = _renumberAllFolderOrders(next);

    setState(() => _expandedFolders.add(target.uid));
    await ref.read(collectionsProvider.notifier).update(next);
  }
}

// ── _FolderHeaderMaterial ─────────────────────────────────────────────────────

class _FolderHeaderMaterial extends StatelessWidget {
  const _FolderHeaderMaterial({
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
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final primary = Theme.of(context).colorScheme.primary;
    final surfaceFill = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      color: surfaceFill,
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
            IconButton(
              padding: const EdgeInsets.only(right: 2),
              visualDensity: VisualDensity.compact,
              onPressed: onToggleSelect,
              icon: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 22,
                color: isSelected ? primary : muted,
              ),
            ),
          ],
          Expanded(
            child: GestureDetector(
              onTap: selectionMode ? onToggleSelect : onToggle,
              onLongPress: onLongPressSelect,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.chevron_right, size: 16, color: muted),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded ? Icons.folder_open : Icons.folder,
                    size: 16,
                    color: primary,
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
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                ],
              ),
            ),
          ),
          if (!selectionMode) ...[
            LongPressDraggable<CollectionTreeDragData>(
              data: dragData,
              hapticFeedbackOnStart: true,
              onDragStarted: onDragStarted,
              onDragEnd: (_) => onDragEnd(),
              onDraggableCanceled: (_, __) => onDragCanceled(),
              feedback: _FolderDragFeedbackCardMaterial(folder: folder),
              childWhenDragging: Icon(
                Icons.drag_handle,
                size: 18,
                color: muted.withValues(alpha: 0.35),
              ),
              child: Icon(Icons.drag_handle, size: 18, color: muted),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () => _showContextMenu(context),
              icon: Icon(Icons.more_vert, size: 18, color: muted),
            ),
          ],
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                folder.name,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Request'),
              onTap: () {
                Navigator.pop(ctx);
                onAddRequest();
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Add Sub-folder'),
              onTap: () {
                Navigator.pop(ctx);
                onAddSubFolder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Import collection JSON…'),
              onTap: () {
                Navigator.pop(ctx);
                onImportCollectionJson();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Export collection JSON…'),
              onTap: () {
                Navigator.pop(ctx);
                onExportFolder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outlined, color: Colors.red),
              title: const Text('Delete Folder',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FolderDragFeedbackCardMaterial extends StatelessWidget {
  const _FolderDragFeedbackCardMaterial({required this.folder});
  final Folder folder;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder, size: 16, color: AppColors.seedColor),
            const SizedBox(width: 8),
            Text(folder.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── _RequestRowMaterial ───────────────────────────────────────────────────────

class _RequestRowMaterial extends StatelessWidget {
  const _RequestRowMaterial({
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

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(request.name,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Move'),
              onTap: () {
                Navigator.pop(ctx);
                onMove();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(ctx);
                onDuplicate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Export collection JSON…'),
              onTap: () {
                Navigator.pop(ctx);
                onExportCollectionJson();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outlined, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final tertiary = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    final primary = Theme.of(context).colorScheme.primary;

    return Slidable(
      key: ValueKey(request.uid),
      enabled: !selectionMode,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.94,
        children: [
          SlidableAction(
            onPressed: (_) => onRename(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit_outlined,
            spacing: 2,
            label: 'Rename',
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
          SlidableAction(
            onPressed: (_) => onMove(),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.compare_arrows,
            spacing: 2,
            label: 'Move',
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
          SlidableAction(
            onPressed: (_) => onDuplicate(),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            icon: Icons.copy_outlined,
            spacing: 2,
            label: 'Copy',
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outlined,
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
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selectionMode)
              IconButton(
                padding: const EdgeInsets.only(right: 2),
                visualDensity: VisualDensity.compact,
                onPressed: onToggleSelect,
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: isSelected ? primary : muted,
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
                                color: muted,
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
            if (!selectionMode) ...[
              LongPressDraggable<CollectionTreeDragData>(
                data: dragData,
                hapticFeedbackOnStart: true,
                onDragStarted: onDragStarted,
                onDragEnd: (_) => onDragEnd(),
                onDraggableCanceled: (_, __) => onDragCanceled(),
                feedback: _RequestDragFeedbackCardMaterial(request: request),
                childWhenDragging: Icon(Icons.drag_handle, size: 18,
                    color: tertiary.withValues(alpha: 0.35)),
                child: Icon(Icons.drag_handle, size: 18, color: tertiary),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => _showContextMenu(context),
                icon: Icon(Icons.more_vert, size: 18, color: muted),
              ),
              Icon(Icons.chevron_right, size: 14, color: tertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestDragFeedbackCardMaterial extends StatelessWidget {
  const _RequestDragFeedbackCardMaterial({required this.request});
  final HttpRequest request;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MethodBadge(method: request.method.value),
            const SizedBox(width: 8),
            Text(request.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
