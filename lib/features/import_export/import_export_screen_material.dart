import 'dart:async';
import 'dart:io';

import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/platform/icloud_backup_channel.dart';
import 'package:aun_reqstudio/core/services/ad_service.dart';
import 'package:aun_reqstudio/core/utils/app_backup.dart';
import 'package:aun_reqstudio/core/utils/full_backup_json.dart';
import 'package:aun_reqstudio/core/utils/curl_parser.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_importer.dart';
import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/active_environment_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/websocket/providers/ws_saved_compose_provider.dart';
import 'package:aun_reqstudio/infrastructure/history_repository.dart';
import 'package:aun_reqstudio/infrastructure/ws_saved_compose_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class ImportExportScreenMaterial extends ConsumerStatefulWidget {
  const ImportExportScreenMaterial({super.key});

  @override
  ConsumerState<ImportExportScreenMaterial> createState() =>
      _ImportExportScreenMaterialState();
}

class _ImportExportScreenMaterialState
    extends ConsumerState<ImportExportScreenMaterial> {
  static const _uuid = Uuid();
  bool _isLoading = false;
  String? _statusMessage;
  String? _lastImportedEnvUid;

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

  /// Avoids go_router + [StatefulShellRoute] duplicate [Page] key assertions on
  /// Android when leaving a root route like `/import` and opening a shell branch
  /// (`/environments/:uid`) in the same synchronous callback.
  void _closeImportAndGoToEnvironment(String uid) {
    final router = GoRouter.of(context);
    final path = '${AppRoutes.environments}/$uid';
    router.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(path);
    });
  }

  Future<void> _showPostImportExportAd() async {
    if (!mounted) return;
    await AdService.instance.maybeShowPostImportExportInterstitial();
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Import / Export'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Full backup ──────────────────────────────────────────
          _SectionHeaderMat(title: 'Full backup', color: secondary),
          const SizedBox(height: 8),
          Text(
            'Export or restore collections, environments, request history, '
            'and saved WebSocket composer messages. '
            'Global settings are not included. '
            'Restore replaces all current data of those types.'
            '${Platform.isIOS ? ' On iPhone and iPad you can also save and restore the same backup via iCloud.' : ''}',
            style: TextStyle(fontSize: 13, height: 1.35, color: secondary),
          ),
          const SizedBox(height: 12),
          _OptionCardMat(
            icon: Icons.archive_outlined,
            title: 'Export all data',
            subtitle: 'Single JSON file — use for backup or moving devices',
            onTap: _exportFullBackup,
          ),
          const SizedBox(height: 8),
          _OptionCardMat(
            icon: Icons.restore_outlined,
            title: 'Restore from backup',
            subtitle: 'Deletes all current data, then imports the file',
            onTap: _restoreFullBackup,
          ),

          // iCloud section (iOS only)
          if (Platform.isIOS) ...[
            const SizedBox(height: 16),
            Text(
              'iCloud',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondary,
              ),
            ),
            const SizedBox(height: 8),
            if (!_icloudMetaLoaded)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Checking iCloud…',
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                  ],
                ),
              )
            else if (!_icloudAvailable)
              Text(
                'iCloud is not available. Sign in to iCloud on this device '
                'and ensure iCloud Drive is enabled.',
                style: TextStyle(fontSize: 13, height: 1.35, color: secondary),
              )
            else ...[
              _OptionCardMat(
                icon: Icons.cloud_upload_outlined,
                title: 'Save backup to iCloud',
                subtitle: 'Replaces any previous iCloud backup for this app',
                onTap: _saveBackupToIcloud,
              ),
              const SizedBox(height: 8),
              _OptionCardMat(
                icon: Icons.cloud_download_outlined,
                title: 'Restore from iCloud',
                subtitle: _icloudBackupAgeLabel() != null
                    ? 'Last saved: ${_icloudBackupAgeLabel()}'
                    : 'Uses the latest file saved from this app',
                onTap: _restoreFromIcloud,
              ),
            ],
          ],

          const SizedBox(height: 24),

          // ── Status message ───────────────────────────────────────
          if (_statusMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(color: primary),
                        ),
                      ),
                    ],
                  ),
                  if (_lastImportedEnvUid != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          _closeImportAndGoToEnvironment(_lastImportedEnvUid!),
                      icon: Icon(
                        Icons.arrow_forward_outlined,
                        size: 16,
                        color: primary,
                      ),
                      label: Text(
                        'View & fill variables',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ── Import ───────────────────────────────────────────────
          _SectionHeaderMat(title: 'Import', color: secondary),
          const SizedBox(height: 12),
          _OptionCardMat(
            icon: Icons.description_outlined,
            title: 'Collection JSON (v2.1)',
            subtitle: 'Import requests + auto-create variable environment',
            onTap: _importCollectionFile,
          ),
          const SizedBox(height: 8),
          _OptionCardMat(
            icon: Icons.public_outlined,
            title: 'Environment JSON',
            subtitle: 'Import a v2.x environment export JSON file',
            onTap: _importCollectionEnvironment,
          ),
          const SizedBox(height: 8),
          _OptionCardMat(
            icon: Icons.code_outlined,
            title: 'cURL Command',
            subtitle: 'Paste a cURL command to import a request',
            onTap: _importCurl,
          ),

          // ── Export ───────────────────────────────────────────────
          const SizedBox(height: 24),
          _SectionHeaderMat(title: 'Export', color: secondary),
          const SizedBox(height: 12),
          if (collections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No collections to export',
                style: TextStyle(color: secondary),
              ),
            )
          else
            ...collections.map(
              (col) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Builder(
                  builder: (cardContext) => _OptionCardMat(
                    icon: Icons.folder_outlined,
                    title: col.name,
                    subtitle: 'Export as collection v2.1 JSON',
                    onTap: () => _exportCollection(
                      col.uid,
                      sharePositionOrigin: _shareAnchorRect(cardContext),
                    ),
                  ),
                ),
              ),
            ),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This will permanently delete all collections, environments, '
          'request history, and saved WebSocket messages on this device, '
          'then replace them with the backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from iCloud?'),
        content: const Text(
          'This will permanently delete all collections, environments, '
          'request history, and saved WebSocket messages on this device, '
          'then replace them with the iCloud backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            'Restored from iCloud: '
            '${data.collections.length} collection(s), '
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
      final collection = CollectionV21Importer.import(content);
      await ref.read(collectionsProvider.notifier).importCollection(collection);

      final varNames = CollectionV21Importer.extractVariableNames(content);
      String? createdEnvUid;
      if (varNames.isNotEmpty) {
        final environment = _buildEnvironmentFromVarNames(
          '${collection.name} Variables',
          varNames,
        );
        createdEnvUid = environment.uid;
        await ref
            .read(environmentsProvider.notifier)
            .importEnvironment(environment);
      }

      setState(() {
        _lastImportedEnvUid = createdEnvUid;
        _statusMessage = createdEnvUid != null
            ? 'Imported "${collection.name}" · created environment with ${varNames.length} variables'
            : 'Imported "${collection.name}" successfully';
      });
      await _showPostImportExportAd();
    } catch (e) {
      _showError(e.toString());
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
      final env = CollectionV21Importer.importEnvironment(content);
      await ref.read(environmentsProvider.notifier).importEnvironment(env);

      setState(() {
        _lastImportedEnvUid = env.uid;
        _statusMessage =
            'Imported environment "${env.name}" with ${env.variables.length} variables';
      });
      await _showPostImportExportAd();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Environment _buildEnvironmentFromVarNames(
    String name,
    List<String> varNames,
  ) {
    final now = DateTime.now();
    return Environment(
      uid: _uuid.v4(),
      name: name,
      variables: varNames
          .map((k) => EnvironmentVariable(uid: _uuid.v4(), key: k, value: ''))
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _importCurl() async {
    final controller = TextEditingController();
    final curlCommand = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(ctx).unfocus(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    'Import cURL',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Paste a cURL command to import a request',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: controller,
                    maxLines: 6,
                    minLines: 4,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                    ),
                    decoration: const InputDecoration(
                      hintText: "curl -X GET 'https://api.example.com'",
                      hintStyle: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                      ),
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
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppGradientButton.material(
                          fullWidth: true,
                          onPressed: () =>
                              Navigator.pop(ctx, controller.text.trim()),
                          child: const Text('Import'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
    final targetCollection = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Save to Collection',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          ...collections.map(
            (col) => ListTile(
              title: Text(col.name),
              onTap: () => Navigator.pop(ctx, col.uid),
            ),
          ),
          ListTile(
            title: const Text('Cancel', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 8),
        ],
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
}

class _SectionHeaderMat extends StatelessWidget {
  const _SectionHeaderMat({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

class _OptionCardMat extends StatelessWidget {
  const _OptionCardMat({
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
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primary, size: 20),
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
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: secondary),
            ],
          ),
        ),
      ),
    );
  }
}
