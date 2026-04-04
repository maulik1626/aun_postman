// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_cookie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ResponseCookieImpl _$$ResponseCookieImplFromJson(Map<String, dynamic> json) =>
    _$ResponseCookieImpl(
      name: json['name'] as String,
      value: json['value'] as String,
      domain: json['domain'] as String?,
      path: json['path'] as String?,
      expires: json['expires'] == null
          ? null
          : DateTime.parse(json['expires'] as String),
      httpOnly: json['httpOnly'] as bool? ?? false,
      secure: json['secure'] as bool? ?? false,
    );

Map<String, dynamic> _$$ResponseCookieImplToJson(
  _$ResponseCookieImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'value': instance.value,
  'domain': instance.domain,
  'path': instance.path,
  'expires': instance.expires?.toIso8601String(),
  'httpOnly': instance.httpOnly,
  'secure': instance.secure,
};
