// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoAuthImpl _$$NoAuthImplFromJson(Map<String, dynamic> json) =>
    _$NoAuthImpl($type: json['runtimeType'] as String?);

Map<String, dynamic> _$$NoAuthImplToJson(_$NoAuthImpl instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

_$BearerAuthImpl _$$BearerAuthImplFromJson(Map<String, dynamic> json) =>
    _$BearerAuthImpl(
      token: json['token'] as String? ?? '',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$BearerAuthImplToJson(_$BearerAuthImpl instance) =>
    <String, dynamic>{'token': instance.token, 'runtimeType': instance.$type};

_$BasicAuthImpl _$$BasicAuthImplFromJson(Map<String, dynamic> json) =>
    _$BasicAuthImpl(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$BasicAuthImplToJson(_$BasicAuthImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'runtimeType': instance.$type,
    };

_$ApiKeyAuthImpl _$$ApiKeyAuthImplFromJson(Map<String, dynamic> json) =>
    _$ApiKeyAuthImpl(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      addTo:
          $enumDecodeNullable(_$ApiKeyAddToEnumMap, json['addTo']) ??
          ApiKeyAddTo.header,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ApiKeyAuthImplToJson(_$ApiKeyAuthImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'addTo': _$ApiKeyAddToEnumMap[instance.addTo]!,
      'runtimeType': instance.$type,
    };

const _$ApiKeyAddToEnumMap = {
  ApiKeyAddTo.header: 'header',
  ApiKeyAddTo.query: 'query',
};
