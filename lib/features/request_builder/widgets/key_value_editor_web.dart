import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aun_reqstudio/features/request_builder/widgets/key_value_bulk_parser.dart';

class KeyValueEditorWebRow {
  KeyValueEditorWebRow({
    String key = '',
    String value = '',
    String description = '',
    bool isEnabled = true,
  }) : keyController = TextEditingController(text: key),
       valueController = TextEditingController(text: value),
       descriptionController = TextEditingController(text: description),
       isEnabledNotifier = ValueNotifier<bool>(isEnabled);

  final TextEditingController keyController;
  final TextEditingController valueController;
  final TextEditingController descriptionController;
  final ValueNotifier<bool> isEnabledNotifier;

  bool get isEnabled => isEnabledNotifier.value;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
    descriptionController.dispose();
    isEnabledNotifier.dispose();
  }
}

typedef KeyValueEditorWebChanged =
    void Function(List<({String key, String value, bool isEnabled})>);

// Shared table geometry for both header and row cells.
const double _kWebKvLeadingControlWidth = 38;
const double _kWebKvTrailingActionWidth = 38;
const int _kWebKvKeyFlex = 4;
const int _kWebKvValueFlex = 5;
const int _kWebKvDescriptionFlex = 5;
const double _kWebKvCellHorizontalPadding = 10;

class KeyValueEditorWeb extends StatefulWidget {
  const KeyValueEditorWeb({
    super.key,
    required this.rows,
    required this.onChanged,
    required this.title,
    this.keyPlaceholder = 'Key',
    this.valuePlaceholder = 'Value',
    this.descriptionPlaceholder = 'Description (optional)',
  });

  final List<({String key, String value, bool isEnabled})> rows;
  final KeyValueEditorWebChanged onChanged;
  final String title;
  final String keyPlaceholder;
  final String valuePlaceholder;
  final String descriptionPlaceholder;

  @override
  State<KeyValueEditorWeb> createState() => _KeyValueEditorWebState();
}

class _KeyValueEditorWebState extends State<KeyValueEditorWeb> {
  late List<KeyValueEditorWebRow> _rows;
  late final ScrollController _scrollController;
  final List<KeyValueEditorWebRow> _rowsPendingDispose = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _rows = _buildRowsFromInput(widget.rows);
    if (_rows.isEmpty) _rows.add(KeyValueEditorWebRow());
  }

  @override
  void didUpdateWidget(covariant KeyValueEditorWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _normalize(widget.rows);
    final current = _normalize(_currentSnapshot());
    if (_sameTuples(next, current)) return;
    _syncRowsWithInput(next);
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final row in _rowsPendingDispose) {
      row.dispose();
    }
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _enqueueDispose(Iterable<KeyValueEditorWebRow> rows) {
    _rowsPendingDispose.addAll(rows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rowsPendingDispose.isEmpty) return;
      final pending = List<KeyValueEditorWebRow>.from(_rowsPendingDispose);
      _rowsPendingDispose.clear();
      for (final row in pending) {
        row.dispose();
      }
    });
  }

  void _syncRowsWithInput(
    List<({String key, String value, bool isEnabled})> next,
  ) {
    final targetLength = next.length;
    for (var i = 0; i < targetLength; i++) {
      if (i >= _rows.length) {
        _rows.add(
          KeyValueEditorWebRow(
            key: next[i].key,
            value: next[i].value,
            isEnabled: next[i].isEnabled,
          ),
        );
        continue;
      }
      final row = _rows[i];
      if (row.keyController.text != next[i].key) {
        row.keyController.value = row.keyController.value.copyWith(
          text: next[i].key,
          selection: TextSelection.collapsed(offset: next[i].key.length),
          composing: TextRange.empty,
        );
      }
      if (row.valueController.text != next[i].value) {
        row.valueController.value = row.valueController.value.copyWith(
          text: next[i].value,
          selection: TextSelection.collapsed(offset: next[i].value.length),
          composing: TextRange.empty,
        );
      }
      if (row.isEnabledNotifier.value != next[i].isEnabled) {
        row.isEnabledNotifier.value = next[i].isEnabled;
      }
    }

    if (_rows.length > targetLength) {
      final removed = _rows.sublist(targetLength);
      _rows.removeRange(targetLength, _rows.length);
      _enqueueDispose(removed);
    }
  }

  List<KeyValueEditorWebRow> _buildRowsFromInput(
    List<({String key, String value, bool isEnabled})> input,
  ) {
    return input
        .map(
          (r) => KeyValueEditorWebRow(
            key: r.key,
            value: r.value,
            isEnabled: r.isEnabled,
          ),
        )
        .toList();
  }

  List<({String key, String value, bool isEnabled})> _currentSnapshot() {
    return _rows
        .map(
          (r) => (
            key: r.keyController.text,
            value: r.valueController.text,
            isEnabled: r.isEnabledNotifier.value,
          ),
        )
        .toList();
  }

  List<({String key, String value, bool isEnabled})> _normalize(
    List<({String key, String value, bool isEnabled})> rows,
  ) {
    if (rows.isEmpty) {
      return const [(key: '', value: '', isEnabled: true)];
    }
    return rows;
  }

  bool _sameTuples(
    List<({String key, String value, bool isEnabled})> a,
    List<({String key, String value, bool isEnabled})> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].key != b[i].key ||
          a[i].value != b[i].value ||
          a[i].isEnabled != b[i].isEnabled) {
        return false;
      }
    }
    return true;
  }

  void _notify() {
    widget.onChanged(_currentSnapshot());
  }

  void _addRow() {
    setState(() => _rows.add(KeyValueEditorWebRow()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeRow(int index) {
    if (index < 0 || index >= _rows.length) return;
    final removed = _rows[index];
    setState(() {
      _rows.removeAt(index);
      if (_rows.isEmpty) _rows.add(KeyValueEditorWebRow());
    });
    _notify();
    _enqueueDispose([removed]);
  }

  Future<void> _showBulkEditor() async {
    final initialText = bulkKeyValueRowsToText(
      _currentSnapshot().map(
        (r) => (key: r.key, value: r.value, isEnabled: r.isEnabled),
      ),
    );
    final controller = TextEditingController(text: initialText);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk Edit'),
        content: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste lines like "key:value", "key=value", or paste a JSON object/array. '
                'Nested keys are flattened with dot notation.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 16,
                minLines: 12,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                ),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText:
                      'Content-Type:application/json\nAccept:*/*\n\n{ "page": 1, "limit": 25 }',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (!mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
      return;
    }
    if (result == true) {
      final parsed = parseBulkKeyValueRows(controller.text);
      final normalized = parsed.isEmpty
          ? <({String key, String value, bool isEnabled})>[
              (key: '', value: '', isEnabled: true),
            ]
          : parsed
                .map(
                  (r) => (key: r.key, value: r.value, isEnabled: r.isEnabled),
                )
                .toList();
      setState(() {
        _syncRowsWithInput(normalized);
        if (_rows.isEmpty) _rows.add(KeyValueEditorWebRow());
      });
      _notify();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.outlineVariant.withValues(alpha: 0.55);
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showHeaderChrome = constraints.maxHeight >= 92;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeaderChrome)
                _KeyValueEditorWebToolbar(
                  title: widget.title,
                  rowCount: _rows
                      .where(
                        (r) =>
                            r.keyController.text.trim().isNotEmpty ||
                            r.valueController.text.trim().isNotEmpty,
                      )
                      .length,
                  onAdd: _addRow,
                  onBulkEdit: _showBulkEditor,
                ),
              if (showHeaderChrome)
                _KeyValueEditorWebHeader(
                  keyLabel: widget.keyPlaceholder,
                  valueLabel: widget.valuePlaceholder,
                  descriptionLabel: widget.descriptionPlaceholder,
                ),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: dividerColor),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return _KeyValueEditorWebRowView(
                        key: ObjectKey(row),
                        row: row,
                        keyHint: widget.keyPlaceholder,
                        valueHint: widget.valuePlaceholder,
                        descriptionHint: widget.descriptionPlaceholder,
                        onAnyChanged: _notify,
                        onRemove: () => _removeRow(index),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KeyValueEditorWebToolbar extends StatelessWidget {
  const _KeyValueEditorWebToolbar({
    required this.title,
    required this.rowCount,
    required this.onAdd,
    required this.onBulkEdit,
  });

  final String title;
  final int rowCount;
  final VoidCallback onAdd;
  final VoidCallback onBulkEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          if (rowCount > 0)
            Text(
              '$rowCount',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: onBulkEdit,
            icon: const Icon(Icons.edit_note, size: 16),
            label: const Text('Bulk Edit'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: scheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueEditorWebHeader extends StatelessWidget {
  const _KeyValueEditorWebHeader({
    required this.keyLabel,
    required this.valueLabel,
    required this.descriptionLabel,
  });

  final String keyLabel;
  final String valueLabel;
  final String descriptionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface.withValues(alpha: 0.6);
    final divider = scheme.outlineVariant.withValues(alpha: 0.5);
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: Row(
        children: [
          Container(
            width: _kWebKvLeadingControlWidth,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: divider)),
            ),
          ),
          _HeaderLabel(
            label: keyLabel,
            color: textColor,
            flex: _kWebKvKeyFlex,
            divider: divider,
          ),
          _HeaderLabel(
            label: valueLabel,
            color: textColor,
            flex: _kWebKvValueFlex,
            divider: divider,
          ),
          _HeaderLabel(
            label: descriptionLabel,
            color: textColor,
            flex: _kWebKvDescriptionFlex,
            divider: divider,
          ),
          const SizedBox(width: _kWebKvTrailingActionWidth),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel({
    required this.label,
    required this.color,
    required this.flex,
    required this.divider,
  });

  final String label;
  final Color color;
  final int flex;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _kWebKvCellHorizontalPadding,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyValueEditorWebRowView extends StatelessWidget {
  const _KeyValueEditorWebRowView({
    super.key,
    required this.row,
    required this.keyHint,
    required this.valueHint,
    required this.descriptionHint,
    required this.onAnyChanged,
    required this.onRemove,
  });

  final KeyValueEditorWebRow row;
  final String keyHint;
  final String valueHint;
  final String descriptionHint;
  final VoidCallback onAnyChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: row.isEnabledNotifier,
      builder: (context, enabled, _) {
        return Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            color: scheme.surface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _kWebKvLeadingControlWidth,
                  child: Checkbox(
                    value: enabled,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) {
                      row.isEnabledNotifier.value = v ?? true;
                      onAnyChanged();
                    },
                  ),
                ),
                _RowField(
                  flex: _kWebKvKeyFlex,
                  controller: row.keyController,
                  hint: keyHint,
                  monospace: true,
                  onChanged: onAnyChanged,
                ),
                _RowField(
                  flex: _kWebKvValueFlex,
                  controller: row.valueController,
                  hint: valueHint,
                  monospace: true,
                  onChanged: onAnyChanged,
                ),
                _RowField(
                  flex: _kWebKvDescriptionFlex,
                  controller: row.descriptionController,
                  hint: descriptionHint,
                  monospace: false,
                  onChanged: onAnyChanged,
                ),
                SizedBox(
                  width: _kWebKvTrailingActionWidth,
                  child: IconButton(
                    iconSize: 15,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove row',
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RowField extends StatelessWidget {
  const _RowField({
    required this.flex,
    required this.controller,
    required this.hint,
    required this.monospace,
    required this.onChanged,
  });

  final int flex;
  final TextEditingController controller;
  final String hint;
  final bool monospace;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontFamily: monospace ? 'JetBrainsMono' : null,
      fontSize: 13,
      color: scheme.onSurface,
    );
    final hintStyle = style.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.4),
    );
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _kWebKvCellHorizontalPadding,
        ),
        alignment: Alignment.center,
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
            SingleActivator(LogicalKeyboardKey.tab, shift: true):
                PreviousFocusIntent(),
          },
          child: TextField(
            controller: controller,
            style: style,
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: hint,
              hintStyle: hintStyle,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            onChanged: (_) => onChanged(),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ),
      ),
    );
  }
}
