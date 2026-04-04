// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoBodyImpl _$$NoBodyImplFromJson(Map<String, dynamic> json) =>
    _$NoBodyImpl($type: json['runtimeType'] as String?);

Map<String, dynamic> _$$NoBodyImplToJson(_$NoBodyImpl instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

_$RawJsonBodyImpl _$$RawJsonBodyImplFromJson(Map<String, dynamic> json) =>
    _$RawJsonBodyImpl(
      content: json['content'] as String? ?? '',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$RawJsonBodyImplToJson(_$RawJsonBodyImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'runtimeType': instance.$type,
    };

_$RawXmlBodyImpl _$$RawXmlBodyImplFromJson(Map<String, dynamic> json) =>
    _$RawXmlBodyImpl(
      content: json['content'] as String? ?? '',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$RawXmlBodyImplToJson(_$RawXmlBodyImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'runtimeType': instance.$type,
    };

_$RawTextBodyImpl _$$RawTextBodyImplFromJson(Map<String, dynamic> json) =>
    _$RawTextBodyImpl(
      content: json['content'] as String? ?? '',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$RawTextBodyImplToJson(_$RawTextBodyImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'runtimeType': instance.$type,
    };

_$RawHtmlBodyImpl _$$RawHtmlBodyImplFromJson(Map<String, dynamic> json) =>
    _$RawHtmlBodyImpl(
      content: json['content'] as String? ?? '',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$RawHtmlBodyImplToJson(_$RawHtmlBodyImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'runtimeType': instance.$type,
    };

_$FormDataBodyImpl _$$FormDataBodyImplFromJson(Map<String, dynamic> json) =>
    _$FormDataBodyImpl(
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map((e) => FormDataField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$FormDataBodyImplToJson(_$FormDataBodyImpl instance) =>
    <String, dynamic>{'fields': instance.fields, 'runtimeType': instance.$type};

_$UrlEncodedBodyImpl _$$UrlEncodedBodyImplFromJson(Map<String, dynamic> json) =>
    _$UrlEncodedBodyImpl(
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$UrlEncodedBodyImplToJson(
  _$UrlEncodedBodyImpl instance,
) => <String, dynamic>{
  'fields': instance.fields,
  'runtimeType': instance.$type,
};

_$BinaryBodyImpl _$$BinaryBodyImplFromJson(Map<String, dynamic> json) =>
    _$BinaryBodyImpl(
      filePath: json['filePath'] as String,
      mimeType: json['mimeType'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$BinaryBodyImplToJson(_$BinaryBodyImpl instance) =>
    <String, dynamic>{
      'filePath': instance.filePath,
      'mimeType': instance.mimeType,
      'runtimeType': instance.$type,
    };
