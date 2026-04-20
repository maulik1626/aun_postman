import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// HTTP proxy for mobile/desktop IO builds (`host:port` or `http://host:port`). Empty disables.
class ProxySettingsScreenMaterial extends ConsumerStatefulWidget {
  const ProxySettingsScreenMaterial({super.key});

  @override
  ConsumerState<ProxySettingsScreenMaterial> createState() =>
      _ProxySettingsScreenMaterialState();
}

class _ProxySettingsScreenMaterialState
    extends ConsumerState<ProxySettingsScreenMaterial> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(appSettingsProvider).httpProxy,
    );
    _controller.addListener(_persist);
  }

  void _persist() {
    ref.read(appSettingsProvider.notifier).setHttpProxy(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_persist);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secondary =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return Scaffold(
      appBar: AppBar(title: const Text('HTTP Proxy')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Forwarded to the native HTTP client on iOS, Android, macOS, '
              'Windows, and Linux. Web builds ignore this setting.',
              style: TextStyle(fontSize: 14, height: 1.35, color: secondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText:
                    'e.g. 127.0.0.1:8888 or http://proxy.example.com:8080',
                hintStyle: TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 14),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              style: const TextStyle(
                  fontFamily: 'JetBrainsMono', fontSize: 15),
              autocorrect: false,
              keyboardType: TextInputType.url,
            ),
          ),
        ],
      ),
    );
  }
}
