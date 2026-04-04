import 'package:flutter/cupertino.dart';

class KeyValueRow {
  KeyValueRow({
    String key = '',
    String value = '',
    bool isEnabled = true,
  })  : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value),
        isEnabled = ValueNotifier(isEnabled);

  final TextEditingController keyController;
  final TextEditingController valueController;
  final ValueNotifier<bool> isEnabled;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
    isEnabled.dispose();
  }
}

class KeyValueEditor extends StatefulWidget {
  const KeyValueEditor({
    super.key,
    required this.rows,
    required this.onChanged,
    this.keyPlaceholder = 'Key',
    this.valuePlaceholder = 'Value',
  });

  final List<({String key, String value, bool isEnabled})> rows;
  final void Function(List<({String key, String value, bool isEnabled})>)
      onChanged;
  final String keyPlaceholder;
  final String valuePlaceholder;

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  late List<KeyValueRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.rows
        .map((r) =>
            KeyValueRow(key: r.key, value: r.value, isEnabled: r.isEnabled))
        .toList();
    if (_rows.isEmpty) _rows.add(KeyValueRow());
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      _rows.map((r) => (
            key: r.keyController.text,
            value: r.valueController.text,
            isEnabled: r.isEnabled.value,
          )).toList(),
    );
  }

  void _addRow() {
    setState(() => _rows.add(KeyValueRow()));
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
      if (_rows.isEmpty) _rows.add(KeyValueRow());
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              const SizedBox(width: 28), // checkbox width
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.keyPlaceholder.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              Container(
                width: 0.5,
                height: 14,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    widget.valuePlaceholder.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 26), // delete button width
            ],
          ),
        ),
        // Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rows.length,
          separatorBuilder: (_, __) => Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 16),
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          itemBuilder: (context, index) {
            final row = _rows[index];
            return ValueListenableBuilder<bool>(
              valueListenable: row.isEnabled,
              builder: (context, enabled, _) => Opacity(
                opacity: enabled ? 1.0 : 0.45,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemBackground
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
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
                        child: CupertinoTextField(
                          controller: row.keyController,
                          placeholder: widget.keyPlaceholder,
                          decoration: null,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8),
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          placeholderStyle: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            color: CupertinoColors.placeholderText
                                .resolveFrom(context),
                          ),
                          onChanged: (_) => _notify(),
                        ),
                      ),
                      Container(
                        width: 0.5,
                        height: 28,
                        color:
                            CupertinoColors.separator.resolveFrom(context),
                      ),
                      Expanded(
                        child: CupertinoTextField(
                          controller: row.valueController,
                          placeholder: widget.valuePlaceholder,
                          decoration: null,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          placeholderStyle: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            color: CupertinoColors.placeholderText
                                .resolveFrom(context),
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
            );
          },
        ),
        // Add Row button
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                'Add Row',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
