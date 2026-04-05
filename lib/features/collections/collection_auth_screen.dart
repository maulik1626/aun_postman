import 'package:aun_postman/app/widgets/auth_config_editor.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/features/collections/providers/collections_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Default auth for requests in this collection when the request uses **No Auth**.
class CollectionAuthScreen extends ConsumerStatefulWidget {
  const CollectionAuthScreen({super.key, required this.collectionUid});

  final String collectionUid;

  @override
  ConsumerState<CollectionAuthScreen> createState() =>
      _CollectionAuthScreenState();
}

class _CollectionAuthScreenState extends ConsumerState<CollectionAuthScreen> {
  /// Local edits; null means “same as saved collection”.
  AuthConfig? _edited;

  Collection? _collectionOf(List<Collection> list) {
    return list.where((c) => c.uid == widget.collectionUid).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final collection = _collectionOf(collections);
    if (collection == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final display = _edited ?? collection.auth;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Collection auth'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
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
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Applies to requests in “${collection.name}” that use No Auth in the Auth tab.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 20),
              AuthConfigEditor(
                auth: display,
                onChanged: (a) => setState(() => _edited = a),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
