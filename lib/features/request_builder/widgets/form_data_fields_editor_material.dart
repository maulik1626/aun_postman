import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class _FormDataRow {
  _FormDataRow({
    String key = '',
    String value = '',
    bool isFile = false,
    this.filePath,
    bool isEnabled = true,
  })  : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value),
        isEnabled = ValueNotifier(isEnabled),
        isFile = ValueNotifier(isFile);

  final TextEditingController keyController;
  final TextEditingController valueController;
  final ValueNotifier<bool> isEnabled;
  final ValueNotifier<bool> isFile;
  String? filePath;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
    isEnabled.dispose();
    isFile.dispose();
  }
}

/// Material 3 form-data editor with per-field text vs file.
class FormDataFieldsEditorMaterial extends StatefulWidget {
  const FormDataFieldsEditorMaterial({
    super.key,
    required this.fields,
    required this.onChanged,
    this.shrinkWrap = false,
  });

  final List<FormDataField> fields;
  final void Function(List<FormDataField>) onChanged;
  final bool shrinkWrap;

  @override
  State<FormDataFieldsEditorMaterial> createState() =>
      _FormDataFieldsEditorMaterialState();
}

class _FormDataFieldsEditorMaterialState
    extends State<FormDataFieldsEditorMaterial> {
  late List<_FormDataRow> _rows;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (!widget.shrinkWrap) {
      _scrollController = ScrollController();
    }
    _rows = widget.fields
        .map(
          (f) => _FormDataRow(
            key: f.key,
            value: f.value,
            isFile: f.isFile,
            filePath: f.filePath,
            isEnabled: f.isEnabled,
          ),
        )
        .toList();
    if (_rows.isEmpty) _rows.add(_FormDataRow());
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      _rows
          .map(
            (r) => FormDataField(
              key: r.keyController.text,
              value: r.valueController.text,
              isFile: r.isFile.value,
              filePath: r.filePath,
              isEnabled: r.isEnabled.value,
            ),
          )
          .toList(),
    );
  }

  void _addRow() {
    setState(() => _rows.add(_FormDataRow()));
    if (widget.shrinkWrap) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = _scrollController;
      if (c == null || !c.hasClients) return;
      c.animateTo(
        c.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
      if (_rows.isEmpty) _rows.add(_FormDataRow());
    });
    _notify();
  }

  Future<void> _pickFile(_FormDataRow row) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      row.filePath = result.files.single.path;
      row.isFile.value = true;
    });
    _notify();
  }

  Widget _buildHeader(BuildContext context) {
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'FIELD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: secondary,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'TYPE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: secondary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'VALUE / FILE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 26),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final row = _rows[index];
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerLow;
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);
    final monoStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final primary = Theme.of(context).colorScheme.primary;

    return ValueListenableBuilder<bool>(
      valueListenable: row.isEnabled,
      builder: (context, enabled, _) => Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: ValueListenableBuilder<bool>(
          valueListenable: row.isFile,
          builder: (context, asFile, _) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: enabled,
                  activeColor: AppColors.seedColor,
                  onChanged: (v) {
                    row.isEnabled.value = v ?? true;
                    _notify();
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.keyController,
                    style: monoStyle,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Name',
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onChanged: (_) => _notify(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          child: Text('Text', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          child: Text('File', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                    selected: {asFile ? 1 : 0},
                    onSelectionChanged: (s) {
                      if (s.isEmpty) return;
                      row.isFile.value = s.first == 1;
                      if (!row.isFile.value) row.filePath = null;
                      _notify();
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor:
                          AppColors.seedColor.withValues(alpha: 0.15),
                      selectedForegroundColor: AppColors.seedColor,
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    showSelectedIcon: false,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: asFile
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.filePath == null || row.filePath!.isEmpty
                                    ? 'No file'
                                    : row.filePath!.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 12,
                                  color: secondary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _pickFile(row),
                              style: TextButton.styleFrom(
                                foregroundColor: primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Choose',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        )
                      : TextField(
                          controller: row.valueController,
                          style: monoStyle,
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Value',
                          ),
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          onChanged: (_) => _notify(),
                        ),
                ),
                GestureDetector(
                  onTap: () => _removeRow(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.remove_circle, size: 20, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return TextButton.icon(
      onPressed: _addRow,
      icon: const Icon(Icons.add_circle_outline, size: 16),
      label: const Text(
        'Add Field',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.seedColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shrinkWrap) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildRow(context, i),
          ],
          _buildAddButton(context),
        ],
      );
    }

    final bottomClearance = MediaQuery.paddingOf(context).bottom + 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            primary: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(top: index > 0 ? 10 : 0),
                    child: _buildRow(context, index),
                  ),
                  childCount: _rows.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomClearance),
                  child: _buildAddButton(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
