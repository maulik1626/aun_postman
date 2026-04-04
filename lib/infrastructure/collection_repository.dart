import 'package:aun_postman/core/errors/app_exception.dart';
import 'package:aun_postman/data/local/daos/collection_dao.dart';
import 'package:aun_postman/data/local/hive_service.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'collection_repository.g.dart';

@Riverpod(keepAlive: true)
CollectionRepository collectionRepository(CollectionRepositoryRef ref) {
  final collectionsBox = ref.watch(hiveBoxProvider(HiveBoxes.collections));
  final foldersBox = ref.watch(hiveBoxProvider(HiveBoxes.folders));
  final requestsBox = ref.watch(hiveBoxProvider(HiveBoxes.requests));
  return CollectionRepository(
    CollectionDao(collectionsBox, foldersBox, requestsBox),
  );
}

class CollectionRepository {
  CollectionRepository(this._dao);
  final CollectionDao _dao;

  List<Collection> getAll() {
    try {
      return _dao.getAll();
    } catch (e) {
      throw StorageException('Failed to load collections: $e');
    }
  }

  Collection? getByUid(String uid) {
    try {
      return _dao.getByUid(uid);
    } catch (e) {
      throw StorageException('Failed to load collection: $e');
    }
  }

  Future<void> save(Collection collection) async {
    try {
      await _dao.upsert(collection);
    } catch (e) {
      throw StorageException('Failed to save collection: $e');
    }
  }

  Future<void> delete(String uid) async {
    try {
      await _dao.delete(uid);
    } catch (e) {
      throw StorageException('Failed to delete collection: $e');
    }
  }

  Future<void> updateSortOrders(List<String> orderedUids) async {
    try {
      await _dao.updateSortOrders(orderedUids);
    } catch (e) {
      throw StorageException('Failed to reorder collections: $e');
    }
  }
}
