// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_value_pair.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KeyValuePairImpl _$$KeyValuePairImplFromJson(Map<String, dynamic> json) =>
    _$KeyValuePairImpl(
      key: json['key'] as String,
      value: json['value'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$KeyValuePairImplToJson(_$KeyValuePairImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'isEnabled': instance.isEnabled,
    };

_$RequestParamImpl _$$RequestParamImplFromJson(Map<String, dynamic> json) =>
    _$RequestParamImpl(
      key: json['key'] as String,
      value: json['value'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$RequestParamImplToJson(_$RequestParamImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'isEnabled': instance.isEnabled,
    };

_$RequestHeaderImpl _$$RequestHeaderImplFromJson(Map<String, dynamic> json) =>
    _$RequestHeaderImpl(
      key: json['key'] as String,
      value: json['value'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$RequestHeaderImplToJson(_$RequestHeaderImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'isEnabled': instance.isEnabled,
    };

_$FormDataFieldImpl _$$FormDataFieldImplFromJson(Map<String, dynamic> json) =>
    _$FormDataFieldImpl(
      key: json['key'] as String,
      value: json['value'] as String,
      isFile: json['isFile'] as bool? ?? false,
      filePath: json['filePath'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$FormDataFieldImplToJson(_$FormDataFieldImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'isFile': instance.isFile,
      'filePath': instance.filePath,
      'isEnabled': instance.isEnabled,
    };
