import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/domain/models/folder.dart';
import 'package:aun_postman/infrastructure/collection_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'collections_provider.g.dart';

@Riverpod(keepAlive: true)
class Collections extends _$Collections {
  static const _uuid = Uuid();

  @override
  List<Collection> build() {
    return ref.read(collectionRepositoryProvider).getAll();
  }

  Future<void> create(String name, {String? description}) async {
    final now = DateTime.now();
    final collection = Collection(
      uid: _uuid.v4(),
      name: name,
      description: description,
      sortOrder: state.length,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(collectionRepositoryProvider).save(collection);
    ref.invalidateSelf();
  }

  Future<void> update(Collection collection) async {
    await ref.read(collectionRepositoryProvider).save(
          collection.copyWith(updatedAt: DateTime.now()),
        );
    ref.invalidateSelf();
  }

  Future<void> delete(String uid) async {
    await ref.read(collectionRepositoryProvider).delete(uid);
    ref.invalidateSelf();
  }

  Future<void> reorder(List<String> orderedUids) async {
    await ref.read(collectionRepositoryProvider).updateSortOrders(orderedUids);
    ref.invalidateSelf();
  }

  Future<void> clearAll() async {
    for (final c in state) {
      await ref.read(collectionRepositoryProvider).delete(c.uid);
    }
    ref.invalidateSelf();
  }

  Future<void> importCollection(Collection collection) async {
    await ref.read(collectionRepositoryProvider).save(collection);
    ref.invalidateSelf();
  }

  Future<void> duplicate(String uid) async {
    final source = state.firstWhere((c) => c.uid == uid);
    final now = DateTime.now();
    final newColUid = _uuid.v4();
    final duplicated = source.copyWith(
      uid: newColUid,
      name: '${source.name} (copy)',
      sortOrder: state.length,
      createdAt: now,
      updatedAt: now,
      requests: source.requests
          .map((r) => r.copyWith(
                uid: _uuid.v4(),
                collectionUid: newColUid,
                folderUid: null,
                createdAt: now,
                updatedAt: now,
              ))
          .toList(),
      folders: source.folders
          .map((f) => _deepCopyFolder(f, newColUid, null, now))
          .toList(),
    );
    await ref.read(collectionRepositoryProvider).save(duplicated);
    ref.invalidateSelf();
  }
}

Folder _deepCopyFolder(
  Folder folder,
  String newCollectionUid,
  String? newParentUid,
  DateTime now,
) {
  final newFolderUid = const Uuid().v4();
  return folder.copyWith(
    uid: newFolderUid,
    collectionUid: newCollectionUid,
    parentFolderUid: newParentUid,
    createdAt: now,
    updatedAt: now,
    requests: folder.requests
        .map((r) => r.copyWith(
              uid: const Uuid().v4(),
              collectionUid: newCollectionUid,
              folderUid: newFolderUid,
              createdAt: now,
              updatedAt: now,
            ))
        .toList(),
    subFolders: folder.subFolders
        .map((sf) => _deepCopyFolder(sf, newCollectionUid, newFolderUid, now))
        .toList(),
  );
}
