import 'package:aun_postman/core/utils/oauth2_token_client.dart';
import 'package:aun_postman/domain/enums/auth_type.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:flutter/cupertino.dart';

AuthType authTypeFromConfig(AuthConfig auth) => switch (auth) {
      NoAuth() => AuthType.none,
      BearerAuth() => AuthType.bearer,
      BasicAuth() => AuthType.basic,
      ApiKeyAuth() => AuthType.apiKey,
      OAuth2Auth() => AuthType.oauth2,
      DigestAuth() => AuthType.digest,
      AwsSigV4Auth() => AuthType.awsSigV4,
    };

AuthConfig defaultAuthForPicker(AuthType type) => switch (type) {
      AuthType.none => const NoAuth(),
      AuthType.bearer => const BearerAuth(),
      AuthType.basic => const BasicAuth(),
      AuthType.apiKey => const ApiKeyAuth(),
      AuthType.oauth2 => const OAuth2Auth(),
      AuthType.digest => const DigestAuth(),
      AuthType.awsSigV4 => const AwsSigV4Auth(),
    };

/// Shared auth type picker + fields (request builder + collection default).
class AuthConfigEditor extends StatelessWidget {
  const AuthConfigEditor({
    super.key,
    required this.auth,
    required this.onChanged,
  });

  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = authTypeFromConfig(auth);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auth type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openTypeSheet(context, current),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground.resolveFrom(
                context,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    current.label,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 18,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _AuthFieldsBody(auth: auth, onChanged: onChanged),
      ],
    );
  }

  void _openTypeSheet(BuildContext context, AuthType selected) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Authentication'),
        actions: [
          for (final t in AuthType.values)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                if (t == selected) return;
                onChanged(defaultAuthForPicker(t));
              },
              child: Text(t.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _AuthFieldsBody extends StatelessWidget {
  const _AuthFieldsBody({required this.auth, required this.onChanged});

  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (auth) {
      NoAuth() => Text(
          'No authentication',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      BearerAuth(:final token) => _BearerFields(
          token: token,
          onChanged: (t) => onChanged(BearerAuth(token: t)),
        ),
      BasicAuth(:final username, :final password) => _BasicFields(
          username: username,
          password: password,
          onChanged: (u, p) => onChanged(BasicAuth(username: u, password: p)),
        ),
      ApiKeyAuth(:final key, :final value, :final addTo) => _ApiKeyFields(
          keyName: key,
          keyValue: value,
          addTo: addTo,
          onChanged: (k, v, a) =>
              onChanged(ApiKeyAuth(key: k, value: v, addTo: a)),
        ),
      final OAuth2Auth oa => _OAuth2Block(auth: oa, onChanged: onChanged),
      DigestAuth(:final username, :final password) => _BasicFields(
          username: username,
          password: password,
          onChanged: (u, p) => onChanged(DigestAuth(username: u, password: p)),
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
        _AwsFields(
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

class _BearerFields extends StatelessWidget {
  const _BearerFields({required this.token, required this.onChanged});
  final String token;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return _AuthLabeledField(
      label: 'Token',
      initialValue: token,
      hint: 'Bearer token',
      onChanged: onChanged,
    );
  }
}

class _BasicFields extends StatelessWidget {
  const _BasicFields({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthLabeledField(
          label: usernameLabel,
          initialValue: username,
          hint: 'username',
          onChanged: (v) => onChanged(v, password),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
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
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _ApiKeyFields extends StatelessWidget {
  const _ApiKeyFields({
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
        _AuthLabeledField(
          label: 'Key',
          initialValue: keyName,
          hint: 'X-API-Key',
          onChanged: (v) => onChanged(v, keyValue, addTo),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
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

class _OAuth2Block extends StatefulWidget {
  const _OAuth2Block({required this.auth, required this.onChanged});

  final OAuth2Auth auth;
  final ValueChanged<AuthConfig> onChanged;

  @override
  State<_OAuth2Block> createState() => _OAuth2BlockState();
}

class _OAuth2BlockState extends State<_OAuth2Block> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.auth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grant type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoSlidingSegmentedControl<OAuth2GrantType>(
          groupValue: a.grantType,
          onValueChanged: (g) {
            if (g == null) return;
            widget.onChanged(a.copyWith(grantType: g));
          },
          children: const {
            OAuth2GrantType.clientCredentials: Text('Client cred.'),
            OAuth2GrantType.password: Text('Password'),
          },
        ),
        const SizedBox(height: 16),
        _AuthLabeledField(
          label: 'Access token (after Get token or Send)',
          initialValue: a.accessToken,
          hint: 'auto-filled',
          onChanged: (v) => widget.onChanged(a.copyWith(accessToken: v)),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
          label: 'Token URL',
          initialValue: a.tokenUrl,
          hint: 'https://auth.example.com/oauth/token',
          onChanged: (v) => widget.onChanged(a.copyWith(tokenUrl: v)),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
          label: 'Client ID',
          initialValue: a.clientId,
          hint: 'client_id',
          onChanged: (v) => widget.onChanged(a.copyWith(clientId: v)),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
          label: 'Client secret',
          initialValue: a.clientSecret,
          hint: 'client_secret',
          obscureText: true,
          onChanged: (v) => widget.onChanged(a.copyWith(clientSecret: v)),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
          label: 'Scope (optional)',
          initialValue: a.scope,
          hint: 'read write',
          onChanged: (v) => widget.onChanged(a.copyWith(scope: v)),
        ),
        if (a.grantType == OAuth2GrantType.password) ...[
          const SizedBox(height: 12),
          _AuthLabeledField(
            label: 'Username',
            initialValue: a.username,
            hint: 'user',
            onChanged: (v) => widget.onChanged(a.copyWith(username: v)),
          ),
          const SizedBox(height: 12),
          _AuthLabeledField(
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
          child: CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () async {
              if (_busy) return;
              setState(() => _busy = true);
              try {
                final next = await OAuth2TokenClient.fetchAndMerge(a);
                widget.onChanged(next);
                if (!context.mounted) return;
                await showCupertinoDialog<void>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('Token received'),
                    content: const Text(
                      'Access token was saved on this request.',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                await showCupertinoDialog<void>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('Token request failed'),
                    content: Text('$e'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: _busy
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('Get New Access Token'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Send also fetches a token automatically when the access token is empty or expired.',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _AwsFields extends StatelessWidget {
  const _AwsFields({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthLabeledField(
          label: 'Access key ID',
          initialValue: accessKeyId,
          hint: 'AKIA...',
          onChanged: (v) => onChanged(
            v,
            secretAccessKey,
            sessionToken,
            region,
            service,
          ),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
          label: 'Secret access key',
          initialValue: secretAccessKey,
          hint: 'Secret',
          obscureText: true,
          onChanged: (v) => onChanged(
            accessKeyId,
            v,
            sessionToken,
            region,
            service,
          ),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
          label: 'Session token (optional)',
          initialValue: sessionToken,
          hint: 'For temporary credentials',
          onChanged: (v) => onChanged(
            accessKeyId,
            secretAccessKey,
            v,
            region,
            service,
          ),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
          label: 'Region',
          initialValue: region,
          hint: 'us-east-1',
          onChanged: (v) => onChanged(
            accessKeyId,
            secretAccessKey,
            sessionToken,
            v,
            service,
          ),
        ),
        const SizedBox(height: 12),
        _AuthLabeledField(
          label: 'Service name',
          initialValue: service,
          hint: 'execute-api',
          onChanged: (v) => onChanged(
            accessKeyId,
            secretAccessKey,
            sessionToken,
            region,
            v,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Uses SigV4 on the request. Works best with JSON/text bodies.',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _AuthLabeledField extends StatefulWidget {
  const _AuthLabeledField({
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
  State<_AuthLabeledField> createState() => _AuthLabeledFieldState();
}

class _AuthLabeledFieldState extends State<_AuthLabeledField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _AuthLabeledField oldWidget) {
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
