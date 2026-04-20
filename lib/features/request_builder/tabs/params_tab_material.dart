import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParamsTabMaterial extends ConsumerWidget {
  const ParamsTabMaterial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(
      requestBuilderProvider.select((s) => s.params),
    );
    final loadedUid = ref.watch(
      requestBuilderProvider.select((s) => s.loadedRequestUid),
    );

    return KeyValueEditorMaterial(
      key: ValueKey(loadedUid),
      rows: params
          .map((p) => (key: p.key, value: p.value, isEnabled: p.isEnabled))
          .toList(),
      keyPlaceholder: 'Parameter',
      valuePlaceholder: 'Value',
      onChanged: (rows) {
        ref.read(requestBuilderProvider.notifier).setParams(
              rows
                  .map(
                    (r) => RequestParam(
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
