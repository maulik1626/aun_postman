import 'package:aun_postman/domain/models/environment.dart';
import 'package:aun_postman/features/environments/providers/active_environment_provider.dart';
import 'package:aun_postman/infrastructure/environment_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'environments_provider.g.dart';

@Riverpod(keepAlive: true)
class Environments extends _$Environments {
  static const _uuid = Uuid();

  @override
  List<Environment> build() {
    return ref.read(environmentRepositoryProvider).getAll();
  }

  Future<void> create(String name) async {
    final now = DateTime.now();
    final env = Environment(
      uid: _uuid.v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(environmentRepositoryProvider).save(env);
    ref.invalidateSelf();
  }

  Future<void> update(Environment env) async {
    await ref.read(environmentRepositoryProvider).save(
          env.copyWith(updatedAt: DateTime.now()),
        );
    ref.invalidateSelf();
  }

  Future<void> delete(String uid) async {
    await ref.read(environmentRepositoryProvider).delete(uid);
    ref.invalidateSelf();
  }

  Future<void> clearAll() async {
    for (final e in state) {
      await ref.read(environmentRepositoryProvider).delete(e.uid);
    }
    ref.invalidateSelf();
  }

  Future<void> setActive(String uid) async {
    await ref.read(environmentRepositoryProvider).setActive(uid);
    ref.invalidateSelf();
    ref.invalidate(activeEnvironmentProvider);
  }
}
