import 'package:aun_reqstudio/core/errors/app_exception.dart';
import 'package:aun_reqstudio/data/local/daos/history_dao.dart';
import 'package:aun_reqstudio/data/local/hive_service.dart';
import 'package:aun_reqstudio/domain/models/history_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_repository.g.dart';

@Riverpod(keepAlive: true)
HistoryRepository historyRepository(HistoryRepositoryRef ref) {
  final box = ref.watch(hiveBoxProvider(HiveBoxes.history));
  return HistoryRepository(HistoryDao(box));
}

class HistoryRepository {
  HistoryRepository(this._dao);
  final HistoryDao _dao;

  List<HistoryEntry> getAll() {
    try {
      return _dao.getAll();
    } catch (e) {
      throw StorageException('Failed to load history: $e');
    }
  }

  Future<void> save(HistoryEntry entry) async {
    try {
      await _dao.save(entry);
    } catch (e) {
      throw StorageException('Failed to save history entry: $e');
    }
  }

  Future<void> delete(String uid) async {
    try {
      await _dao.delete(uid);
    } catch (e) {
      throw StorageException('Failed to delete history entry: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _dao.clearAll();
    } catch (e) {
      throw StorageException('Failed to clear history: $e');
    }
  }
}
