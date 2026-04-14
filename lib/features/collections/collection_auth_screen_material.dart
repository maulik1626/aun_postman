import 'package:aun_reqstudio/app/widgets/auth_config_editor_material.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:aun_reqstudio/domain/models/collection.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Material 3 version of [CollectionAuthScreen].
/// Default auth for requests in this collection when the request uses No Auth.
class CollectionAuthScreenMaterial extends ConsumerStatefulWidget {
  const CollectionAuthScreenMaterial({
    super.key,
    required this.collectionUid,
  });

  final String collectionUid;

  @override
  ConsumerState<CollectionAuthScreenMaterial> createState() =>
      _CollectionAuthScreenMaterialState();
}

class _CollectionAuthScreenMaterialState
    extends ConsumerState<CollectionAuthScreenMaterial> {
  /// Local edits; null means "same as saved collection".
  AuthConfig? _edited;

  Collection? _collectionOf(List<Collection> list) {
    return list.where((c) => c.uid == widget.collectionUid).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final collection = _collectionOf(collections);

    if (collection == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final display = _edited ?? collection.auth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection auth'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(collectionsProvider.notifier).update(
                    collection.copyWith(
                      auth: display,
                      updatedAt: DateTime.now(),
                    ),
                  );
              context.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applies to requests in "${collection.name}" that use No Auth in the Auth tab.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            AuthConfigEditorMaterial(
              auth: display,
              onChanged: (a) => setState(() => _edited = a),
            ),
          ],
        ),
      ),
    );
  }
}
