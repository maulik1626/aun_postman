import 'dart:io';

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/web/web_toast.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/widgets/banner_ad_tile.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/domain/models/collection.dart';
import 'package:aun_reqstudio/features/collections/collection_detail_screen_material.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/ad_session_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

NativeListAdTile _nativeAdTileMaterial(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final chrome = scheme.surfaceContainerLow;
  final border = scheme.outlineVariant;
  final label = scheme.onSurface.withValues(alpha: 0.62);

  return NativeListAdTile(
    appearanceKey: scheme.brightness,
    chromeColor: chrome,
    borderColor: border,
    labelColor: label,
    height: 340,
    templateStyle: NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: chrome,
      cornerRadius: 12,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface,
        size: 15,
        style: NativeTemplateFontStyle.bold,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface.withValues(alpha: 0.72),
        size: 13,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface.withValues(alpha: 0.56),
        size: 11,
      ),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onPrimary,
        backgroundColor: scheme.primary,
        size: 13,
        style: NativeTemplateFontStyle.bold,
      ),
    ),
  );
}

class CollectionsScreenMaterial extends ConsumerStatefulWidget {
  const CollectionsScreenMaterial({super.key});

  @override
  ConsumerState<CollectionsScreenMaterial> createState() =>
      _CollectionsScreenMaterialState();
}

class _CollectionsScreenMaterialState
    extends ConsumerState<CollectionsScreenMaterial> {
  static const _exitGracePeriod = Duration(seconds: 2);
  static const _exitMessage = 'Press back again to exit';

  // Tablet expanded two-pane: uid of collection shown in right pane.
  String? _selectedUid;
  DateTime? _lastExitBackPressAt;

  Future<void> _handleRootBackNavigation() async {
    final now = DateTime.now();
    final lastPress = _lastExitBackPressAt;
    final shouldExit =
        lastPress != null && now.difference(lastPress) <= _exitGracePeriod;

    if (shouldExit) {
      await SystemNavigator.pop();
      return;
    }

    _lastExitBackPressAt = now;
    if (AppPlatform.usesWebCustomUi) {
      WebToast.show(context, message: _exitMessage, type: WebToastType.info);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(_exitMessage),
          behavior: SnackBarBehavior.floating,
          duration: _exitGracePeriod,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final settings = ref.watch(appSettingsProvider);
    final adSession = ref.watch(adSessionProvider);
    final isExpandedLayout = AppPlatform.isExpanded(context);

    if (isExpandedLayout) {
      return Row(
        children: [
          SizedBox(
            width: 320,
            child: _buildListPane(
              context,
              collections,
              isExpanded: true,
              adInterval: settings.collectionsAdInterval,
              sessionBrowseAdsDisabled: adSession.browseAdsDisabledByReward,
            ),
          ),
          const VerticalDivider(width: 1, thickness: 0.5),
          Expanded(
            child: _selectedUid == null
                ? const _EmptyDetailPane()
                : CollectionDetailScreenMaterial(
                    uid: _selectedUid!,
                    isEmbedded: true,
                  ),
          ),
        ],
      );
    }

    return _buildListPane(
      context,
      collections,
      isExpanded: false,
      adInterval: settings.collectionsAdInterval,
      sessionBrowseAdsDisabled: adSession.browseAdsDisabledByReward,
    );
  }

  Widget _buildListPane(
    BuildContext context,
    List<Collection> collections, {
    required bool isExpanded,
    required int adInterval,
    required bool sessionBrowseAdsDisabled,
  }) {
    final isEmpty = collections.isEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleRootBackNavigation();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        leading: IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(AppRoutes.settings),
        ),
        actions: [
          IconButton(
            tooltip: 'Import / Export',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => context.push(AppRoutes.importExport),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: isEmpty
            ? Center(
                child: _EmptyState(
                  onCreate: () => _showCreateDialog(context, ref),
                ),
              )
            : ReorderableListView.builder(
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
                  final isSelected =
                      isExpanded && _selectedUid == collection.uid;

                  return Column(
                    key: ValueKey(collection.uid),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slidable(
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.22,
                          children: [
                            SlidableAction(
                              onPressed: (ctx) =>
                                  _shareCollection(ctx, collection),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.share_outlined,
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
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              icon: Icons.copy_outlined,
                              spacing: 2,
                              label: 'Duplicate',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                            ),
                            SlidableAction(
                              onPressed: (_) => _confirmDelete(
                                context,
                                ref,
                                collection.uid,
                                collection.name,
                              ),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_outlined,
                              spacing: 2,
                              label: 'Delete',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            if (isExpanded) {
                              setState(() => _selectedUid = collection.uid);
                            } else {
                              context.push('/collections/${collection.uid}');
                            }
                          },
                          child: Container(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.06)
                                : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.folder,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                      if (collection.description != null &&
                                          collection
                                              .description!
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          collection.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.38),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.38),
                                ),
                                const SizedBox(width: 4),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_handle,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.38),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (AppConstants.enableAds &&
                          !sessionBrowseAdsDisabled &&
                          AdConfig.collections.shouldInsertAfterOrdinal(
                            index + 1,
                            overrideEvery: adInterval,
                          ))
                        _nativeAdTileMaterial(context),
                    ],
                  );
                },
              ),
      ),
      floatingActionButton: isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text(
                'New Collection',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => const _CreateCollectionDialog(),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Delete "$name" and all its requests?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(collectionsProvider.notifier).delete(uid);
      if (_selectedUid == uid) {
        setState(() => _selectedUid = null);
      }
    }
  }

  // ── Share ──────────────────────────────────────────────────────────────────

  static Future<void> _shareCollection(
    BuildContext context,
    Collection collection,
  ) async {
    try {
      final json = CollectionV21Exporter.export(collection);
      final dir = await getTemporaryDirectory();
      final safe = collection.name
          .replaceAll(RegExp(r'[^\w\s.-]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/$safe.json');
      await file.writeAsString(json);
      if (!context.mounted) return;
      // Android share sheet doesn't need a position origin.
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/json'),
      ], subject: '${collection.name} — AUN - ReqStudio');
    } catch (e) {
      if (!context.mounted) return;
      UserNotification.show(
        context: context,
        title: 'Share',
        body: e.toString(),
      );
    }
  }
}

// ── Create collection dialog ──────────────────────────────────────────────────

/// Controllers are owned here and disposed in [dispose] so they outlive the
/// route pop + exit animation (and IME teardown). Disposing immediately after
/// [showDialog] returns races the still-mounted [TextField]s and throws.
class _CreateCollectionDialog extends StatefulWidget {
  const _CreateCollectionDialog();

  @override
  State<_CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<_CreateCollectionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Collection'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Collection name',
                hintText: 'My API',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final desc = _descController.text.trim();
              Navigator.pop(context, (name, desc.isEmpty ? null : desc));
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.create_new_folder_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Collections',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Organise your requests into collections',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 28),
          AppGradientButton.material(
            onPressed: onCreate,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18),
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

class _EmptyDetailPane extends StatelessWidget {
  const _EmptyDetailPane();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a collection',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
