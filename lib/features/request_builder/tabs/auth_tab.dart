import 'package:aun_postman/domain/enums/auth_type.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthTab extends ConsumerWidget {
  const AuthTab({super.key});

  AuthType _authType(AuthConfig auth) => switch (auth) {
        NoAuth() => AuthType.none,
        BearerAuth() => AuthType.bearer,
        BasicAuth() => AuthType.basic,
        ApiKeyAuth() => AuthType.apiKey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(requestBuilderProvider.select((s) => s.auth));
    final currentType = _authType(auth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auth Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          CupertinoSlidingSegmentedControl<AuthType>(
            groupValue: currentType,
            onValueChanged: (type) {
              if (type == null) return;
              final newAuth = switch (type) {
                AuthType.none => const NoAuth(),
                AuthType.bearer => const BearerAuth(),
                AuthType.basic => const BasicAuth(),
                AuthType.apiKey => const ApiKeyAuth(),
              };
              ref.read(requestBuilderProvider.notifier).setAuth(newAuth);
            },
            children: {
              for (final t in AuthType.values) t: Text(t.label),
            },
          ),
          const SizedBox(height: 24),
          _buildAuthForm(context, ref, auth),
        ],
      ),
    );
  }

  Widget _buildAuthForm(BuildContext context, WidgetRef ref, AuthConfig auth) {
    return switch (auth) {
      NoAuth() => Center(
          child: Text(
            'No authentication',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      BearerAuth(:final token) => _BearerForm(
          token: token,
          onChanged: (t) => ref
              .read(requestBuilderProvider.notifier)
              .setAuth(BearerAuth(token: t)),
        ),
      BasicAuth(:final username, :final password) => _BasicForm(
          username: username,
          password: password,
          onChanged: (u, p) => ref
              .read(requestBuilderProvider.notifier)
              .setAuth(BasicAuth(username: u, password: p)),
        ),
      ApiKeyAuth(:final key, :final value, :final addTo) => _ApiKeyForm(
          keyName: key,
          keyValue: value,
          addTo: addTo,
          onChanged: (k, v, a) => ref
              .read(requestBuilderProvider.notifier)
              .setAuth(ApiKeyAuth(key: k, value: v, addTo: a)),
        ),
    };
  }
}

class _BearerForm extends StatelessWidget {
  const _BearerForm({required this.token, required this.onChanged});
  final String token;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: 'Token',
      initialValue: token,
      hint: 'Bearer token',
      onChanged: onChanged,
    );
  }
}

class _BasicForm extends StatelessWidget {
  const _BasicForm({
    required this.username,
    required this.password,
    required this.onChanged,
  });
  final String username;
  final String password;
  final void Function(String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LabeledField(
          label: 'Username',
          initialValue: username,
          hint: 'username',
          onChanged: (v) => onChanged(v, password),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Password',
          initialValue: password,
          hint: 'password',
          obscureText: true,
          onChanged: (v) => onChanged(username, v),
        ),
      ],
    );
  }
}

class _ApiKeyForm extends StatelessWidget {
  const _ApiKeyForm({
    required this.keyName,
    required this.keyValue,
    required this.addTo,
    required this.onChanged,
  });
  final String keyName;
  final String keyValue;
  final ApiKeyAddTo addTo;
  final void Function(String, String, ApiKeyAddTo) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledField(
          label: 'Key',
          initialValue: keyName,
          hint: 'X-API-Key',
          onChanged: (v) => onChanged(v, keyValue, addTo),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Value',
          initialValue: keyValue,
          hint: 'your-api-key',
          onChanged: (v) => onChanged(keyName, v, addTo),
        ),
        const SizedBox(height: 16),
        Text(
          'Add to',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoSlidingSegmentedControl<ApiKeyAddTo>(
          groupValue: addTo,
          onValueChanged: (s) {
            if (s != null) onChanged(keyName, keyValue, s);
          },
          children: {
            for (final t in ApiKeyAddTo.values) t: Text(t.label),
          },
        ),
      ],
    );
  }
}

class _LabeledField extends StatefulWidget {
  const _LabeledField({
    required this.label,
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    this.obscureText = false,
  });
  final String label;
  final String initialValue;
  final String hint;
  final void Function(String) onChanged;
  final bool obscureText;

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: _controller,
          obscureText: widget.obscureText,
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
          placeholder: widget.hint,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
