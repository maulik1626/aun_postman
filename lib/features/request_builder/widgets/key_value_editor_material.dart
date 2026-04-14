import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

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

class KeyValueEditorMaterial extends StatefulWidget {
  const KeyValueEditorMaterial({
    super.key,
    required this.rows,
    required this.onChanged,
    this.keyPlaceholder = 'Key',
    this.valuePlaceholder = 'Value',
    this.shrinkWrap = false,
  });

  final List<({String key, String value, bool isEnabled})> rows;
  final void Function(List<({String key, String value, bool isEnabled})>)
      onChanged;
  final String keyPlaceholder;
  final String valuePlaceholder;

  /// When true, builds a tight [Column] — use inside a parent [ScrollView].
  final bool shrinkWrap;

  @override
  State<KeyValueEditorMaterial> createState() => _KeyValueEditorMaterialState();
}

class _KeyValueEditorMaterialState extends State<KeyValueEditorMaterial> {
  late List<KeyValueRow> _rows;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (!widget.shrinkWrap) {
      _scrollController = ScrollController();
    }
    _rows = widget.rows
        .map((r) =>
            KeyValueRow(key: r.key, value: r.value, isEnabled: r.isEnabled))
        .toList();
    if (_rows.isEmpty) _rows.add(KeyValueRow());
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      _rows
          .map((r) => (
                key: r.keyController.text,
                value: r.valueController.text,
                isEnabled: r.isEnabled.value,
              ))
          .toList(),
    );
  }

  void _addRow() {
    setState(() => _rows.add(KeyValueRow()));
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
      if (_rows.isEmpty) _rows.add(KeyValueRow());
    });
    _notify();
  }

  Widget _buildColumnHeader(BuildContext context) {
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              widget.keyPlaceholder.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: secondary,
              ),
            ),
          ),
          Container(width: 0.5, height: 14, color: dividerColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                widget.valuePlaceholder.toUpperCase(),
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

  Widget _buildAddRowButton(BuildContext context) {
    return TextButton.icon(
      onPressed: _addRow,
      icon: const Icon(Icons.add_circle_outline, size: 16),
      label: const Text(
        'Add Row',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.seedColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final row = _rows[index];
    final surfaceColor =
        Theme.of(context).colorScheme.surfaceContainerLow;
    final dividerColor = Theme.of(context).dividerColor;
    final monoStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final hintStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 13,
      color: Theme.of(context).hintColor,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: row.isEnabled,
      builder: (context, enabled, _) => Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const SizedBox(width: 4),
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
                child: TextField(
                  controller: row.keyController,
                  style: monoStyle,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.keyPlaceholder,
                    hintStyle: hintStyle,
                  ),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  onChanged: (_) => _notify(),
                ),
              ),
              Container(width: 0.5, height: 28, color: dividerColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: TextField(
                    controller: row.valueController,
                    style: monoStyle,
                    decoration: InputDecoration.collapsed(
                      hintText: widget.valuePlaceholder,
                      hintStyle: hintStyle,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onChanged: (_) => _notify(),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removeRow(index),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.remove_circle,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
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
          _buildColumnHeader(context),
          const SizedBox(height: 10),
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildRow(context, i),
          ],
          _buildAddRowButton(context),
        ],
      );
    }

    final bottomClearance = MediaQuery.paddingOf(context).bottom + 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildColumnHeader(context),
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
                  child: _buildAddRowButton(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
