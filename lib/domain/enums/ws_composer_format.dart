import 'package:json_annotation/json_annotation.dart';

/// Outgoing message encoding selected in the WebSocket composer.
enum WsComposerFormat {
  @JsonValue('text')
  text,
  @JsonValue('json')
  json,
  @JsonValue('binary_hex')
  binaryHex,
  @JsonValue('binary_base64')
  binaryBase64,
}
