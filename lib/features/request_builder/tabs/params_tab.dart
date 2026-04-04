import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_postman/features/request_builder/widgets/key_value_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParamsTab extends ConsumerWidget {
  const ParamsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(
      requestBuilderProvider.select((s) => s.params),
    );
    final loadedUid = ref.watch(
      requestBuilderProvider.select((s) => s.loadedRequestUid),
    );

    return SingleChildScrollView(
      child: KeyValueEditor(
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
      ),
    );
  }
}
