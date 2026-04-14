import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/core/utils/oauth2_token_client.dart';
import 'package:aun_reqstudio/domain/enums/auth_type.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:flutter/material.dart';

// Import and re-export the platform-agnostic helpers from the original file.
import 'package:aun_reqstudio/app/widgets/auth_config_editor.dart'
    show authTypeFromConfig, defaultAuthForPicker;
export 'package:aun_reqstudio/app/widgets/auth_config_editor.dart'
    show authTypeFromConfig, defaultAuthForPicker;

/// Material 3 version of [AuthConfigEditor].
/// Identical API — drop-in replacement for Material screens.
class AuthConfigEditorMaterial extends StatelessWidget {
  const AuthConfigEditorMaterial({
    super.key,
    required this.auth,
    required this.onChanged,
  });

  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = authTypeFromConfig(auth);
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auth type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: secondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AuthType>(
          initialValue: current,
          decoration: const InputDecoration(),
          items: [
            for (final t in AuthType.values)
              DropdownMenuItem(value: t, child: Text(t.label)),
          ],
          onChanged: (t) {
            if (t != null && t != current) {
              onChanged(defaultAuthForPicker(t));
            }
          },
        ),
        const SizedBox(height: 24),
        _AuthFieldsBodyMaterial(auth: auth, onChanged: onChanged),
      ],
    );
  }
}

// ── Fields body ───────────────────────────────────────────────────────────────

class _AuthFieldsBodyMaterial extends StatelessWidget {
  const _AuthFieldsBodyMaterial({required this.auth, required this.onChanged});

  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return switch (auth) {
      NoAuth() => Text(
          'No authentication',
          style: TextStyle(color: secondary),
        ),
      BearerAuth(:final token) => _BearerFieldsMaterial(
          token: token,
          onChanged: (t) => onChanged(BearerAuth(token: t)),
        ),
      BasicAuth(:final username, :final password) => _BasicFieldsMaterial(
          username: username,
          password: password,
          onChanged: (u, p) => onChanged(BasicAuth(username: u, password: p)),
        ),
      ApiKeyAuth(:final key, :final value, :final addTo) =>
        _ApiKeyFieldsMaterial(
          keyName: key,
          keyValue: value,
          addTo: addTo,
          onChanged: (k, v, a) =>
              onChanged(ApiKeyAuth(key: k, value: v, addTo: a)),
        ),
      final OAuth2Auth oa =>
        _OAuth2BlockMaterial(auth: oa, onChanged: onChanged),
      DigestAuth(:final username, :final password) => _BasicFieldsMaterial(
          username: username,
          password: password,
          onChanged: (u, p) =>
              onChanged(DigestAuth(username: u, password: p)),
          usernameLabel: 'Username',
          passwordLabel: 'Password',
          footnote:
              'The first request may return 401; the app retries with a Digest header.',
        ),
      AwsSigV4Auth(
        :final accessKeyId,
        :final secretAccessKey,
        :final sessionToken,
        :final region,
        :final service,
      ) =>
        _AwsFieldsMaterial(
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          sessionToken: sessionToken,
          region: region,
          service: service,
          onChanged: (a, s, st, r, sv) => onChanged(
            AwsSigV4Auth(
              accessKeyId: a,
              secretAccessKey: s,
              sessionToken: st,
              region: r,
              service: sv,
            ),
          ),
        ),
    };
  }
}

// ── Bearer ────────────────────────────────────────────────────────────────────

class _BearerFieldsMaterial extends StatelessWidget {
  const _BearerFieldsMaterial(
      {required this.token, required this.onChanged});
  final String token;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return _AuthLabeledFieldMaterial(
      label: 'Token',
      initialValue: token,
      hint: 'Bearer token',
      onChanged: onChanged,
    );
  }
}

// ── Basic / Digest ────────────────────────────────────────────────────────────

class _BasicFieldsMaterial extends StatelessWidget {
  const _BasicFieldsMaterial({
    required this.username,
    required this.password,
    required this.onChanged,
    this.usernameLabel = 'Username',
    this.passwordLabel = 'Password',
    this.footnote,
  });
  final String username;
  final String password;
  final void Function(String, String) onChanged;
  final String usernameLabel;
  final String passwordLabel;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthLabeledFieldMaterial(
          label: usernameLabel,
          initialValue: username,
          hint: 'username',
          onChanged: (v) => onChanged(v, password),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: passwordLabel,
          initialValue: password,
          hint: 'password',
          obscureText: true,
          onChanged: (v) => onChanged(username, v),
        ),
        if (footnote != null) ...[
          const SizedBox(height: 12),
          Text(
            footnote!,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: secondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ── API Key ───────────────────────────────────────────────────────────────────

class _ApiKeyFieldsMaterial extends StatelessWidget {
  const _ApiKeyFieldsMaterial({
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
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthLabeledFieldMaterial(
          label: 'Key',
          initialValue: keyName,
          hint: 'X-API-Key',
          onChanged: (v) => onChanged(v, keyValue, addTo),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
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
            color: secondary,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ApiKeyAddTo>(
          segments: [
            for (final t in ApiKeyAddTo.values)
              ButtonSegment(value: t, label: Text(t.label)),
          ],
          selected: {addTo},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onChanged(keyName, keyValue, s.first);
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor:
                AppColors.seedColor.withValues(alpha: 0.15),
            selectedForegroundColor: AppColors.seedColor,
          ),
        ),
      ],
    );
  }
}

// ── OAuth 2.0 ─────────────────────────────────────────────────────────────────

class _OAuth2BlockMaterial extends StatefulWidget {
  const _OAuth2BlockMaterial({required this.auth, required this.onChanged});

  final OAuth2Auth auth;
  final ValueChanged<AuthConfig> onChanged;

  @override
  State<_OAuth2BlockMaterial> createState() => _OAuth2BlockMaterialState();
}

class _OAuth2BlockMaterialState extends State<_OAuth2BlockMaterial> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.auth;
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grant type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: secondary,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<OAuth2GrantType>(
          segments: const [
            ButtonSegment(
              value: OAuth2GrantType.clientCredentials,
              label: Text('Client cred.'),
            ),
            ButtonSegment(
              value: OAuth2GrantType.password,
              label: Text('Password'),
            ),
          ],
          selected: {a.grantType},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) {
              widget.onChanged(a.copyWith(grantType: s.first));
            }
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor:
                AppColors.seedColor.withValues(alpha: 0.15),
            selectedForegroundColor: AppColors.seedColor,
          ),
        ),
        const SizedBox(height: 16),
        _AuthLabeledFieldMaterial(
          label: 'Access token (after Get token or Send)',
          initialValue: a.accessToken,
          hint: 'auto-filled',
          onChanged: (v) => widget.onChanged(a.copyWith(accessToken: v)),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: 'Token URL',
          initialValue: a.tokenUrl,
          hint: 'https://auth.example.com/oauth/token',
          onChanged: (v) => widget.onChanged(a.copyWith(tokenUrl: v)),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: 'Client ID',
          initialValue: a.clientId,
          hint: 'client_id',
          onChanged: (v) => widget.onChanged(a.copyWith(clientId: v)),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: 'Client secret',
          initialValue: a.clientSecret,
          hint: 'client_secret',
          obscureText: true,
          onChanged: (v) => widget.onChanged(a.copyWith(clientSecret: v)),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: 'Scope (optional)',
          initialValue: a.scope,
          hint: 'read write',
          onChanged: (v) => widget.onChanged(a.copyWith(scope: v)),
        ),
        if (a.grantType == OAuth2GrantType.password) ...[
          const SizedBox(height: 12),
          _AuthLabeledFieldMaterial(
            label: 'Username',
            initialValue: a.username,
            hint: 'user',
            onChanged: (v) => widget.onChanged(a.copyWith(username: v)),
          ),
          const SizedBox(height: 12),
          _AuthLabeledFieldMaterial(
            label: 'Password',
            initialValue: a.password,
            hint: 'password',
            obscureText: true,
            onChanged: (v) => widget.onChanged(a.copyWith(password: v)),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.seedColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _busy ? null : () => _fetchToken(a),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Get New Access Token'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Send also fetches a token automatically when the access token is empty or expired.',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: secondary,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchToken(OAuth2Auth a) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = await OAuth2TokenClient.fetchAndMerge(a);
      widget.onChanged(next);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Token received'),
          content: const Text('Access token was saved on this request.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Token request failed'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ── AWS SigV4 ─────────────────────────────────────────────────────────────────

class _AwsFieldsMaterial extends StatelessWidget {
  const _AwsFieldsMaterial({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
    required this.region,
    required this.service,
    required this.onChanged,
  });
  final String accessKeyId;
  final String secretAccessKey;
  final String sessionToken;
  final String region;
  final String service;
  final void Function(
    String accessKeyId,
    String secret,
    String session,
    String region,
    String service,
  ) onChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthLabeledFieldMaterial(
          label: 'Access key ID',
          initialValue: accessKeyId,
          hint: 'AKIA...',
          onChanged: (v) =>
              onChanged(v, secretAccessKey, sessionToken, region, service),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: 'Secret access key',
          initialValue: secretAccessKey,
          hint: 'Secret',
          obscureText: true,
          onChanged: (v) =>
              onChanged(accessKeyId, v, sessionToken, region, service),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: 'Session token (optional)',
          initialValue: sessionToken,
          hint: 'For temporary credentials',
          onChanged: (v) =>
              onChanged(accessKeyId, secretAccessKey, v, region, service),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: 'Region',
          initialValue: region,
          hint: 'us-east-1',
          onChanged: (v) =>
              onChanged(accessKeyId, secretAccessKey, sessionToken, v, service),
        ),
        const SizedBox(height: 12),
        _AuthLabeledFieldMaterial(
          label: 'Service name',
          initialValue: service,
          hint: 'execute-api',
          onChanged: (v) =>
              onChanged(accessKeyId, secretAccessKey, sessionToken, region, v),
        ),
        const SizedBox(height: 12),
        Text(
          'Uses SigV4 on the request. Works best with JSON/text bodies.',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: secondary,
          ),
        ),
      ],
    );
  }
}

// ── Shared labeled text field ─────────────────────────────────────────────────

class _AuthLabeledFieldMaterial extends StatefulWidget {
  const _AuthLabeledFieldMaterial({
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
  State<_AuthLabeledFieldMaterial> createState() =>
      _AuthLabeledFieldMaterialState();
}

class _AuthLabeledFieldMaterialState
    extends State<_AuthLabeledFieldMaterial> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _AuthLabeledFieldMaterial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text == oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          obscureText: widget.obscureText,
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
          decoration: InputDecoration(hintText: widget.hint),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
