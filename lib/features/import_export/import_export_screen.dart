import 'package:aun_postman/core/utils/curl_parser.dart';
import 'package:aun_postman/core/utils/postman_v2_exporter.dart';
import 'package:aun_postman/core/utils/postman_v2_importer.dart';
import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/features/collections/providers/collections_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Import / Export'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 44,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.xmark),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_statusMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(context)
                        .primaryColor
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _SectionHeader(title: 'Import'),
              const SizedBox(height: 12),

              _OptionCard(
                icon: CupertinoIcons.doc_text,
                title: 'Postman Collection v2.1',
                subtitle: 'Import a Postman JSON collection file',
                onTap: _importPostmanFile,
              ),
              const SizedBox(height: 8),
              _OptionCard(
                icon: CupertinoIcons.chevron_left_slash_chevron_right,
                title: 'cURL Command',
                subtitle: 'Paste a cURL command to import a request',
                onTap: _importCurl,
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Export'),
              const SizedBox(height: 12),

              if (collections.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No collections to export',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                        subtitle: 'Export as Postman v2.1 JSON',
                        onTap: () => _exportCollection(
                          col.uid,
                          sharePositionOrigin:
                              _shareAnchorRect(cardContext),
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
      ),
    );
  }

  Future<void> _importPostmanFile() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final content = await File(result.files.single.path!).readAsString();
      final collection = PostmanV2Importer.import(content);
      await ref
          .read(collectionsProvider.notifier)
          .importCollection(collection);

      setState(
          () => _statusMessage = 'Imported "${collection.name}" successfully');
    } catch (e) {
      _showError(e.toString());
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
          color:
              CupertinoColors.systemGroupedBackground.resolveFrom(ctx),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom +
              16,
        ),
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
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Paste a cURL command to import a request',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      CupertinoColors.secondaryLabel.resolveFrom(ctx),
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
                  color: CupertinoColors.tertiarySystemBackground
                      .resolveFrom(ctx),
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
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      color: CupertinoColors.tertiarySystemFill
                          .resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              CupertinoColors.label.resolveFrom(ctx),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppGradientButton(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
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

    final collection =
        collections.firstWhere((c) => c.uid == targetCollection);
    final updatedRequest =
        request.copyWith(collectionUid: targetCollection);
    final updatedCollection = collection.copyWith(
      requests: [...collection.requests, updatedRequest],
    );
    await ref.read(collectionsProvider.notifier).update(updatedCollection);
    setState(() => _statusMessage = 'Request imported successfully');
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
      final collection =
          ref.read(collectionsProvider).firstWhere((c) => c.uid == uid);

      final json = PostmanV2Exporter.export(collection);
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
        subject: '${collection.name} — Postman Collection',
        sharePositionOrigin: origin,
      );

      setState(() => _statusMessage = 'Export ready');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                  color: CupertinoTheme.of(context)
                      .primaryColor
                      .withOpacity(0.15),
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
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context),
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
