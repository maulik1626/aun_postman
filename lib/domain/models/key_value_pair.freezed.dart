// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'key_value_pair.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

KeyValuePair _$KeyValuePairFromJson(Map<String, dynamic> json) {
  return _KeyValuePair.fromJson(json);
}

/// @nodoc
mixin _$KeyValuePair {
  String get key => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;

  /// Serializes this KeyValuePair to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KeyValuePair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KeyValuePairCopyWith<KeyValuePair> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KeyValuePairCopyWith<$Res> {
  factory $KeyValuePairCopyWith(
    KeyValuePair value,
    $Res Function(KeyValuePair) then,
  ) = _$KeyValuePairCopyWithImpl<$Res, KeyValuePair>;
  @useResult
  $Res call({String key, String value, bool isEnabled});
}

/// @nodoc
class _$KeyValuePairCopyWithImpl<$Res, $Val extends KeyValuePair>
    implements $KeyValuePairCopyWith<$Res> {
  _$KeyValuePairCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KeyValuePair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? isEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            isEnabled: null == isEnabled
                ? _value.isEnabled
                : isEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KeyValuePairImplCopyWith<$Res>
    implements $KeyValuePairCopyWith<$Res> {
  factory _$$KeyValuePairImplCopyWith(
    _$KeyValuePairImpl value,
    $Res Function(_$KeyValuePairImpl) then,
  ) = __$$KeyValuePairImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, String value, bool isEnabled});
}

/// @nodoc
class __$$KeyValuePairImplCopyWithImpl<$Res>
    extends _$KeyValuePairCopyWithImpl<$Res, _$KeyValuePairImpl>
    implements _$$KeyValuePairImplCopyWith<$Res> {
  __$$KeyValuePairImplCopyWithImpl(
    _$KeyValuePairImpl _value,
    $Res Function(_$KeyValuePairImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KeyValuePair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? isEnabled = null,
  }) {
    return _then(
      _$KeyValuePairImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        isEnabled: null == isEnabled
            ? _value.isEnabled
            : isEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$KeyValuePairImpl implements _KeyValuePair {
  const _$KeyValuePairImpl({
    required this.key,
    required this.value,
    this.isEnabled = true,
  });

  factory _$KeyValuePairImpl.fromJson(Map<String, dynamic> json) =>
      _$$KeyValuePairImplFromJson(json);

  @override
  final String key;
  @override
  final String value;
  @override
  @JsonKey()
  final bool isEnabled;

  @override
  String toString() {
    return 'KeyValuePair(key: $key, value: $value, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KeyValuePairImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, key, value, isEnabled);

  /// Create a copy of KeyValuePair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KeyValuePairImplCopyWith<_$KeyValuePairImpl> get copyWith =>
      __$$KeyValuePairImplCopyWithImpl<_$KeyValuePairImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KeyValuePairImplToJson(this);
  }
}

abstract class _KeyValuePair implements KeyValuePair {
  const factory _KeyValuePair({
    required final String key,
    required final String value,
    final bool isEnabled,
  }) = _$KeyValuePairImpl;

  factory _KeyValuePair.fromJson(Map<String, dynamic> json) =
      _$KeyValuePairImpl.fromJson;

  @override
  String get key;
  @override
  String get value;
  @override
  bool get isEnabled;

  /// Create a copy of KeyValuePair
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KeyValuePairImplCopyWith<_$KeyValuePairImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RequestParam _$RequestParamFromJson(Map<String, dynamic> json) {
  return _RequestParam.fromJson(json);
}

/// @nodoc
mixin _$RequestParam {
  String get key => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;

  /// Serializes this RequestParam to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RequestParam
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RequestParamCopyWith<RequestParam> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RequestParamCopyWith<$Res> {
  factory $RequestParamCopyWith(
    RequestParam value,
    $Res Function(RequestParam) then,
  ) = _$RequestParamCopyWithImpl<$Res, RequestParam>;
  @useResult
  $Res call({String key, String value, bool isEnabled});
}

/// @nodoc
class _$RequestParamCopyWithImpl<$Res, $Val extends RequestParam>
    implements $RequestParamCopyWith<$Res> {
  _$RequestParamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RequestParam
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? isEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            isEnabled: null == isEnabled
                ? _value.isEnabled
                : isEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RequestParamImplCopyWith<$Res>
    implements $RequestParamCopyWith<$Res> {
  factory _$$RequestParamImplCopyWith(
    _$RequestParamImpl value,
    $Res Function(_$RequestParamImpl) then,
  ) = __$$RequestParamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, String value, bool isEnabled});
}

/// @nodoc
class __$$RequestParamImplCopyWithImpl<$Res>
    extends _$RequestParamCopyWithImpl<$Res, _$RequestParamImpl>
    implements _$$RequestParamImplCopyWith<$Res> {
  __$$RequestParamImplCopyWithImpl(
    _$RequestParamImpl _value,
    $Res Function(_$RequestParamImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestParam
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? isEnabled = null,
  }) {
    return _then(
      _$RequestParamImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        isEnabled: null == isEnabled
            ? _value.isEnabled
            : isEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RequestParamImpl implements _RequestParam {
  const _$RequestParamImpl({
    required this.key,
    required this.value,
    this.isEnabled = true,
  });

  factory _$RequestParamImpl.fromJson(Map<String, dynamic> json) =>
      _$$RequestParamImplFromJson(json);

  @override
  final String key;
  @override
  final String value;
  @override
  @JsonKey()
  final bool isEnabled;

  @override
  String toString() {
    return 'RequestParam(key: $key, value: $value, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequestParamImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, key, value, isEnabled);

  /// Create a copy of RequestParam
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RequestParamImplCopyWith<_$RequestParamImpl> get copyWith =>
      __$$RequestParamImplCopyWithImpl<_$RequestParamImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RequestParamImplToJson(this);
  }
}

abstract class _RequestParam implements RequestParam {
  const factory _RequestParam({
    required final String key,
    required final String value,
    final bool isEnabled,
  }) = _$RequestParamImpl;

  factory _RequestParam.fromJson(Map<String, dynamic> json) =
      _$RequestParamImpl.fromJson;

  @override
  String get key;
  @override
  String get value;
  @override
  bool get isEnabled;

  /// Create a copy of RequestParam
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RequestParamImplCopyWith<_$RequestParamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RequestHeader _$RequestHeaderFromJson(Map<String, dynamic> json) {
  return _RequestHeader.fromJson(json);
}

/// @nodoc
mixin _$RequestHeader {
  String get key => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;

  /// Serializes this RequestHeader to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RequestHeader
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RequestHeaderCopyWith<RequestHeader> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RequestHeaderCopyWith<$Res> {
  factory $RequestHeaderCopyWith(
    RequestHeader value,
    $Res Function(RequestHeader) then,
  ) = _$RequestHeaderCopyWithImpl<$Res, RequestHeader>;
  @useResult
  $Res call({String key, String value, bool isEnabled});
}

/// @nodoc
class _$RequestHeaderCopyWithImpl<$Res, $Val extends RequestHeader>
    implements $RequestHeaderCopyWith<$Res> {
  _$RequestHeaderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RequestHeader
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? isEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            isEnabled: null == isEnabled
                ? _value.isEnabled
                : isEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RequestHeaderImplCopyWith<$Res>
    implements $RequestHeaderCopyWith<$Res> {
  factory _$$RequestHeaderImplCopyWith(
    _$RequestHeaderImpl value,
    $Res Function(_$RequestHeaderImpl) then,
  ) = __$$RequestHeaderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, String value, bool isEnabled});
}

/// @nodoc
class __$$RequestHeaderImplCopyWithImpl<$Res>
    extends _$RequestHeaderCopyWithImpl<$Res, _$RequestHeaderImpl>
    implements _$$RequestHeaderImplCopyWith<$Res> {
  __$$RequestHeaderImplCopyWithImpl(
    _$RequestHeaderImpl _value,
    $Res Function(_$RequestHeaderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestHeader
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? isEnabled = null,
  }) {
    return _then(
      _$RequestHeaderImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        isEnabled: null == isEnabled
            ? _value.isEnabled
            : isEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RequestHeaderImpl implements _RequestHeader {
  const _$RequestHeaderImpl({
    required this.key,
    required this.value,
    this.isEnabled = true,
  });

  factory _$RequestHeaderImpl.fromJson(Map<String, dynamic> json) =>
      _$$RequestHeaderImplFromJson(json);

  @override
  final String key;
  @override
  final String value;
  @override
  @JsonKey()
  final bool isEnabled;

  @override
  String toString() {
    return 'RequestHeader(key: $key, value: $value, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequestHeaderImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, key, value, isEnabled);

  /// Create a copy of RequestHeader
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RequestHeaderImplCopyWith<_$RequestHeaderImpl> get copyWith =>
      __$$RequestHeaderImplCopyWithImpl<_$RequestHeaderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RequestHeaderImplToJson(this);
  }
}

abstract class _RequestHeader implements RequestHeader {
  const factory _RequestHeader({
    required final String key,
    required final String value,
    final bool isEnabled,
  }) = _$RequestHeaderImpl;

  factory _RequestHeader.fromJson(Map<String, dynamic> json) =
      _$RequestHeaderImpl.fromJson;

  @override
  String get key;
  @override
  String get value;
  @override
  bool get isEnabled;

  /// Create a copy of RequestHeader
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RequestHeaderImplCopyWith<_$RequestHeaderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FormDataField _$FormDataFieldFromJson(Map<String, dynamic> json) {
  return _FormDataField.fromJson(json);
}

/// @nodoc
mixin _$FormDataField {
  String get key => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  bool get isFile => throw _privateConstructorUsedError;
  String? get filePath => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;

  /// Serializes this FormDataField to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FormDataField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FormDataFieldCopyWith<FormDataField> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FormDataFieldCopyWith<$Res> {
  factory $FormDataFieldCopyWith(
    FormDataField value,
    $Res Function(FormDataField) then,
  ) = _$FormDataFieldCopyWithImpl<$Res, FormDataField>;
  @useResult
  $Res call({
    String key,
    String value,
    bool isFile,
    String? filePath,
    bool isEnabled,
  });
}

/// @nodoc
class _$FormDataFieldCopyWithImpl<$Res, $Val extends FormDataField>
    implements $FormDataFieldCopyWith<$Res> {
  _$FormDataFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FormDataField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? isFile = null,
    Object? filePath = freezed,
    Object? isEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            isFile: null == isFile
                ? _value.isFile
                : isFile // ignore: cast_nullable_to_non_nullable
                      as bool,
            filePath: freezed == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            isEnabled: null == isEnabled
                ? _value.isEnabled
                : isEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FormDataFieldImplCopyWith<$Res>
    implements $FormDataFieldCopyWith<$Res> {
  factory _$$FormDataFieldImplCopyWith(
    _$FormDataFieldImpl value,
    $Res Function(_$FormDataFieldImpl) then,
  ) = __$$FormDataFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String key,
    String value,
    bool isFile,
    String? filePath,
    bool isEnabled,
  });
}

/// @nodoc
class __$$FormDataFieldImplCopyWithImpl<$Res>
    extends _$FormDataFieldCopyWithImpl<$Res, _$FormDataFieldImpl>
    implements _$$FormDataFieldImplCopyWith<$Res> {
  __$$FormDataFieldImplCopyWithImpl(
    _$FormDataFieldImpl _value,
    $Res Function(_$FormDataFieldImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FormDataField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? isFile = null,
    Object? filePath = freezed,
    Object? isEnabled = null,
  }) {
    return _then(
      _$FormDataFieldImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        isFile: null == isFile
            ? _value.isFile
            : isFile // ignore: cast_nullable_to_non_nullable
                  as bool,
        filePath: freezed == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        isEnabled: null == isEnabled
            ? _value.isEnabled
            : isEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FormDataFieldImpl implements _FormDataField {
  const _$FormDataFieldImpl({
    required this.key,
    required this.value,
    this.isFile = false,
    this.filePath,
    this.isEnabled = true,
  });

  factory _$FormDataFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$FormDataFieldImplFromJson(json);

  @override
  final String key;
  @override
  final String value;
  @override
  @JsonKey()
  final bool isFile;
  @override
  final String? filePath;
  @override
  @JsonKey()
  final bool isEnabled;

  @override
  String toString() {
    return 'FormDataField(key: $key, value: $value, isFile: $isFile, filePath: $filePath, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FormDataFieldImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.isFile, isFile) || other.isFile == isFile) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, key, value, isFile, filePath, isEnabled);

  /// Create a copy of FormDataField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FormDataFieldImplCopyWith<_$FormDataFieldImpl> get copyWith =>
      __$$FormDataFieldImplCopyWithImpl<_$FormDataFieldImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FormDataFieldImplToJson(this);
  }
}

abstract class _FormDataField implements FormDataField {
  const factory _FormDataField({
    required final String key,
    required final String value,
    final bool isFile,
    final String? filePath,
    final bool isEnabled,
  }) = _$FormDataFieldImpl;

  factory _FormDataField.fromJson(Map<String, dynamic> json) =
      _$FormDataFieldImpl.fromJson;

  @override
  String get key;
  @override
  String get value;
  @override
  bool get isFile;
  @override
  String? get filePath;
  @override
  bool get isEnabled;

  /// Create a copy of FormDataField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FormDataFieldImplCopyWith<_$FormDataFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
