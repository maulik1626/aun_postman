// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HttpRequestImpl _$$HttpRequestImplFromJson(Map<String, dynamic> json) =>
    _$HttpRequestImpl(
      uid: json['uid'] as String,
      name: json['name'] as String,
      method: $enumDecode(_$HttpMethodEnumMap, json['method']),
      url: json['url'] as String? ?? '',
      params:
          (json['params'] as List<dynamic>?)
              ?.map((e) => RequestParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      headers:
          (json['headers'] as List<dynamic>?)
              ?.map((e) => RequestHeader.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      body: RequestBody.fromJson(json['body'] as Map<String, dynamic>),
      auth: AuthConfig.fromJson(json['auth'] as Map<String, dynamic>),
      collectionUid: json['collectionUid'] as String?,
      folderUid: json['folderUid'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$HttpRequestImplToJson(_$HttpRequestImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'method': _$HttpMethodEnumMap[instance.method]!,
      'url': instance.url,
      'params': instance.params,
      'headers': instance.headers,
      'body': instance.body,
      'auth': instance.auth,
      'collectionUid': instance.collectionUid,
      'folderUid': instance.folderUid,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$HttpMethodEnumMap = {
  HttpMethod.get: 'get',
  HttpMethod.post: 'post',
  HttpMethod.put: 'put',
  HttpMethod.patch: 'patch',
  HttpMethod.delete: 'delete',
  HttpMethod.head: 'head',
  HttpMethod.options: 'options',
};
