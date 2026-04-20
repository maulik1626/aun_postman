import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeadersTabMaterial extends ConsumerWidget {
  const HeadersTabMaterial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headers = ref.watch(
      requestBuilderProvider.select((s) => s.headers),
    );
    final loadedUid = ref.watch(
      requestBuilderProvider.select((s) => s.loadedRequestUid),
    );

    return KeyValueEditorMaterial(
      key: ValueKey(loadedUid),
      rows: headers
          .map((h) => (key: h.key, value: h.value, isEnabled: h.isEnabled))
          .toList(),
      keyPlaceholder: 'Header',
      valuePlaceholder: 'Value',
      onChanged: (rows) {
        ref.read(requestBuilderProvider.notifier).setHeaders(
              rows
                  .map(
                    (r) => RequestHeader(
                      key: r.key,
                      value: r.value,
                      isEnabled: r.isEnabled,
                    ),
                  )
                  .toList(),
            );
      },
    );
  }
}
