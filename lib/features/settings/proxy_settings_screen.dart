import 'package:aun_postman/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// HTTP proxy for mobile/desktop IO builds (`host:port` or `http://host:port`). Empty disables.
class ProxySettingsScreen extends ConsumerStatefulWidget {
  const ProxySettingsScreen({super.key});

  @override
  ConsumerState<ProxySettingsScreen> createState() =>
      _ProxySettingsScreenState();
}

class _ProxySettingsScreenState extends ConsumerState<ProxySettingsScreen> {
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
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('HTTP Proxy'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Forwarded to the native HTTP client on iOS, Android, macOS, '
                'Windows, and Linux. Web builds ignore this setting.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoTextField(
                controller: _controller,
                placeholder:
                    'e.g. 127.0.0.1:8888 or http://proxy.example.com:8080',
                placeholderStyle: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'JetBrainsMono',
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemBackground.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                autocorrect: false,
                keyboardType: TextInputType.url,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
