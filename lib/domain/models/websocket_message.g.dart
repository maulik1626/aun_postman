// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSocketMessageImpl _$$WebSocketMessageImplFromJson(
  Map<String, dynamic> json,
) => _$WebSocketMessageImpl(
  id: json['id'] as String,
  content: json['content'] as String,
  direction: $enumDecode(_$WsMessageDirectionEnumMap, json['direction']),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$WebSocketMessageImplToJson(
  _$WebSocketMessageImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'direction': _$WsMessageDirectionEnumMap[instance.direction]!,
  'timestamp': instance.timestamp.toIso8601String(),
};

const _$WsMessageDirectionEnumMap = {
  WsMessageDirection.sent: 'sent',
  WsMessageDirection.received: 'received',
};
