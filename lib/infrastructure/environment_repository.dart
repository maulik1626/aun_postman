import 'package:aun_postman/core/errors/app_exception.dart';
import 'package:aun_postman/data/local/daos/environment_dao.dart';
import 'package:aun_postman/data/local/hive_service.dart';
import 'package:aun_postman/domain/models/environment.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'environment_repository.g.dart';

@Riverpod(keepAlive: true)
EnvironmentRepository environmentRepository(EnvironmentRepositoryRef ref) {
  final envBox = ref.watch(hiveBoxProvider(HiveBoxes.environments));
  final varBox = ref.watch(hiveBoxProvider(HiveBoxes.envVariables));
  return EnvironmentRepository(EnvironmentDao(envBox, varBox));
}

class EnvironmentRepository {
  EnvironmentRepository(this._dao);
  final EnvironmentDao _dao;

  List<Environment> getAll() {
    try {
      return _dao.getAll();
    } catch (e) {
      throw StorageException('Failed to load environments: $e');
    }
  }

  Environment? getActive() {
    try {
      return _dao.getActive();
    } catch (e) {
      throw StorageException('Failed to load active environment: $e');
    }
  }

  Future<void> save(Environment env) async {
    try {
      await _dao.upsert(env);
    } catch (e) {
      throw StorageException('Failed to save environment: $e');
    }
  }

  Future<void> setActive(String uid) async {
    try {
      await _dao.setActive(uid);
    } catch (e) {
      throw StorageException('Failed to activate environment: $e');
    }
  }

  Future<void> clearActive() async {
    try {
      await _dao.clearActive();
    } catch (e) {
      throw StorageException('Failed to clear active environment: $e');
    }
  }

  Future<void> delete(String uid) async {
    try {
      await _dao.delete(uid);
    } catch (e) {
      throw StorageException('Failed to delete environment: $e');
    }
  }
}
