import 'package:aun_reqstudio/domain/enums/ws_composer_format.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ws_composer_draft_provider.g.dart';

/// Latest composer text per WebSocket tab (for global actions e.g. Save from sheet).
@Riverpod(keepAlive: true)
class WsComposerDraft extends _$WsComposerDraft {
  @override
  String build(String sessionId) => '';

  void setDraft(String text) {
    if (state != text) state = text;
  }
}

/// Selected composer format per tab (mirrors panel state for bookmark Save).
@Riverpod(keepAlive: true)
class WsComposerFormatLive extends _$WsComposerFormatLive {
  @override
  WsComposerFormat build(String sessionId) => WsComposerFormat.text;

  void setFormat(WsComposerFormat format) {
    if (state != format) state = format;
  }
}
