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

_$OAuth2AuthImpl _$$OAuth2AuthImplFromJson(Map<String, dynamic> json) =>
    _$OAuth2AuthImpl(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresAtSecs: (json['expiresAtSecs'] as num?)?.toInt(),
      tokenUrl: json['tokenUrl'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      grantType:
          $enumDecodeNullable(_$OAuth2GrantTypeEnumMap, json['grantType']) ??
          OAuth2GrantType.clientCredentials,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$OAuth2AuthImplToJson(_$OAuth2AuthImpl instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'tokenType': instance.tokenType,
      'expiresAtSecs': instance.expiresAtSecs,
      'tokenUrl': instance.tokenUrl,
      'clientId': instance.clientId,
      'clientSecret': instance.clientSecret,
      'scope': instance.scope,
      'username': instance.username,
      'password': instance.password,
      'grantType': _$OAuth2GrantTypeEnumMap[instance.grantType]!,
      'runtimeType': instance.$type,
    };

const _$OAuth2GrantTypeEnumMap = {
  OAuth2GrantType.clientCredentials: 'clientCredentials',
  OAuth2GrantType.password: 'password',
};

_$DigestAuthImpl _$$DigestAuthImplFromJson(Map<String, dynamic> json) =>
    _$DigestAuthImpl(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$DigestAuthImplToJson(_$DigestAuthImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'runtimeType': instance.$type,
    };

_$AwsSigV4AuthImpl _$$AwsSigV4AuthImplFromJson(Map<String, dynamic> json) =>
    _$AwsSigV4AuthImpl(
      accessKeyId: json['accessKeyId'] as String? ?? '',
      secretAccessKey: json['secretAccessKey'] as String? ?? '',
      sessionToken: json['sessionToken'] as String? ?? '',
      region: json['region'] as String? ?? 'us-east-1',
      service: json['service'] as String? ?? 'execute-api',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$AwsSigV4AuthImplToJson(_$AwsSigV4AuthImpl instance) =>
    <String, dynamic>{
      'accessKeyId': instance.accessKeyId,
      'secretAccessKey': instance.secretAccessKey,
      'sessionToken': instance.sessionToken,
      'region': instance.region,
      'service': instance.service,
      'runtimeType': instance.$type,
    };
