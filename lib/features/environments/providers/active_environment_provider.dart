import 'package:aun_postman/domain/models/environment.dart';
import 'package:aun_postman/infrastructure/environment_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_environment_provider.g.dart';

@Riverpod(keepAlive: true)
class ActiveEnvironment extends _$ActiveEnvironment {
  @override
  Environment? build() {
    return ref.read(environmentRepositoryProvider).getActive();
  }

  Future<void> setActive(String uid) async {
    await ref.read(environmentRepositoryProvider).setActive(uid);
    ref.invalidateSelf();
  }

  Future<void> clearActive() async {
    await ref.read(environmentRepositoryProvider).clearActive();
    state = null;
  }
}
