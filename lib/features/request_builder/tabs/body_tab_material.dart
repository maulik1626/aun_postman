import 'dart:convert';
import 'dart:math' as math;

import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/json_auto_repair.dart';
import 'package:aun_reqstudio/core/utils/json_comment_stripper.dart';
import 'package:aun_reqstudio/domain/enums/body_type.dart';
import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:aun_reqstudio/domain/models/request_body.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/form_data_fields_editor_material.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor_material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BodyTabMaterial extends ConsumerStatefulWidget {
  const BodyTabMaterial({super.key});

  @override
  ConsumerState<BodyTabMaterial> createState() => _BodyTabMaterialState();
}

class _BodyTabMaterialState extends ConsumerState<BodyTabMaterial> {
  static const double _kTypeStripApproxHeight = 52;
  static const double _kMinEditorComfortHeight = 72;

  late TextEditingController _bodyController;
  late final UndoHistoryController _bodyUndoController;
  bool _syntaxHighlight = false;

  void _onBodyUndoHistoryChanged() {
    if (mounted) setState(() {});
  }

  void _onBodyControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _bodyUndoController = UndoHistoryController();
    _bodyUndoController.addListener(_onBodyUndoHistoryChanged);
    final body = ref.read(requestBuilderProvider).body;
    _bodyController = TextEditingController(text: _rawContent(body));
    _bodyController.addListener(_onBodyControllerChanged);
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyControllerChanged);
    _bodyUndoController.removeListener(_onBodyUndoHistoryChanged);
    _bodyUndoController.dispose();
    _bodyController.dispose();
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

  Future<void> _formatJson(BuildContext context) async {
    if (!context.mounted) return;
    if (jsonHasLineComments(_bodyController.text)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pretty print'),
          content: const Text(
            'Lines that start with // (comments) will be removed. '
            'They cannot be kept in formatted JSON.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pretty print'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    try {
      final decoded = jsonDecode(
        stripJsonLineComments(_bodyController.text).trim(),
      );
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      _bodyController.text = formatted;
      ref
          .read(requestBuilderProvider.notifier)
          .setBody(RawJsonBody(content: formatted));
    } catch (_) {
      if (!context.mounted) return;
      UserNotification.show(
        context: context,
        title: 'Body',
        body: 'Invalid JSON — cannot format',
      );
    }
  }

  Future<void> _repairJson(BuildContext context) async {
    if (!context.mounted) return;
    if (jsonRepairMayRemoveComments(_bodyController.text)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Auto repair'),
          content: const Text(
            'Line comments (//) and block comments (/* */) will be removed '
            'if present. Missing commas between properties or array items, '
            'trailing commas, and a leading BOM will be fixed when possible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Repair'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    final repaired = tryAutoRepairJson(_bodyController.text);
    if (repaired == null) {
      if (!context.mounted) return;
      UserNotification.show(
        context: context,
        title: 'Body',
        body: 'Could not repair JSON',
      );
      return;
    }
    _bodyController.text = repaired;
    ref
        .read(requestBuilderProvider.notifier)
        .setBody(RawJsonBody(content: repaired));
  }

  void _onTypeChanged(BodyType type) {
    setState(() => _syntaxHighlight = false);
    final currentText = _bodyController.text;
    final RequestBody newBody = switch (type) {
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
    ref.listen(requestBuilderProvider.select((s) => s.loadedRequestUid), (
      _,
      __,
    ) {
      final body = ref.read(requestBuilderProvider).body;
      final newContent = _rawContent(body);
      if (_bodyController.text != newContent) {
        _bodyController.text = newContent;
      }
    });

    final body = ref.watch(requestBuilderProvider.select((s) => s.body));
    final currentType = _currentType(body);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final squeezed =
            maxH.isFinite &&
            maxH < _kTypeStripApproxHeight + _kMinEditorComfortHeight;

        final strip = _buildTypeStrip(context, currentType);
        final divider = Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).dividerColor,
        );

        if (squeezed) {
          final screenH = MediaQuery.sizeOf(context).height;
          final rawMinH = math.max(200.0, screenH * 0.32);
          return SingleChildScrollView(
            primary: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                strip,
                divider,
                _buildEditor(
                  context,
                  body,
                  currentType,
                  squeezed: true,
                  rawFieldMinHeight: rawMinH,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            strip,
            divider,
            Expanded(
              child:
                  _buildEditor(context, body, currentType, squeezed: false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypeStrip(BuildContext context, BodyType currentType) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
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
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? primary : surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    RequestBody body,
    BodyType type, {
    required bool squeezed,
    double rawFieldMinHeight = 220,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    switch (type) {
      case BodyType.none:
        return Center(
          child: Text(
            'No Body',
            style: TextStyle(color: secondary),
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
        final isDark =
            Theme.of(context).brightness == Brightness.dark;
        final editorBg = isDark
            ? const Color(0xFF1E1E1E)
            : Theme.of(context).colorScheme.surface;
        final editorFg = isDark
            ? const Color(0xFFABB2BF)
            : Theme.of(context).colorScheme.onSurface;
        final highlightLang = switch (type) {
          BodyType.rawJson => 'json',
          BodyType.rawXml => 'xml',
          BodyType.rawHtml => 'html',
          _ => 'plaintext',
        };
        final jsonInvalid = type == BodyType.rawJson &&
            !isValidJsonBodyContent(_bodyController.text);

        final Widget editorChrome;
        if (_syntaxHighlight) {
          editorChrome = ColoredBox(
            color: editorBg,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minWidth: constraints.maxWidth),
                  child: HighlightView(
                    _bodyController.text,
                    language: highlightLang,
                    theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                    textStyle: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      height: 1.6,
                      color: editorFg,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          final textField = TextField(
            controller: _bodyController,
            undoController: _bodyUndoController,
            expands: !squeezed,
            maxLines: squeezed ? null : null,
            minLines: null,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
              height: 1.6,
              color: editorFg,
            ),
            decoration: InputDecoration.collapsed(
              hintText: '',
              fillColor: editorBg,
              filled: true,
            ),
            cursorColor: editorFg,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            onChanged: (value) {
              final updated = switch (type) {
                BodyType.rawJson => RawJsonBody(content: value),
                BodyType.rawXml => RawXmlBody(content: value),
                BodyType.rawHtml => RawHtmlBody(content: value),
                _ => RawTextBody(content: value),
              };
              ref.read(requestBuilderProvider.notifier).setBody(updated);
            },
          );
          editorChrome = ColoredBox(color: editorBg, child: textField);
        }

        // Toolbar
        final toolbar = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: secondary,
                    ),
                  ),
                  if (jsonInvalid) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.error,
                      size: 14,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: const Text(
                        'Invalid JSON',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_syntaxHighlight) ...[
                              if (_bodyUndoController.value.canUndo)
                                GestureDetector(
                                  onTap: () =>
                                      _bodyUndoController.undo(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.undo,
                                      size: 18,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              if (_bodyUndoController.value.canRedo)
                                GestureDetector(
                                  onTap: () =>
                                      _bodyUndoController.redo(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.redo,
                                      size: 18,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              if (_bodyUndoController.value.canUndo ||
                                  _bodyUndoController.value.canRedo)
                                const SizedBox(width: 4),
                            ],
                            if (type == BodyType.rawJson &&
                                jsonInvalid) ...[
                              _ToolbarChip(
                                icon: Icons.build,
                                label: 'Repair',
                                primary: primary,
                                onTap: () => _repairJson(context),
                              ),
                              const SizedBox(width: 8),
                            ],
                            _ToolbarChip(
                              icon: _syntaxHighlight
                                  ? Icons.edit
                                  : Icons.color_lens_outlined,
                              label: _syntaxHighlight
                                  ? 'Edit'
                                  : 'Highlight',
                              primary: primary,
                              isActive: _syntaxHighlight,
                              onTap: () {
                                FocusManager.instance.primaryFocus
                                    ?.unfocus();
                                setState(
                                  () => _syntaxHighlight =
                                      !_syntaxHighlight,
                                );
                              },
                            ),
                            if (type == BodyType.rawJson) ...[
                              const SizedBox(width: 8),
                              _ToolbarChip(
                                icon: Icons.format_align_left,
                                label: 'Pretty Print',
                                primary: primary,
                                onTap: () => _formatJson(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );

        return Column(
          children: [
            toolbar,
            if (squeezed)
              SizedBox(height: rawFieldMinHeight, child: editorChrome)
            else
              Expanded(child: editorChrome),
          ],
        );

      case BodyType.formData:
        final fields = body is FormDataBody
            ? body.fields
            : const <FormDataField>[];
        final loadedUid = ref.watch(
          requestBuilderProvider.select((s) => s.loadedRequestUid),
        );
        final formEditor = FormDataFieldsEditorMaterial(
          key: ValueKey('${loadedUid ?? 'new'}-formdata'),
          shrinkWrap: squeezed,
          fields: fields,
          onChanged: (next) {
            ref
                .read(requestBuilderProvider.notifier)
                .setBody(FormDataBody(fields: next));
          },
        );
        if (squeezed) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: formEditor,
          );
        }
        return formEditor;

      case BodyType.urlEncoded:
        final fields = body is UrlEncodedBody
            ? body.fields
            : const <KeyValuePair>[];
        final urlEditor = KeyValueEditorMaterial(
          shrinkWrap: squeezed,
          rows: fields
              .map(
                (f) =>
                    (key: f.key, value: f.value, isEnabled: f.isEnabled),
              )
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
        );
        if (squeezed) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: urlEditor,
          );
        }
        return urlEditor;

      case BodyType.binary:
        final filePath = body is BinaryBody ? body.filePath : '';
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 48,
                color: primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                filePath.isEmpty
                    ? 'No file selected'
                    : filePath.split('/').last,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              AppGradientButton.material(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    allowMultiple: false,
                  );
                  if (result != null &&
                      result.files.single.path != null) {
                    ref
                        .read(requestBuilderProvider.notifier)
                        .setBody(
                          BinaryBody(
                            filePath: result.files.single.path!,
                          ),
                        );
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
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

// ── Toolbar chip ──────────────────────────────────────────────────────────────

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? primary.withValues(alpha: 0.22)
              : primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
