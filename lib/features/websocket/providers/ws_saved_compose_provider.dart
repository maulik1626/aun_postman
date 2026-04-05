import 'package:aun_postman/domain/enums/ws_composer_format.dart';
import 'package:aun_postman/domain/models/ws_saved_compose_message.dart';
import 'package:aun_postman/infrastructure/ws_saved_compose_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'ws_saved_compose_provider.g.dart';

@Riverpod(keepAlive: true)
class WsSavedComposeList extends _$WsSavedComposeList {
  static const _uuid = Uuid();

  @override
  List<WsSavedComposeMessage> build() {
    return ref.read(wsSavedComposeRepositoryProvider).getAll();
  }

  Future<void> saveNow(WsSavedComposeMessage message) async {
    await ref.read(wsSavedComposeRepositoryProvider).save(message);
    ref.invalidateSelf();
  }

  Future<void> saveBody({
    required String body,
    required WsComposerFormat format,
  }) async {
    final now = DateTime.now();
    final message = WsSavedComposeMessage(
      uid: _uuid.v4(),
      body: body,
      format: format,
      savedAt: now,
    );
    await saveNow(message);
  }

  Future<void> delete(String uid) async {
    await ref.read(wsSavedComposeRepositoryProvider).delete(uid);
    ref.invalidateSelf();
  }
}
