import 'package:aun_reqstudio/domain/models/collection.dart';
import 'package:aun_reqstudio/domain/models/folder.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/infrastructure/collection_repository.dart';
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

  /// Serialized so rapid drags apply in order and never race the DAO.
  Future<void> _reorderQueue = Future.value();

  Future<void> reorder(List<String> orderedUids) {
    _reorderQueue = _reorderQueue.then((_) async {
      await ref.read(collectionRepositoryProvider).updateSortOrders(orderedUids);
      ref.invalidateSelf();
    });
    return _reorderQueue;
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
      auth: source.auth,
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

  /// Merges imported top-level folders and root requests into [collectionUid],
  /// either at collection root or inside [parentFolderUid].
  Future<void> mergeCollectionFragment({
    required String collectionUid,
    String? parentFolderUid,
    required List<Folder> folders,
    required List<HttpRequest> rootRequests,
  }) async {
    final src = state.firstWhere((c) => c.uid == collectionUid);
    final now = DateTime.now();

    if (parentFolderUid == null) {
      var nextFolderOrder = src.folders.length;
      var nextReqOrder = src.requests.length;
      final appendedFolders = folders.map((f) {
        final copy =
            _deepCopyFolder(f, collectionUid, null, now).copyWith(sortOrder: nextFolderOrder);
        nextFolderOrder++;
        return copy;
      }).toList();
      final appendedReqs = rootRequests.map((r) {
        final copy = _remapRequestForMerge(
          r,
          collectionUid,
          null,
          now,
          nextReqOrder,
        );
        nextReqOrder++;
        return copy;
      }).toList();

      await update(
        src.copyWith(
          folders: [...src.folders, ...appendedFolders],
          requests: [...src.requests, ...appendedReqs],
          updatedAt: now,
        ),
      );
      return;
    }

    final merged = _insertCollectionFragmentIntoFolder(
      src,
      parentFolderUid,
      folders,
      rootRequests,
      now,
    );
    await update(merged);
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

HttpRequest _remapRequestForMerge(
  HttpRequest r,
  String collectionUid,
  String? folderUid,
  DateTime now,
  int sortOrder,
) {
  return r.copyWith(
    uid: const Uuid().v4(),
    collectionUid: collectionUid,
    folderUid: folderUid,
    sortOrder: sortOrder,
    createdAt: now,
    updatedAt: now,
  );
}

Collection _insertCollectionFragmentIntoFolder(
  Collection c,
  String parentFolderUid,
  List<Folder> folders,
  List<HttpRequest> rootRequests,
  DateTime now,
) {
  return c.copyWith(
    folders: _mergeCollectionIntoFolderBranch(
      c.folders,
      parentFolderUid,
      folders,
      rootRequests,
      now,
      c.uid,
    ),
    updatedAt: now,
  );
}

List<Folder> _mergeCollectionIntoFolderBranch(
  List<Folder> folders,
  String targetUid,
  List<Folder> toAddFolders,
  List<HttpRequest> toAddReqs,
  DateTime now,
  String collectionUid,
) {
  return folders.map((f) {
    if (f.uid == targetUid) {
      var fo = f.subFolders.length;
      var ro = f.requests.length;
      final newSubs = [
        ...f.subFolders,
        ...toAddFolders.map((x) {
          final copy = _deepCopyFolder(x, collectionUid, targetUid, now)
              .copyWith(sortOrder: fo);
          fo++;
          return copy;
        }),
      ];
      final newReqs = [
        ...f.requests,
        ...toAddReqs.map((r) {
          final copy =
              _remapRequestForMerge(r, collectionUid, targetUid, now, ro);
          ro++;
          return copy;
        }),
      ];
      return f.copyWith(subFolders: newSubs, requests: newReqs);
    }
    if (f.subFolders.isEmpty) return f;
    return f.copyWith(
      subFolders: _mergeCollectionIntoFolderBranch(
        f.subFolders,
        targetUid,
        toAddFolders,
        toAddReqs,
        now,
        collectionUid,
      ),
    );
  }).toList();
}
