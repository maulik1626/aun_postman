import 'package:freezed_annotation/freezed_annotation.dart';

part 'key_value_pair.freezed.dart';
part 'key_value_pair.g.dart';

@freezed
class KeyValuePair with _$KeyValuePair {
  const factory KeyValuePair({
    required String key,
    required String value,
    @Default(true) bool isEnabled,
  }) = _KeyValuePair;

  factory KeyValuePair.fromJson(Map<String, dynamic> json) =>
      _$KeyValuePairFromJson(json);
}

@freezed
class RequestParam with _$RequestParam {
  const factory RequestParam({
    required String key,
    required String value,
    @Default(true) bool isEnabled,
  }) = _RequestParam;

  factory RequestParam.fromJson(Map<String, dynamic> json) =>
      _$RequestParamFromJson(json);
}

@freezed
class RequestHeader with _$RequestHeader {
  const factory RequestHeader({
    required String key,
    required String value,
    @Default(true) bool isEnabled,
  }) = _RequestHeader;

  factory RequestHeader.fromJson(Map<String, dynamic> json) =>
      _$RequestHeaderFromJson(json);
}

@freezed
class FormDataField with _$FormDataField {
  const factory FormDataField({
    required String key,
    required String value,
    @Default(false) bool isFile,
    String? filePath,
    @Default(true) bool isEnabled,
  }) = _FormDataField;

  factory FormDataField.fromJson(Map<String, dynamic> json) =>
      _$FormDataFieldFromJson(json);
}
