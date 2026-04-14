import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor_material.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global HTTP headers merged into every request before the request's own headers.
class DefaultHeadersSettingsScreenMaterial extends ConsumerWidget {
  const DefaultHeadersSettingsScreenMaterial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final secondary =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final rows = settings.defaultHeaders
        .map(
          (h) => (
            key: h.key,
            value: h.value,
            isEnabled: h.isEnabled,
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Default Headers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Added to every request first. The request\'s Headers tab '
              'overrides the same name.',
              style: TextStyle(fontSize: 14, height: 1.35, color: secondary),
            ),
          ),
          Expanded(
            child: KeyValueEditorMaterial(
              rows: rows.isEmpty
                  ? [(key: '', value: '', isEnabled: true)]
                  : rows,
              keyPlaceholder: 'Header name',
              valuePlaceholder: 'Value',
              onChanged: (updated) {
                final headers = updated
                    .where((r) => r.key.trim().isNotEmpty)
                    .map(
                      (r) => RequestHeader(
                        key: r.key.trim(),
                        value: r.value,
                        isEnabled: r.isEnabled,
                      ),
                    )
                    .toList();
                ref
                    .read(appSettingsProvider.notifier)
                    .setDefaultHeaders(headers);
              },
            ),
          ),
        ],
      ),
    );
  }
}
