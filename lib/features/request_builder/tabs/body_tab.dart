import 'dart:convert';
import 'dart:math' as math;

import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/json_auto_repair.dart';
import 'package:aun_reqstudio/core/utils/json_comment_stripper.dart';
import 'package:aun_reqstudio/domain/enums/body_type.dart';
import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:aun_reqstudio/domain/models/request_body.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/form_data_fields_editor.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BodyTab extends ConsumerStatefulWidget {
  const BodyTab({super.key});

  @override
  ConsumerState<BodyTab> createState() => _BodyTabState();
}

class _BodyTabState extends ConsumerState<BodyTab> {
  /// Chips + separator need ~52px; below this + editor minimum, use a scroll fallback.
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
      final proceed = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Pretty print'),
          content: const Text(
            'Lines that start with // (comments) will be removed. '
            'They cannot be kept in formatted JSON.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
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
      final proceed = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Auto repair'),
          content: const Text(
            'Line comments (//) and block comments (/* */) will be removed '
            'if present. Missing commas between properties or array items, '
            'trailing commas, and a leading BOM will be fixed when possible.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
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
    // Preserve current text when switching between raw types
    final currentText = _bodyController.text;

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
        final divider = _buildBodyDivider(context);

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
              child: _buildEditor(context, body, currentType, squeezed: false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypeStrip(BuildContext context, BodyType currentType) {
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
                  color: selected
                      ? CupertinoTheme.of(context).primaryColor
                      : CupertinoColors.tertiarySystemFill.resolveFrom(context),
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
    );
  }

  Widget _buildBodyDivider(BuildContext context) {
    return Container(
      height: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    RequestBody body,
    BodyType type, {
    required bool squeezed,
    double rawFieldMinHeight = 220,
  }) {
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
        final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
        final editorBg = isDark
            ? const Color(0xFF1E1E1E)
            : CupertinoColors.systemBackground.resolveFrom(context);
        final editorFg = isDark
            ? const Color(0xFFABB2BF)
            : CupertinoColors.label.resolveFrom(context);
        final highlightLang = switch (type) {
          BodyType.rawJson => 'json',
          BodyType.rawXml => 'xml',
          BodyType.rawHtml => 'html',
          _ => 'plaintext',
        };
        final jsonInvalid =
            type == BodyType.rawJson &&
            !isValidJsonBodyContent(_bodyController.text);

        final Widget editorChrome;
        if (_syntaxHighlight) {
          editorChrome = ColoredBox(
            color: editorBg,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
          final textField = CupertinoTextField(
            controller: _bodyController,
            undoController: _bodyUndoController,
            expands: !squeezed,
            maxLines: null,
            minLines: null,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
              height: 1.6,
              color: editorFg,
            ),
            decoration: const BoxDecoration(),
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

        return Column(
          children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        if (jsonInvalid) ...[
                          const SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.exclamationmark_circle_fill,
                            size: 14,
                            color: CupertinoColors.destructiveRed.resolveFrom(
                              context,
                            ),
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 96),
                            child: Text(
                              'Invalid JSON',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.destructiveRed
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
                                      onTap: () => _bodyUndoController.undo(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          CupertinoIcons.arrow_uturn_left,
                                          size: 18,
                                          color: CupertinoTheme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                      ),
                                    ),
                                  if (_bodyUndoController.value.canRedo)
                                    GestureDetector(
                                      onTap: () => _bodyUndoController.redo(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          CupertinoIcons.arrow_uturn_right,
                                          size: 18,
                                          color: CupertinoTheme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                      ),
                                    ),
                                  if (_bodyUndoController.value.canUndo ||
                                      _bodyUndoController.value.canRedo)
                                    const SizedBox(width: 4),
                                ],
                                if (type == BodyType.rawJson &&
                                    jsonInvalid) ...[
                                  GestureDetector(
                                    onTap: () => _repairJson(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoTheme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.wrench,
                                            size: 13,
                                            color: CupertinoTheme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Repair',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: CupertinoTheme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                GestureDetector(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    setState(
                                      () =>
                                          _syntaxHighlight = !_syntaxHighlight,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _syntaxHighlight
                                          ? CupertinoTheme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.22)
                                          : CupertinoColors.tertiarySystemFill
                                                .resolveFrom(context),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.color_filter,
                                          size: 13,
                                          color: CupertinoTheme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _syntaxHighlight
                                              ? 'Edit'
                                              : 'Highlight',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: CupertinoTheme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (type == BodyType.rawJson) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _formatJson(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoTheme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.textformat,
                                            size: 13,
                                            color: CupertinoTheme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pretty Print',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: CupertinoTheme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
            ),
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
        final formEditor = FormDataFieldsEditor(
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
        final urlEditor = KeyValueEditor(
          shrinkWrap: squeezed,
          rows: fields
              .map((f) => (key: f.key, value: f.value, isEnabled: f.isEnabled))
              .toList(),
          keyPlaceholder: 'Field name',
          valuePlaceholder: 'Value',
          onChanged: (rows) {
            ref
                .read(requestBuilderProvider.notifier)
                .setBody(
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
                CupertinoIcons.doc,
                size: 48,
                color: CupertinoTheme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.5),
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
              AppGradientButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.single.path != null) {
                    ref
                        .read(requestBuilderProvider.notifier)
                        .setBody(
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
