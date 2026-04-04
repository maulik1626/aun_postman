import 'dart:convert';

import 'package:aun_postman/domain/enums/body_type.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/features/request_builder/widgets/key_value_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/json.dart' as hl_json;
import 'package:highlight/languages/xml.dart' as hl_xml;

class BodyTab extends ConsumerStatefulWidget {
  const BodyTab({super.key});

  @override
  ConsumerState<BodyTab> createState() => _BodyTabState();
}

class _BodyTabState extends ConsumerState<BodyTab> {
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    final body = ref.read(requestBuilderProvider).body;
    _codeController = CodeController(
      text: _rawContent(body),
      language: _languageFor(_currentType(body)),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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

  // Returns the highlight mode for the given body type.
  // JSON and XML/HTML use real parsers; Text uses null (no highlighting).
  dynamic _languageFor(BodyType type) => switch (type) {
        BodyType.rawJson => hl_json.json,
        BodyType.rawXml => hl_xml.xml,
        BodyType.rawHtml => hl_xml.xml, // HTML treated as XML for highlighting
        _ => null,
      };

  void _formatJson(BuildContext context) {
    try {
      final decoded = jsonDecode(_codeController.text);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      _codeController.text = formatted;
      ref
          .read(requestBuilderProvider.notifier)
          .setBody(RawJsonBody(content: formatted));
    } catch (_) {
      _showToast(context, 'Invalid JSON — cannot format');
    }
  }

  void _showToast(BuildContext context, String message) {
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
          child: Text(
            message,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }

  void _onTypeChanged(BodyType type) {
    // Preserve current text when switching between raw types
    final currentText = _codeController.text;
    _codeController.language = _languageFor(type);

    RequestBody newBody = switch (type) {
      BodyType.none => const NoBody(),
      BodyType.rawJson => RawJsonBody(content: currentText),
      BodyType.rawXml => RawXmlBody(content: currentText),
      BodyType.rawText => RawTextBody(content: currentText),
      BodyType.rawHtml => RawHtmlBody(content: currentText),
      BodyType.formData => const FormDataBody(),
      BodyType.urlEncoded => const UrlEncodedBody(),
      BodyType.binary => const BinaryBody(filePath: ''),
    };
    ref.read(requestBuilderProvider.notifier).setBody(newBody);
  }

  @override
  Widget build(BuildContext context) {
    // Sync controller when a saved request is loaded from a collection.
    ref.listen(
      requestBuilderProvider.select((s) => s.loadedRequestUid),
      (_, __) {
        final body = ref.read(requestBuilderProvider).body;
        final newContent = _rawContent(body);
        final newType = _currentType(body);
        if (_codeController.text != newContent) {
          _codeController.text = newContent;
        }
        _codeController.language = _languageFor(newType);
      },
    );

    final body = ref.watch(requestBuilderProvider.select((s) => s.body));
    final currentType = _currentType(body);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector — scrollable pill chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
        Expanded(child: _buildEditor(context, body, currentType, isDark)),
      ],
    );
  }

  Widget _buildEditor(
      BuildContext context, RequestBody body, BodyType type, bool isDark) {
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
        final typeLabel = switch (type) {
          BodyType.rawJson => 'JSON',
          BodyType.rawXml => 'XML',
          BodyType.rawHtml => 'HTML',
          _ => 'TEXT',
        };
        return Column(
          children: [
            // Toolbar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    CupertinoColors.tertiarySystemFill.resolveFrom(context),
                border: Border(
                  bottom: BorderSide(
                    color:
                        CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context),
                    ),
                  ),
                  const Spacer(),
                  if (type == BodyType.rawJson)
                    GestureDetector(
                      onTap: () => _formatJson(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CupertinoTheme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.textformat,
                                size: 13,
                                color:
                                    CupertinoTheme.of(context).primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Pretty Print',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    CupertinoTheme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Syntax-highlighted code editor
            Expanded(
              child: CodeTheme(
                data: CodeThemeData(
                  styles: isDark ? atomOneDarkTheme : atomOneLightTheme,
                ),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: _codeController,
                    minLines: null,
                    expands: false,
                    wrap: false,
                    background: isDark
                        ? const Color(0xFF1E1E1E)
                        : CupertinoColors.systemBackground
                            .resolveFrom(context),
                    textStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      height: 1.6,
                    ),
                    onChanged: (value) {
                      final updated = switch (type) {
                        BodyType.rawJson => RawJsonBody(content: value),
                        BodyType.rawXml => RawXmlBody(content: value),
                        BodyType.rawHtml => RawHtmlBody(content: value),
                        _ => RawTextBody(content: value),
                      };
                      ref
                          .read(requestBuilderProvider.notifier)
                          .setBody(updated);
                    },
                  ),
                ),
              ),
            ),
          ],
        );

      case BodyType.formData:
        final fields =
            body is FormDataBody ? body.fields : const <FormDataField>[];
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
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
          padding: const EdgeInsets.only(bottom: 24),
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
                color: CupertinoTheme.of(context)
                    .primaryColor
                    .withValues(alpha: 0.5),
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
