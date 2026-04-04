import 'package:aun_postman/domain/models/history_entry.dart';
import 'package:aun_postman/infrastructure/history_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_provider.g.dart';

@Riverpod(keepAlive: true)
class History extends _$History {
  @override
  List<HistoryEntry> build() {
    return ref.read(historyRepositoryProvider).getAll();
  }

  Future<void> delete(String uid) async {
    await ref.read(historyRepositoryProvider).delete(uid);
    ref.invalidateSelf();
  }

  Future<void> clearAll() async {
    await ref.read(historyRepositoryProvider).clearAll();
    ref.invalidateSelf();
  }
}
