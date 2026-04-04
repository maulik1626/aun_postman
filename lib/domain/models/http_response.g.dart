// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HttpResponseImpl _$$HttpResponseImplFromJson(Map<String, dynamic> json) =>
    _$HttpResponseImpl(
      statusCode: (json['statusCode'] as num).toInt(),
      statusMessage: json['statusMessage'] as String,
      headers:
          (json['headers'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      body: json['body'] as String? ?? '',
      durationMs: (json['durationMs'] as num).toInt(),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      cookies:
          (json['cookies'] as List<dynamic>?)
              ?.map((e) => ResponseCookie.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      receivedAt: DateTime.parse(json['receivedAt'] as String),
    );

Map<String, dynamic> _$$HttpResponseImplToJson(_$HttpResponseImpl instance) =>
    <String, dynamic>{
      'statusCode': instance.statusCode,
      'statusMessage': instance.statusMessage,
      'headers': instance.headers,
      'body': instance.body,
      'durationMs': instance.durationMs,
      'sizeBytes': instance.sizeBytes,
      'cookies': instance.cookies,
      'receivedAt': instance.receivedAt.toIso8601String(),
    };
