// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HistoryEntryImpl _$$HistoryEntryImplFromJson(Map<String, dynamic> json) =>
    _$HistoryEntryImpl(
      uid: json['uid'] as String,
      request: HttpRequest.fromJson(json['request'] as Map<String, dynamic>),
      response: HttpResponse.fromJson(json['response'] as Map<String, dynamic>),
      executedAt: DateTime.parse(json['executedAt'] as String),
    );

Map<String, dynamic> _$$HistoryEntryImplToJson(_$HistoryEntryImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'request': instance.request,
      'response': instance.response,
      'executedAt': instance.executedAt.toIso8601String(),
    };
