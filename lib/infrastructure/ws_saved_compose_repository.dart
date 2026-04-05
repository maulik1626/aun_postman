import 'package:aun_postman/core/errors/app_exception.dart';
import 'package:aun_postman/data/local/daos/ws_saved_compose_dao.dart';
import 'package:aun_postman/data/local/hive_service.dart';
import 'package:aun_postman/domain/models/ws_saved_compose_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ws_saved_compose_repository.g.dart';

@Riverpod(keepAlive: true)
WsSavedComposeRepository wsSavedComposeRepository(
  WsSavedComposeRepositoryRef ref,
) {
  final box = ref.watch(hiveBoxProvider(HiveBoxes.wsSavedCompose));
  return WsSavedComposeRepository(WsSavedComposeDao(box));
}

class WsSavedComposeRepository {
  WsSavedComposeRepository(this._dao);
  final WsSavedComposeDao _dao;

  List<WsSavedComposeMessage> getAll() {
    try {
      return _dao.getAll();
    } catch (e) {
      throw StorageException('Failed to load saved WebSocket messages: $e');
    }
  }

  Future<void> save(WsSavedComposeMessage message) async {
    try {
      await _dao.upsert(message);
    } catch (e) {
      throw StorageException('Failed to save WebSocket message: $e');
    }
  }

  Future<void> delete(String uid) async {
    try {
      await _dao.delete(uid);
    } catch (e) {
      throw StorageException('Failed to delete saved WebSocket message: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _dao.clearAll();
    } catch (e) {
      throw StorageException('Failed to clear saved WebSocket messages: $e');
    }
  }
}
