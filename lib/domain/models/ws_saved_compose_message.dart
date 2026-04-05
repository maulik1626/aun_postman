import 'package:aun_postman/domain/enums/ws_composer_format.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ws_saved_compose_message.freezed.dart';
part 'ws_saved_compose_message.g.dart';

@freezed
class WsSavedComposeMessage with _$WsSavedComposeMessage {
  const factory WsSavedComposeMessage({
    required String uid,
    required String body,
    @Default(WsComposerFormat.text) WsComposerFormat format,
    required DateTime savedAt,
  }) = _WsSavedComposeMessage;

  factory WsSavedComposeMessage.fromJson(Map<String, dynamic> json) =>
      _$WsSavedComposeMessageFromJson(json);
}
