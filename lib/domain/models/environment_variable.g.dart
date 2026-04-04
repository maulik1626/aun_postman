// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_variable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnvironmentVariableImpl _$$EnvironmentVariableImplFromJson(
  Map<String, dynamic> json,
) => _$EnvironmentVariableImpl(
  uid: json['uid'] as String,
  key: json['key'] as String,
  value: json['value'] as String? ?? '',
  isEnabled: json['isEnabled'] as bool? ?? true,
  isSecret: json['isSecret'] as bool? ?? false,
);

Map<String, dynamic> _$$EnvironmentVariableImplToJson(
  _$EnvironmentVariableImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'key': instance.key,
  'value': instance.value,
  'isEnabled': instance.isEnabled,
  'isSecret': instance.isSecret,
};
