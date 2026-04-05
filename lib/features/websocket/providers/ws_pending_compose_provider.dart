import 'package:aun_postman/domain/enums/ws_composer_format.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ws_pending_compose_provider.g.dart';

/// Queues a saved snippet to be applied to the active tab’s composer.
class WsPendingCompose {
  const WsPendingCompose({
    required this.sessionId,
    required this.body,
    required this.format,
  });

  final String sessionId;
  final String body;
  final WsComposerFormat format;
}

@Riverpod(keepAlive: true)
class WsPendingComposeNotifier extends _$WsPendingComposeNotifier {
  @override
  WsPendingCompose? build() => null;

  void enqueue(WsPendingCompose value) => state = value;

  void clear() => state = null;
}
