import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

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

/// Form-data editor with per-field text vs file (same as Dio execution).
class FormDataFieldsEditor extends StatefulWidget {
  const FormDataFieldsEditor({
    super.key,
    required this.fields,
    required this.onChanged,
    this.shrinkWrap = false,
  });

  final List<FormDataField> fields;
  final void Function(List<FormDataField>) onChanged;
  final bool shrinkWrap;

  @override
  State<FormDataFieldsEditor> createState() => _FormDataFieldsEditorState();
}

class _FormDataFieldsEditorState extends State<FormDataFieldsEditor> {
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
    if (_rows.isEmpty) {
      _rows.add(_FormDataRow());
    }
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
      if (_rows.isEmpty) {
        _rows.add(_FormDataRow());
      }
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
    return Container(
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
          const SizedBox(width: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'FIELD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
    return ValueListenableBuilder<bool>(
      valueListenable: row.isEnabled,
      builder: (context, enabled, _) => Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: ValueListenableBuilder<bool>(
          valueListenable: row.isFile,
          builder: (context, asFile, _) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CupertinoCheckbox(
                  value: enabled,
                  activeColor: CupertinoTheme.of(context).primaryColor,
                  onChanged: (v) {
                    row.isEnabled.value = v ?? true;
                    _notify();
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: CupertinoTextField(
                    controller: row.keyController,
                    placeholder: 'Name',
                    decoration: null,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: asFile ? 1 : 0,
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: Text('Text', style: TextStyle(fontSize: 11)),
                      ),
                      1: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: Text('File', style: TextStyle(fontSize: 11)),
                      ),
                    },
                    onValueChanged: (v) {
                      if (v == null) return;
                      row.isFile.value = v == 1;
                      if (!row.isFile.value) row.filePath = null;
                      _notify();
                    },
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
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              onPressed: () => _pickFile(row),
                              child: Text(
                                'Choose',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoTheme.of(context)
                                      .primaryColor,
                                ),
                              ),
                            ),
                          ],
                        )
                      : CupertinoTextField(
                          controller: row.valueController,
                          placeholder: 'Value',
                          decoration: null,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          onChanged: (_) => _notify(),
                        ),
                ),
                GestureDetector(
                  onTap: () => _removeRow(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.minus_circle_fill,
                      size: 20,
                      color: CupertinoColors.destructiveRed,
                    ),
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
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onPressed: _addRow,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.add_circled,
            size: 16,
            color: CupertinoTheme.of(context).primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Add Field',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
        ],
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
