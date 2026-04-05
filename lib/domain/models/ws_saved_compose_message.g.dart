// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_saved_compose_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WsSavedComposeMessageImpl _$$WsSavedComposeMessageImplFromJson(
  Map<String, dynamic> json,
) => _$WsSavedComposeMessageImpl(
  uid: json['uid'] as String,
  body: json['body'] as String,
  format:
      $enumDecodeNullable(_$WsComposerFormatEnumMap, json['format']) ??
      WsComposerFormat.text,
  savedAt: DateTime.parse(json['savedAt'] as String),
);

Map<String, dynamic> _$$WsSavedComposeMessageImplToJson(
  _$WsSavedComposeMessageImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'body': instance.body,
  'format': _$WsComposerFormatEnumMap[instance.format]!,
  'savedAt': instance.savedAt.toIso8601String(),
};

const _$WsComposerFormatEnumMap = {
  WsComposerFormat.text: 'text',
  WsComposerFormat.json: 'json',
  WsComposerFormat.binaryHex: 'binary_hex',
  WsComposerFormat.binaryBase64: 'binary_base64',
};
