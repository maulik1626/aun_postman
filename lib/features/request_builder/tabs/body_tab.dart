import 'dart:convert';

import 'package:aun_postman/domain/enums/body_type.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/features/request_builder/widgets/key_value_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BodyTab extends ConsumerStatefulWidget {
  const BodyTab({super.key});

  @override
  ConsumerState<BodyTab> createState() => _BodyTabState();
}

class _BodyTabState extends ConsumerState<BodyTab> {
  late TextEditingController _rawController;

  @override
  void initState() {
    super.initState();
    final body = ref.read(requestBuilderProvider).body;
    _rawController = TextEditingController(text: _rawContent(body));
  }


  String _rawContent(RequestBody body) => switch (body) {
        RawJsonBody(:final content) => content,
        RawXmlBody(:final content) => content,
        RawTextBody(:final content) => content,
        RawHtmlBody(:final content) => content,
        _ => '',
      };

  BodyType _currentType(RequestBody body) => switch (body) {
        NoBody() => BodyType.none,
        RawJsonBody() => BodyType.rawJson,
        RawXmlBody() => BodyType.rawXml,
        RawTextBody() => BodyType.rawText,
        RawHtmlBody() => BodyType.rawHtml,
        FormDataBody() => BodyType.formData,
        UrlEncodedBody() => BodyType.urlEncoded,
        BinaryBody() => BodyType.binary,
      };

  void _formatJson(BuildContext context, BodyType type) {
    if (type != BodyType.rawJson) return;
    try {
      final decoded = jsonDecode(_rawController.text);
      final formatted =
          const JsonEncoder.withIndent('  ').convert(decoded);
      _rawController.text = formatted;
      ref
          .read(requestBuilderProvider.notifier)
          .setBody(RawJsonBody(content: formatted));
    } catch (_) {
      // Show inline error toast — invalid JSON
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => Positioned(
          bottom: 60,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.destructiveRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Invalid JSON — cannot format',
              style: TextStyle(color: CupertinoColors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      overlay.insert(entry);
      Future.delayed(const Duration(seconds: 2), entry.remove);
    }
  }

  void _onTypeChanged(BodyType type) {
    RequestBody newBody = switch (type) {
      BodyType.none => const NoBody(),
      BodyType.rawJson => RawJsonBody(content: _rawController.text),
      BodyType.rawXml => RawXmlBody(content: _rawController.text),
      BodyType.rawText => RawTextBody(content: _rawController.text),
      BodyType.rawHtml => RawHtmlBody(content: _rawController.text),
      BodyType.formData => const FormDataBody(),
      BodyType.urlEncoded => const UrlEncodedBody(),
      BodyType.binary => const BinaryBody(filePath: ''),
    };
    ref.read(requestBuilderProvider.notifier).setBody(newBody);
  }

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When a request is loaded from a collection, sync the raw text controller
    // to the newly loaded body content (loadedRequestUid changes on load).
    ref.listen(
      requestBuilderProvider.select((s) => s.loadedRequestUid),
      (_, __) {
        final newContent = _rawContent(ref.read(requestBuilderProvider).body);
        if (_rawController.text != newContent) {
          _rawController.text = newContent;
        }
      },
    );

    final body = ref.watch(requestBuilderProvider.select((s) => s.body));
    final currentType = _currentType(body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector — scrollable pill chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: BodyType.values.map((type) {
              final selected = currentType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => _onTypeChanged(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? CupertinoTheme.of(context).primaryColor
                          : CupertinoColors.tertiarySystemFill
                              .resolveFrom(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? CupertinoColors.white
                            : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          height: 0.5,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        Expanded(child: _buildEditor(context, body, currentType)),
      ],
    );
  }

  Widget _buildEditor(
      BuildContext context, RequestBody body, BodyType type) {
    switch (type) {
      case BodyType.none:
        return Center(
          child: Text(
            'No Body',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        );

      case BodyType.rawJson:
      case BodyType.rawXml:
      case BodyType.rawText:
      case BodyType.rawHtml:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format toolbar — only for JSON
              if (type == BodyType.rawJson)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minSize: 0,
                        color: CupertinoColors.tertiarySystemFill
                            .resolveFrom(context),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () => _formatJson(context, type),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.textformat,
                                size: 14,
                                color: CupertinoTheme.of(context).primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Format',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoTheme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: CupertinoTextField(
            controller: _rawController,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
            ),
            placeholder: type == BodyType.rawJson
                ? '{\n  "key": "value"\n}'
                : 'Enter body content',
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(context),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            onChanged: (value) {
              final updated = switch (type) {
                BodyType.rawJson => RawJsonBody(content: value),
                BodyType.rawXml => RawXmlBody(content: value),
                BodyType.rawHtml => RawHtmlBody(content: value),
                _ => RawTextBody(content: value),
              };
              ref.read(requestBuilderProvider.notifier).setBody(updated);
            },
          ),
        ),
          ],
          ),
        );

      case BodyType.formData:
        final fields =
            body is FormDataBody ? body.fields : const <FormDataField>[];
        return SingleChildScrollView(
          child: KeyValueEditor(
            rows: fields
                .map((f) =>
                    (key: f.key, value: f.value, isEnabled: f.isEnabled))
                .toList(),
            keyPlaceholder: 'Field name',
            valuePlaceholder: 'Value',
            onChanged: (rows) {
              ref.read(requestBuilderProvider.notifier).setBody(
                    FormDataBody(
                      fields: rows
                          .map(
                            (r) => FormDataField(
                              key: r.key,
                              value: r.value,
                              isEnabled: r.isEnabled,
                            ),
                          )
                          .toList(),
                    ),
                  );
            },
          ),
        );

      case BodyType.urlEncoded:
        final fields =
            body is UrlEncodedBody ? body.fields : const <KeyValuePair>[];
        return SingleChildScrollView(
          child: KeyValueEditor(
            rows: fields
                .map((f) =>
                    (key: f.key, value: f.value, isEnabled: f.isEnabled))
                .toList(),
            keyPlaceholder: 'Field name',
            valuePlaceholder: 'Value',
            onChanged: (rows) {
              ref.read(requestBuilderProvider.notifier).setBody(
                    UrlEncodedBody(
                      fields: rows
                          .map(
                            (r) => KeyValuePair(
                              key: r.key,
                              value: r.value,
                              isEnabled: r.isEnabled,
                            ),
                          )
                          .toList(),
                    ),
                  );
            },
          ),
        );

      case BodyType.binary:
        final filePath = body is BinaryBody ? body.filePath : '';
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.doc,
                size: 48,
                color:
                    CupertinoTheme.of(context).primaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                filePath.isEmpty
                    ? 'No file selected'
                    : filePath.split('/').last,
                style: const TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 13),
              ),
              const SizedBox(height: 16),
              AppGradientButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.single.path != null) {
                    ref.read(requestBuilderProvider.notifier).setBody(
                          BinaryBody(filePath: result.files.single.path!),
                        );
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add_circled, size: 20),
                    SizedBox(width: 6),
                    Text('Choose File'),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
