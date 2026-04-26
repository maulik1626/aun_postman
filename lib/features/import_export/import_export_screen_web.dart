import 'dart:convert';

import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/web/browser_json_export.dart';
import 'package:aun_reqstudio/app/web/web_toast.dart';
import 'package:aun_reqstudio/core/utils/app_backup.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/core/utils/curl_parser.dart';
import 'package:aun_reqstudio/core/utils/full_backup_json.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/active_environment_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/import_export/json_import_flow.dart';
import 'package:aun_reqstudio/features/websocket/providers/ws_saved_compose_provider.dart';
import 'package:aun_reqstudio/infrastructure/history_repository.dart';
import 'package:aun_reqstudio/infrastructure/ws_saved_compose_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ImportExportScreenWeb extends ConsumerStatefulWidget {
  const ImportExportScreenWeb({
    super.key,
    this.embedded = false,
    this.onEmbeddedNavigateAway,
  });

  /// When true (web workspace right pane), omits [Scaffold] app bar and
  /// [PopScope] so the screen nests inside [ShellScreenWeb].
  final bool embedded;

  /// Called before [context.go] from embedded UI so the shell can clear its
  /// local Import/Export panel override.
  final VoidCallback? onEmbeddedNavigateAway;

  @override
  ConsumerState<ImportExportScreenWeb> createState() =>
      _ImportExportScreenWebState();
}

class _ImportExportScreenWebState extends ConsumerState<ImportExportScreenWeb> {
  static const _maxImportFileBytes = 5 * 1024 * 1024;
  bool _isLoading = false;
  String? _statusMessage;
  String? _lastImportedEnvUid;

  void _handleBackNavigation() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(AppRoutes.collections);
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);
    final primary = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.embedded) ...[
          Text(
            'Import / Export',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _SectionHeaderMat(title: 'Full backup', color: secondary),
            const SizedBox(height: 8),
            Text(
              'Export or restore collections, environments, request history, '
              'and saved WebSocket composer messages. Restore replaces existing '
              'data for these categories.',
              style: TextStyle(fontSize: 13, height: 1.35, color: secondary),
            ),
            const SizedBox(height: 12),
            _OptionCardMat(
              icon: Icons.archive_outlined,
              title: 'Export all data',
              subtitle: 'Download a full backup JSON file',
              onTap: _exportFullBackup,
            ),
            const SizedBox(height: 8),
            _OptionCardMat(
              icon: Icons.restore_outlined,
              title: 'Restore from backup',
              subtitle: 'Replace local data from a backup JSON file',
              onTap: _restoreFullBackup,
            ),
            const SizedBox(height: 24),
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
                        onPressed: () {
                          widget.onEmbeddedNavigateAway?.call();
                          context.go(
                            '${AppRoutes.environments}/$_lastImportedEnvUid',
                          );
                        },
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
                      ),
                    ],
                  ],
                ),
              ),
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
                  child: _OptionCardMat(
                    icon: Icons.folder_outlined,
                    title: col.name,
                    subtitle: 'Download as collection v2.1 JSON',
                    onTap: () => _exportCollection(col.uid),
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
    );

    if (widget.embedded) {
      return Material(color: scheme.surface, child: body);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _handleBackNavigation,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Import / Export'),
        ),
        body: body,
      ),
    );
  }

  Future<String?> _pickSingleJsonText({required String purpose}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final name = file.name.toLowerCase();
    if (!name.endsWith('.json')) {
      throw Exception('Please select a .json file for $purpose.');
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('Unable to read selected file bytes.');
    }
    if (bytes.length > _maxImportFileBytes) {
      throw Exception('File is too large. Maximum supported size is 5 MB.');
    }
    return utf8.decode(bytes);
  }

  Future<void> _exportFullBackup() async {
    setState(() => _isLoading = true);
    try {
      final json = await buildFullBackupJson(ref);
      final stamp = DateTime.now().toIso8601String().split('T').first;
      downloadJsonFile(
        fileName: 'aun_reqstudio_backup_$stamp.json',
        content: json,
      );
      if (!mounted) return;
      setState(() => _statusMessage = 'Full backup downloaded.');
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
          'This will replace existing collections, environments, request '
          'history, and saved WebSocket composer data.',
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
      final content = await _pickSingleJsonText(purpose: 'backup restore');
      if (content == null) return;
      final data = AppBackup.parse(content);
      await _applyFullRestore(data);

      if (!mounted) return;
      setState(() {
        _lastImportedEnvUid = null;
        _statusMessage =
            'Restored ${data.collections.length} collection(s), '
            '${data.environments.length} environment(s), '
            '${data.history.length} history entries.';
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
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
      final content = await _pickSingleJsonText(purpose: 'collection import');
      if (content == null) return;
      final outcome =
          await ImportExportJsonImporter.importCollectionFromContent(
            ref: ref,
            content: content,
          );
      _applyJsonImportOutcome(outcome);
    } catch (e) {
      _showError(ImportExportJsonImporter.errorMessageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importCollectionEnvironment() async {
    setState(() => _isLoading = true);
    try {
      final content = await _pickSingleJsonText(purpose: 'environment import');
      if (content == null) return;
      final outcome =
          await ImportExportJsonImporter.importEnvironmentFromContent(
            ref: ref,
            content: content,
          );
      _applyJsonImportOutcome(outcome);
    } catch (e) {
      _showError(ImportExportJsonImporter.errorMessageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importCurl() async {
    final controller = TextEditingController();
    final command = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import cURL'),
        content: SizedBox(
          width: 640,
          child: TextField(
            controller: controller,
            maxLines: 8,
            minLines: 5,
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
            decoration: const InputDecoration(
              hintText: "curl -X GET 'https://api.example.com'",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (command == null || command.isEmpty) return;

    final request = CurlParser.parse(command);
    if (request == null) {
      _showError('Could not parse cURL command.');
      return;
    }
    final collections = ref.read(collectionsProvider);
    if (collections.isEmpty) {
      _showError('Create a collection first to save this request.');
      return;
    }

    final targetCollection = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save to Collection'),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final collection = collections[index];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(collection.name),
                  onTap: () => Navigator.pop(ctx, collection.uid),
                  dense: true,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (targetCollection == null) return;

    final collection = collections.firstWhere((c) => c.uid == targetCollection);
    final updatedCollection = collection.copyWith(
      requests: [
        ...collection.requests,
        request.copyWith(collectionUid: targetCollection),
      ],
    );
    await ref.read(collectionsProvider.notifier).update(updatedCollection);
    if (!mounted) return;
    setState(() => _statusMessage = 'Request imported successfully.');
  }

  Future<void> _exportCollection(String uid) async {
    setState(() => _isLoading = true);
    try {
      final collection = ref
          .read(collectionsProvider)
          .firstWhere((c) => c.uid == uid);
      final json = CollectionV21Exporter.export(collection);
      final safeName = safeJsonFileName(collection.name);
      downloadJsonFile(fileName: '$safeName.json', content: json);
      if (!mounted) return;
      setState(() => _statusMessage = 'Collection export downloaded.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyJsonImportOutcome(JsonImportOutcome outcome) {
    if (!mounted) return;
    setState(() {
      _lastImportedEnvUid = outcome.lastImportedEnvUid;
      _statusMessage = outcome.statusMessage;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    WebToast.show(context, message: message, type: WebToastType.error);
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
