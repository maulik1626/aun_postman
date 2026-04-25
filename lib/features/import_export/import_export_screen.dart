import 'dart:async';
import 'dart:io';

import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/platform/shared_json_import_channel.dart';
import 'package:aun_reqstudio/core/platform/icloud_backup_channel.dart';
import 'package:aun_reqstudio/core/services/ad_service.dart';
import 'package:aun_reqstudio/core/utils/app_backup.dart';
import 'package:aun_reqstudio/core/utils/full_backup_json.dart';
import 'package:aun_reqstudio/core/utils/curl_parser.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/active_environment_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/import_export/json_import_flow.dart';
import 'package:aun_reqstudio/features/websocket/providers/ws_saved_compose_provider.dart';
import 'package:aun_reqstudio/infrastructure/history_repository.dart';
import 'package:aun_reqstudio/infrastructure/ws_saved_compose_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  String? _lastImportedEnvUid; // uid of auto-created env, for navigation
  VoidCallback? _sharedImportListener;

  /// iOS: after first [_refreshIcloudMeta] completes.
  bool _icloudMetaLoaded = false;
  bool _icloudAvailable = false;
  double? _icloudModifiedMs;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_refreshIcloudMeta()),
      );
    }
    final coordinator = ref.read(sharedJsonImportCoordinatorProvider);
    _sharedImportListener = () {
      unawaited(_consumePendingSharedImport());
    };
    coordinator.addListener(_sharedImportListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumePendingSharedImport());
    });
  }

  Future<void> _refreshIcloudMeta() async {
    if (!Platform.isIOS) return;
    final av = await IcloudBackupChannel.isAvailable();
    double? ms;
    if (av && await IcloudBackupChannel.backupExists()) {
      ms = await IcloudBackupChannel.backupModifiedMsSinceEpoch();
    }
    if (!mounted) return;
    setState(() {
      _icloudMetaLoaded = true;
      _icloudAvailable = av;
      _icloudModifiedMs = ms;
    });
  }

  String? _icloudBackupAgeLabel() {
    final ms = _icloudModifiedMs;
    if (ms == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms.round());
    return DateFormat.yMMMd().add_jm().format(dt);
  }

  Future<void> _showPostImportExportAd() async {
    if (!mounted) return;
    await AdService.instance.maybeShowPostImportExportInterstitial();
  }

  void _handleBackNavigation() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(AppRoutes.collections);
  }

  Future<void> _deleteSharedImportFile(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_sharedImportListener != null) {
      ref
          .read(sharedJsonImportCoordinatorProvider)
          .removeListener(_sharedImportListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Import / Export'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _handleBackNavigation,
              minimumSize: const Size(44, 44),
              child: const Icon(CupertinoIcons.xmark),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const _SectionHeader(title: 'Full backup'),
                      const SizedBox(height: 8),
                      Text(
                        'Export or restore collections, environments, request history, '
                        'and saved WebSocket composer messages. '
                        'Global settings (timeout, proxy, default headers, etc.) are not included. '
                        'WebSocket tab URLs and headers stay on this device (secure storage) and are not in this backup file. '
                        'Restore replaces all current data of those types.'
                        '${Platform.isIOS ? ' On iPhone and iPad you can also save and restore the same backup via iCloud.' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _OptionCard(
                        icon: CupertinoIcons.archivebox_fill,
                        title: 'Export all data',
                        subtitle:
                            'Single JSON file — use for backup or moving devices',
                        onTap: _exportFullBackup,
                      ),
                      const SizedBox(height: 8),
                      _OptionCard(
                        icon: CupertinoIcons.arrow_counterclockwise_circle,
                        title: 'Restore from backup',
                        subtitle:
                            'Deletes all current data, then imports the file',
                        onTap: _restoreFullBackup,
                      ),
                      if (Platform.isIOS) ...[
                        const SizedBox(height: 16),
                        Text(
                          'iCloud',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!_icloudMetaLoaded)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const CupertinoActivityIndicator(radius: 10),
                                const SizedBox(width: 10),
                                Text(
                                  'Checking iCloud…',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (!_icloudAvailable)
                          Text(
                            'iCloud is not available. Sign in to iCloud on this device '
                            'and ensure iCloud Drive is enabled.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          )
                        else ...[
                          _OptionCard(
                            icon: CupertinoIcons.cloud_upload_fill,
                            title: 'Save backup to iCloud',
                            subtitle:
                                'Replaces any previous iCloud backup for this app',
                            onTap: _saveBackupToIcloud,
                          ),
                          const SizedBox(height: 8),
                          _OptionCard(
                            icon: CupertinoIcons.cloud_download_fill,
                            title: 'Restore from iCloud',
                            subtitle: _icloudBackupAgeLabel() != null
                                ? 'Last saved: ${_icloudBackupAgeLabel()}'
                                : 'Uses the latest file saved from this app',
                            onTap: _restoreFromIcloud,
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                      if (_statusMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoTheme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_circle,
                                    color: CupertinoTheme.of(
                                      context,
                                    ).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _statusMessage!,
                                      style: TextStyle(
                                        color: CupertinoTheme.of(
                                          context,
                                        ).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_lastImportedEnvUid != null) ...[
                                const SizedBox(height: 8),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.push(
                                      '${AppRoutes.environments}/$_lastImportedEnvUid',
                                    );
                                  },
                                  minimumSize: const Size(0, 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.arrow_right_circle,
                                        size: 16,
                                        color: CupertinoTheme.of(
                                          context,
                                        ).primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'View & fill variables',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: CupertinoTheme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      const _SectionHeader(title: 'Import'),
                      const SizedBox(height: 12),

                      _OptionCard(
                        icon: CupertinoIcons.doc_text,
                        title: 'Collection JSON (v2.1)',
                        subtitle:
                            'Import requests + auto-create variable environment',
                        onTap: _importCollectionFile,
                      ),
                      const SizedBox(height: 8),
                      _OptionCard(
                        icon: CupertinoIcons.globe,
                        title: 'Environment JSON',
                        subtitle: 'Import a v2.x environment export JSON file',
                        onTap: _importCollectionEnvironment,
                      ),
                      const SizedBox(height: 8),
                      _OptionCard(
                        icon: CupertinoIcons.chevron_left_slash_chevron_right,
                        title: 'cURL Command',
                        subtitle: 'Paste a cURL command to import a request',
                        onTap: _importCurl,
                      ),

                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Export'),
                      const SizedBox(height: 12),

                      if (collections.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No collections to export',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        )
                      else
                        ...collections.map(
                          (col) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Builder(
                              builder: (cardContext) => _OptionCard(
                                icon: CupertinoIcons.folder_fill,
                                title: col.name,
                                subtitle: 'Export as collection v2.1 JSON',
                                onTap: () => _exportCollection(
                                  col.uid,
                                  sharePositionOrigin: _shareAnchorRect(
                                    cardContext,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CupertinoActivityIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: bottomInset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFullBackup() async {
    setState(() => _isLoading = true);
    try {
      final json = await buildFullBackupJson(ref);
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/aun_reqstudio_backup_$stamp.json');
      await file.writeAsString(json);

      if (!mounted) return;
      final origin = Platform.isIOS ? _shareAnchorRect(context) : null;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'AUN - ReqStudio — full backup',
        sharePositionOrigin: origin,
      );
      if (mounted) {
        setState(() => _statusMessage = 'Full backup exported');
      }
      await _showPostImportExportAd();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreFullBackup() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This will permanently delete all collections, environments, '
          'request history, and saved WebSocket messages on this device, '
          'then replace them with the backup file.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return;

      final content = await File(result.files.single.path!).readAsString();
      final data = AppBackup.parse(content);
      await _applyFullRestore(data);

      if (!mounted) return;
      setState(() {
        _lastImportedEnvUid = null;
        _statusMessage =
            'Restored ${data.collections.length} collection(s), '
            '${data.environments.length} environment(s), '
            '${data.history.length} history entries';
      });
      await _showPostImportExportAd();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBackupToIcloud() async {
    if (!Platform.isIOS) return;
    setState(() => _isLoading = true);
    try {
      final json = await buildFullBackupJson(ref);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/aun_reqstudio_icloud_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json);
      await IcloudBackupChannel.copyFileToICloud(file.path);
      await file.delete();
      await _refreshIcloudMeta();
      if (mounted) {
        setState(() => _statusMessage = 'Backup saved to iCloud');
      }
      await _showPostImportExportAd();
    } on IcloudBackupException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreFromIcloud() async {
    if (!Platform.isIOS) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Restore from iCloud?'),
        content: const Text(
          'This will permanently delete all collections, environments, '
          'request history, and saved WebSocket messages on this device, '
          'then replace them with the iCloud backup.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    String? tempPath;
    try {
      tempPath = await IcloudBackupChannel.copyFromICloudToTempPath();
      if (tempPath == null) {
        _showError('No backup found in iCloud. Save a backup to iCloud first.');
        return;
      }
      final content = await File(tempPath).readAsString();
      final data = AppBackup.parse(content);
      await _applyFullRestore(data);

      if (!mounted) return;
      setState(() {
        _lastImportedEnvUid = null;
        _statusMessage =
            'Restored from iCloud: ${data.collections.length} collection(s), '
            '${data.environments.length} environment(s), '
            '${data.history.length} history entries';
      });
      await _refreshIcloudMeta();
      await _showPostImportExportAd();
    } on IcloudBackupException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (tempPath != null) {
        try {
          await File(tempPath).delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyFullRestore(AppBackupData data) async {
    await ref.read(collectionsProvider.notifier).clearAll();
    await ref.read(environmentsProvider.notifier).clearAll();
    await ref.read(historyProvider.notifier).clearAll();
    await ref.read(wsSavedComposeRepositoryProvider).clearAll();

    for (final c in data.collections) {
      await ref.read(collectionsProvider.notifier).importCollection(c);
    }
    for (final e in data.environments) {
      await ref
          .read(environmentsProvider.notifier)
          .importEnvironment(e.copyWith(isActive: false));
    }
    for (final h in data.history) {
      await ref.read(historyRepositoryProvider).save(h);
    }
    ref.invalidate(historyProvider);

    for (final m in data.wsSavedCompose) {
      await ref.read(wsSavedComposeRepositoryProvider).save(m);
    }
    ref.invalidate(wsSavedComposeListProvider);

    await ref.read(activeEnvironmentProvider.notifier).clearActive();
    final uid = data.activeEnvironmentUid;
    if (uid != null && data.environments.any((e) => e.uid == uid)) {
      await ref.read(environmentsProvider.notifier).setActive(uid);
    }
    ref.invalidate(collectionsProvider);
    ref.invalidate(environmentsProvider);
    ref.invalidate(activeEnvironmentProvider);
  }

  Future<void> _importCollectionFile() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final content = await File(result.files.single.path!).readAsString();
      final outcome = await ImportExportJsonImporter.importCollectionFromContent(
        ref: ref,
        content: content,
      );
      _applyJsonImportOutcome(outcome);
      await _showPostImportExportAd();
    } catch (e) {
      _showError(ImportExportJsonImporter.errorMessageFor(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importCollectionEnvironment() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final content = await File(result.files.single.path!).readAsString();
      final outcome =
          await ImportExportJsonImporter.importEnvironmentFromContent(
            ref: ref,
            content: content,
          );
      _applyJsonImportOutcome(outcome);
      await _showPostImportExportAd();
    } catch (e) {
      _showError(ImportExportJsonImporter.errorMessageFor(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importCurl() async {
    final controller = TextEditingController();
    final curlCommand = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground.resolveFrom(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          bottom:
              MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom +
              16,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.separator.resolveFrom(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Import cURL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Paste a cURL command to import a request',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoTextField(
                  controller: controller,
                  maxLines: 6,
                  minLines: 4,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.all(12),
                  placeholder: "curl -X GET 'https://api.example.com'",
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemBackground.resolveFrom(
                      ctx,
                    ),
                    border: Border.all(
                      color: CupertinoColors.separator.resolveFrom(ctx),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  autofocus: true,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(
                          ctx,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.label.resolveFrom(ctx),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppGradientButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text.trim()),
                        child: const Text('Import'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();

    if (curlCommand == null || curlCommand.isEmpty) return;

    final request = CurlParser.parse(curlCommand);
    if (request == null) {
      _showError('Could not parse cURL command');
      return;
    }

    final collections = ref.read(collectionsProvider);
    if (collections.isEmpty) {
      _showError('Create a collection first to save the request into');
      return;
    }

    if (!mounted) return;
    final targetCollection = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Save to Collection'),
        actions: collections
            .map(
              (col) => CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, col.uid),
                child: Text(col.name),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (targetCollection == null) return;

    final collection = collections.firstWhere((c) => c.uid == targetCollection);
    final updatedRequest = request.copyWith(collectionUid: targetCollection);
    final updatedCollection = collection.copyWith(
      requests: [...collection.requests, updatedRequest],
    );
    await ref.read(collectionsProvider.notifier).update(updatedCollection);
    setState(() => _statusMessage = 'Request imported successfully');
    await _showPostImportExportAd();
  }

  /// iOS requires a non-zero [sharePositionOrigin] for the share sheet anchor.
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

  Future<void> _exportCollection(
    String uid, {
    Rect? sharePositionOrigin,
  }) async {
    setState(() => _isLoading = true);
    try {
      final collection = ref
          .read(collectionsProvider)
          .firstWhere((c) => c.uid == uid);

      final json = CollectionV21Exporter.export(collection);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${collection.name.replaceAll(RegExp(r'[^\w\s]'), '_')}.json',
      );
      await file.writeAsString(json);

      if (!mounted) return;
      final origin = Platform.isIOS
          ? (sharePositionOrigin ?? _shareAnchorRect(context))
          : null;

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '${collection.name} — AUN - ReqStudio',
        sharePositionOrigin: origin,
      );

      setState(() => _statusMessage = 'Export ready');
      await _showPostImportExportAd();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    UserNotification.show(
      context: context,
      title: 'Import / Export',
      body: message,
    );
  }

  void _applyJsonImportOutcome(JsonImportOutcome outcome) {
    setState(() {
      _lastImportedEnvUid = outcome.lastImportedEnvUid;
      _statusMessage = outcome.statusMessage;
    });
  }

  Future<void> _consumePendingSharedImport() async {
    if (!mounted || _isLoading) return;

    final coordinator = ref.read(sharedJsonImportCoordinatorProvider);
    final payload = coordinator.consumeNext();
    if (payload == null) return;

    setState(() => _isLoading = true);
    try {
      final content = await File(payload.path).readAsString();
      final outcome = await ImportExportJsonImporter.importSharedJsonFromContent(
        ref: ref,
        content: content,
        fileName: payload.fileName,
      );
      _applyJsonImportOutcome(outcome);
      await _showPostImportExportAd();
    } catch (e) {
      _showError(ImportExportJsonImporter.errorMessageFor(e));
    } finally {
      unawaited(_deleteSharedImportFile(payload.path));
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (coordinator.hasPending) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_consumePendingSharedImport());
        });
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: CupertinoTheme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
