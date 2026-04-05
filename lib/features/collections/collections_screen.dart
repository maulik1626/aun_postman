import 'dart:io';

import 'package:aun_postman/app/router/app_routes.dart';
import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/core/notifications/user_notification.dart';
import 'package:aun_postman/core/utils/postman_v2_exporter.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/features/collections/dialogs/create_collection_dialog.dart';
import 'package:aun_postman/features/collections/providers/collections_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Collections'),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 44,
                onPressed: () => context.push(AppRoutes.settings),
                child: const Icon(CupertinoIcons.settings),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44,
                    onPressed: () => context.push(AppRoutes.importExport),
                    child: const Icon(CupertinoIcons.square_arrow_down),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44,
                    onPressed: () => _showCreateDialog(context, ref),
                    child: const Icon(CupertinoIcons.add),
                  ),
                ],
              ),
            ),
            if (collections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: _EmptyState(
                          onCreate: () => _showCreateDialog(context, ref),
                        ),
                      ),
                    ),
                    SizedBox(height: bottomInset),
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
                      child: ReorderableList(
                        padding: EdgeInsets.zero,
                        itemCount: collections.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          final reordered = [...collections];
                          final item = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, item);
                          ref
                              .read(collectionsProvider.notifier)
                              .reorder(reordered.map((c) => c.uid).toList());
                        },
                        itemBuilder: (context, index) {
                          final collection = collections[index];
                          final requestCount =
                              collection.requests.length +
                              collection.folders.fold(
                                0,
                                (s, f) => s + f.requests.length,
                              );
                          return Slidable(
                            key: ValueKey(collection.uid),
                            startActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.22,
                              children: [
                                SlidableAction(
                                  onPressed: (ctx) =>
                                      _shareCollection(ctx, collection),
                                  backgroundColor: CupertinoColors.systemBlue,
                                  foregroundColor: CupertinoColors.white,
                                  icon: CupertinoIcons.share_up,
                                  spacing: 2,
                                  label: 'Share',
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 4,
                                  ),
                                ),
                              ],
                            ),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.48,
                              children: [
                                SlidableAction(
                                  onPressed: (_) => ref
                                      .read(collectionsProvider.notifier)
                                      .duplicate(collection.uid),
                                  backgroundColor: CupertinoColors.systemIndigo,
                                  foregroundColor: CupertinoColors.white,
                                  icon: CupertinoIcons.doc_on_doc,
                                  spacing: 2,
                                  label: 'Duplicate',
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 4),
                                ),
                                SlidableAction(
                                  onPressed: (_) => _confirmDelete(
                                    context,
                                    ref,
                                    collection.uid,
                                    collection.name,
                                  ),
                                  backgroundColor: CupertinoColors.destructiveRed,
                                  foregroundColor: CupertinoColors.white,
                                  icon: CupertinoIcons.trash,
                                  spacing: 2,
                                  label: 'Delete',
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 4),
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () =>
                                  context.push('/collections/${collection.uid}'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: CupertinoColors.separator.resolveFrom(
                                        context,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: CupertinoTheme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.folder_fill,
                                        size: 18,
                                        color: CupertinoTheme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            collection.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$requestCount request${requestCount == 1 ? '' : 's'}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: CupertinoColors.secondaryLabel
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                          if (collection.description != null &&
                                              collection.description!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              collection.description!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: CupertinoColors.tertiaryLabel
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 16,
                                      color: CupertinoColors.tertiaryLabel.resolveFrom(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        CupertinoIcons.line_horizontal_3,
                                        size: 18,
                                        color: CupertinoColors.tertiaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: bottomInset),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Rect _shareAnchorRect(BuildContext anchorContext) {
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

  static Future<void> _shareCollection(
    BuildContext context,
    Collection collection,
  ) async {
    try {
      final json = PostmanV2Exporter.export(collection);
      final dir = await getTemporaryDirectory();
      final safe = collection.name
          .replaceAll(RegExp(r'[^\w\s.-]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/$safe.json');
      await file.writeAsString(json);
      if (!context.mounted) return;
      final origin = Platform.isIOS ? _shareAnchorRect(context) : null;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '${collection.name} — Postman',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!context.mounted) return;
      UserNotification.show(
        context: context,
        title: 'Share',
        body: e.toString(),
      );
    }
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showCupertinoDialog<(String, String?)>(
      context: context,
      builder: (_) => const CreateCollectionDialog(),
    );
    if (result != null) {
      await ref
          .read(collectionsProvider.notifier)
          .create(result.$1, description: result.$2);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String uid,
    String name,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Delete "$name" and all its requests?'),
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
    if (confirmed == true) {
      await ref.read(collectionsProvider.notifier).delete(uid);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CupertinoTheme.of(
                context,
              ).primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              CupertinoIcons.folder_badge_plus,
              size: 40,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Collections',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Organise your requests into collections',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 28),
          AppGradientButton(
            onPressed: onCreate,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.add, size: 18),
                SizedBox(width: 6),
                Text('New Collection'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
