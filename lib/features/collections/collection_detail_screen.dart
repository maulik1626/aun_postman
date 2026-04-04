import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/domain/models/folder.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/features/collections/providers/collections_provider.dart';
import 'package:aun_postman/features/collections/widgets/method_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
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

    // Flatten the entire folder tree into a list of widgets
    final folderWidgets = _buildFolderWidgets(
      context,
      collection,
      collection.folders,
      indent: 0,
    );

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(collection.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 44,
                  onPressed: () => _showCreateFolderDialog(context, collection,
                      parentUid: null),
                  child: const Icon(CupertinoIcons.folder_badge_plus, size: 22),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 44,
                  onPressed: () =>
                      context.push('/collections/${widget.uid}/request/new'),
                  child: const Icon(CupertinoIcons.add),
                ),
              ],
            ),
          ),
          // Root-level requests
          if (collection.requests.isNotEmpty) ...[
            SliverToBoxAdapter(child: _sectionHeader(context, 'REQUESTS')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final request = collection.requests[index];
                  return _RequestRow(
                    key: ValueKey(request.uid),
                    request: request,
                    collectionUid: widget.uid,
                    indent: 0,
                    folderUid: null,
                    onDelete: () =>
                        _deleteRequest(collection, request, null),
                    onDuplicate: () =>
                        _duplicateRequest(collection, request, null),
                    onRename: () => _showRenameRequestDialog(
                        context, collection, request, null),
                    onMove: () =>
                        _showMoveDialog(collection, request, null),
                  );
                },
                childCount: collection.requests.length,
              ),
            ),
          ],

          // Folders (recursively flattened)
          if (folderWidgets.isNotEmpty) ...[
            SliverToBoxAdapter(child: _sectionHeader(context, 'FOLDERS')),
            SliverList(
              delegate: SliverChildListDelegate(folderWidgets),
            ),
          ],

          // Empty state
          if (collection.requests.isEmpty && collection.folders.isEmpty)
            SliverFillRemaining(
              child: Center(
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          color: CupertinoColors.tertiarySystemFill
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(10),
                          onPressed: () => _showCreateFolderDialog(
                              context, collection,
                              parentUid: null),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.folder_badge_plus,
                                size: 16,
                                color:
                                    CupertinoColors.label.resolveFrom(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'New Folder',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.label
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppGradientButton(
                          onPressed: () => context.push(
                              '/collections/${widget.uid}/request/new'),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.add, size: 16),
                              SizedBox(width: 6),
                              Text('Add Request'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// Recursively builds a flat list of widgets for folders and their contents.
  List<Widget> _buildFolderWidgets(
    BuildContext context,
    Collection collection,
    List<Folder> folders, {
    required int indent,
  }) {
    final widgets = <Widget>[];
    for (final folder in folders) {
      final isExpanded = _expandedFolders.contains(folder.uid);

      widgets.add(_FolderHeader(
        key: ValueKey('folder_header_${folder.uid}'),
        folder: folder,
        isExpanded: isExpanded,
        indent: indent,
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
      ));

      if (isExpanded) {
        // Sub-folders first (recursive)
        widgets.addAll(_buildFolderWidgets(
          context,
          collection,
          folder.subFolders,
          indent: indent + 1,
        ));

        // Requests in this folder
        for (final request in folder.requests) {
          widgets.add(_RequestRow(
            key: ValueKey('req_${request.uid}'),
            request: request,
            collectionUid: widget.uid,
            indent: indent + 1,
            folderUid: folder.uid,
            onDelete: () =>
                _deleteRequest(collection, request, folder.uid),
            onDuplicate: () =>
                _duplicateRequest(collection, request, folder.uid),
            onRename: () => _showRenameRequestDialog(
                context, collection, request, folder.uid),
            onMove: () =>
                _showMoveDialog(collection, request, folder.uid),
          ));
        }
      }
    }
    return widgets;
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

// ── _FolderHeader ─────────────────────────────────────────────────────────────

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    super.key,
    required this.folder,
    required this.isExpanded,
    required this.indent,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    required this.onAddRequest,
    required this.onAddSubFolder,
  });

  final Folder folder;
  final bool isExpanded;
  final int indent;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAddRequest;
  final VoidCallback onAddSubFolder;

  @override
  Widget build(BuildContext context) {
    final directCount = folder.requests.length;
    final hasSubFolders = folder.subFolders.isNotEmpty;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
        padding: EdgeInsets.only(
          left: 16.0 + indent * 20.0,
          right: 8,
          top: 10,
          bottom: 10,
        ),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color:
                    CupertinoColors.secondaryLabel.resolveFrom(context),
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
            // Badge: sub-folder count + request count
            if (hasSubFolders || directCount > 0)
              Text(
                hasSubFolders
                    ? '${folder.subFolders.length}f · ${directCount}r'
                    : '$directCount',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 36,
              onPressed: () => _showContextMenu(context),
              child: Icon(
                CupertinoIcons.ellipsis_circle,
                size: 18,
                color:
                    CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
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
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.trash),
                SizedBox(width: 8),
                Text('Delete Folder'),
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
    required this.onDelete,
    required this.onDuplicate,
    required this.onRename,
    required this.onMove,
  });

  final HttpRequest request;
  final String collectionUid;
  final int indent;
  final String? folderUid;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(request.uid),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.72,
        children: [
          SlidableAction(
            onPressed: (_) => onRename(),
            backgroundColor: CupertinoColors.systemBlue,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.pencil,
            label: 'Rename',
          ),
          SlidableAction(
            onPressed: (_) => onMove(),
            backgroundColor: CupertinoColors.systemOrange,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.arrow_right_arrow_left,
            label: 'Move',
          ),
          SlidableAction(
            onPressed: (_) => onDuplicate(),
            backgroundColor: CupertinoColors.systemIndigo,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.doc_on_doc,
            label: 'Copy',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: CupertinoColors.destructiveRed,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.trash,
            label: 'Delete',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => context.push(
          '/collections/$collectionUid/request/${request.uid}',
        ),
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0 + indent * 20.0,
            right: 16,
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
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
