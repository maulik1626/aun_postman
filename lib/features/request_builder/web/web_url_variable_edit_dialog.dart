import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:aun_reqstudio/features/request_builder/web/url_template_range.dart';
import 'package:flutter/material.dart';

typedef WebPersistActiveEnvVariable =
    Future<void> Function(String key, String value, bool isSecret);

/// Web-only small dialog to inspect a `{{variable}}` token, update its value in
/// the active environment, and update this URL occurrence (rename key or
/// substitute a literal).
Future<void> showWebUrlVariableEditDialog({
  required BuildContext context,
  required UrlVariableTemplateSpan span,
  required String currentUrl,
  required Environment? activeEnv,
  required void Function(String newUrl) onApply,
  WebPersistActiveEnvVariable? persistActiveEnvVariable,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _WebUrlVariableEditDialog(
      span: span,
      currentUrl: currentUrl,
      activeEnv: activeEnv,
      onApply: onApply,
      persistActiveEnvVariable: persistActiveEnvVariable,
    ),
  );
}

class _WebUrlVariableEditDialog extends StatefulWidget {
  const _WebUrlVariableEditDialog({
    required this.span,
    required this.currentUrl,
    required this.activeEnv,
    required this.onApply,
    this.persistActiveEnvVariable,
  });

  final UrlVariableTemplateSpan span;
  final String currentUrl;
  final Environment? activeEnv;
  final void Function(String newUrl) onApply;
  final WebPersistActiveEnvVariable? persistActiveEnvVariable;

  @override
  State<_WebUrlVariableEditDialog> createState() =>
      _WebUrlVariableEditDialogState();
}

class _WebUrlVariableEditDialogState extends State<_WebUrlVariableEditDialog> {
  late final TextEditingController _renameKeyController;
  late final TextEditingController _literalController;
  late final TextEditingController _valueController;
  late bool _storeAsSecret;
  late bool _revealValue;
  String? _error;

  EnvironmentVariable? _variableForSpan() {
    final env = widget.activeEnv;
    if (env == null) return null;
    EnvironmentVariable? enabled;
    EnvironmentVariable? any;
    for (final v in env.variables) {
      if (v.key != widget.span.inner) continue;
      any ??= v;
      if (v.isEnabled) {
        enabled = v;
        break;
      }
    }
    return enabled ?? any;
  }

  @override
  void initState() {
    super.initState();
    _renameKeyController = TextEditingController(text: widget.span.inner);
    _literalController = TextEditingController();
    final row = _variableForSpan();
    _valueController = TextEditingController(text: row?.value ?? '');
    _storeAsSecret = row?.isSecret ?? false;
    final hasSecretPrefill =
        row != null && row.isSecret && row.value.trim().isNotEmpty;
    _revealValue = !hasSecretPrefill;
  }

  @override
  void dispose() {
    _renameKeyController.dispose();
    _literalController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  bool get _hasActiveEnv => widget.activeEnv != null;

  bool get _enabledForSpanKey {
    if (!_hasActiveEnv) return false;
    return widget.activeEnv!.variables.any(
      (v) => v.key == widget.span.inner && v.isEnabled,
    );
  }

  bool get _hasDisabledVarForSpanKey {
    if (!_hasActiveEnv) return false;
    var hasKey = false;
    var hasEnabled = false;
    for (final v in widget.activeEnv!.variables) {
      if (v.key != widget.span.inner) continue;
      hasKey = true;
      if (v.isEnabled) hasEnabled = true;
    }
    return hasKey && !hasEnabled;
  }

  Future<void> _persistEnvIfNeeded(String key) async {
    final persist = widget.persistActiveEnvVariable;
    if (persist == null || !_hasActiveEnv) return;
    await persist(key, _valueController.text, _storeAsSecret);
  }

  /// Non-null message means invalid (also used when applying a literal so env
  /// writes use the same key as rename).
  String? _validateVariableKey(String key) {
    if (key.isEmpty) return 'Variable name cannot be empty.';
    if (key.contains('{') || key.contains('}')) {
      return 'Name cannot contain { or }.';
    }
    return null;
  }

  Future<void> _submit() async {
    final key = _renameKeyController.text.trim();
    final keyErr = _validateVariableKey(key);
    if (keyErr != null) {
      setState(() => _error = keyErr);
      return;
    }
    setState(() => _error = null);

    final literal = _literalController.text;
    if (literal.isNotEmpty) {
      await _persistEnvIfNeeded(key);
      final next = widget.currentUrl.replaceRange(
        widget.span.start,
        widget.span.end,
        literal,
      );
      widget.onApply(next);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    await _persistEnvIfNeeded(key);

    if (key == widget.span.inner) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final next = widget.currentUrl.replaceRange(
      widget.span.start,
      widget.span.end,
      '{{$key}}',
    );
    widget.onApply(next);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final token = widget.currentUrl.substring(
      widget.span.start,
      widget.span.end,
    );
    final obscureValue = _storeAsSecret && !_revealValue;

    return AlertDialog(
      title: const Text('URL variable'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Token',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                token,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (!_hasActiveEnv)
                Text(
                  'No active environment — set one to edit variable values.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.68),
                  ),
                )
              else ...[
                if (_hasDisabledVarForSpanKey)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'This key exists in the active environment but is '
                      'disabled — enable it under Environments to use it in URLs.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.error.withValues(alpha: 0.85),
                      ),
                    ),
                  )
                else if (!_enabledForSpanKey)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'This key is not in the active environment yet — '
                      'Apply adds or updates it.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.error.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                Text(
                  'Update variable value',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _valueController,
                  autocorrect: false,
                  obscureText: obscureValue,
                  minLines: 1,
                  maxLines: obscureValue ? 1 : 4,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: _storeAsSecret
                        ? IconButton(
                            tooltip: _revealValue ? 'Hide value' : 'Show value',
                            icon: Icon(
                              _revealValue
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() => _revealValue = !_revealValue);
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Secret value',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  subtitle: Text(
                    'Stored masked in the environment; use the eye to show or '
                    'hide while editing.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: scheme.onSurface.withValues(alpha: 0.52),
                    ),
                  ),
                  value: _storeAsSecret,
                  onChanged: (v) {
                    setState(() {
                      _storeAsSecret = v ?? false;
                      if (_storeAsSecret &&
                          _valueController.text.trim().isNotEmpty) {
                        _revealValue = false;
                      }
                      if (!_storeAsSecret) {
                        _revealValue = true;
                      }
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Rename variable (this URL only)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _renameKeyController,
                autocorrect: false,
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              Text(
                'Or replace token with literal (this URL only)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'If filled, replaces the entire {{…}} including braces. '
                'Leave empty to use rename only. When an environment is active, '
                'Apply still saves "Update variable value" for the rename key '
                'above.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: scheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _literalController,
                autocorrect: false,
                minLines: 1,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'e.g. https://api.example.com or plain text',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
