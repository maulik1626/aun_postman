// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'environment_variable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EnvironmentVariable _$EnvironmentVariableFromJson(Map<String, dynamic> json) {
  return _EnvironmentVariable.fromJson(json);
}

/// @nodoc
mixin _$EnvironmentVariable {
  String get uid => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;
  bool get isSecret => throw _privateConstructorUsedError;

  /// Serializes this EnvironmentVariable to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EnvironmentVariable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnvironmentVariableCopyWith<EnvironmentVariable> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnvironmentVariableCopyWith<$Res> {
  factory $EnvironmentVariableCopyWith(
    EnvironmentVariable value,
    $Res Function(EnvironmentVariable) then,
  ) = _$EnvironmentVariableCopyWithImpl<$Res, EnvironmentVariable>;
  @useResult
  $Res call({
    String uid,
    String key,
    String value,
    bool isEnabled,
    bool isSecret,
  });
}

/// @nodoc
class _$EnvironmentVariableCopyWithImpl<$Res, $Val extends EnvironmentVariable>
    implements $EnvironmentVariableCopyWith<$Res> {
  _$EnvironmentVariableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EnvironmentVariable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? key = null,
    Object? value = null,
    Object? isEnabled = null,
    Object? isSecret = null,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
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
            isSecret: null == isSecret
                ? _value.isSecret
                : isSecret // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EnvironmentVariableImplCopyWith<$Res>
    implements $EnvironmentVariableCopyWith<$Res> {
  factory _$$EnvironmentVariableImplCopyWith(
    _$EnvironmentVariableImpl value,
    $Res Function(_$EnvironmentVariableImpl) then,
  ) = __$$EnvironmentVariableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String key,
    String value,
    bool isEnabled,
    bool isSecret,
  });
}

/// @nodoc
class __$$EnvironmentVariableImplCopyWithImpl<$Res>
    extends _$EnvironmentVariableCopyWithImpl<$Res, _$EnvironmentVariableImpl>
    implements _$$EnvironmentVariableImplCopyWith<$Res> {
  __$$EnvironmentVariableImplCopyWithImpl(
    _$EnvironmentVariableImpl _value,
    $Res Function(_$EnvironmentVariableImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EnvironmentVariable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? key = null,
    Object? value = null,
    Object? isEnabled = null,
    Object? isSecret = null,
  }) {
    return _then(
      _$EnvironmentVariableImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
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
        isSecret: null == isSecret
            ? _value.isSecret
            : isSecret // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EnvironmentVariableImpl implements _EnvironmentVariable {
  const _$EnvironmentVariableImpl({
    required this.uid,
    required this.key,
    this.value = '',
    this.isEnabled = true,
    this.isSecret = false,
  });

  factory _$EnvironmentVariableImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnvironmentVariableImplFromJson(json);

  @override
  final String uid;
  @override
  final String key;
  @override
  @JsonKey()
  final String value;
  @override
  @JsonKey()
  final bool isEnabled;
  @override
  @JsonKey()
  final bool isSecret;

  @override
  String toString() {
    return 'EnvironmentVariable(uid: $uid, key: $key, value: $value, isEnabled: $isEnabled, isSecret: $isSecret)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnvironmentVariableImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.isSecret, isSecret) ||
                other.isSecret == isSecret));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, uid, key, value, isEnabled, isSecret);

  /// Create a copy of EnvironmentVariable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnvironmentVariableImplCopyWith<_$EnvironmentVariableImpl> get copyWith =>
      __$$EnvironmentVariableImplCopyWithImpl<_$EnvironmentVariableImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EnvironmentVariableImplToJson(this);
  }
}

abstract class _EnvironmentVariable implements EnvironmentVariable {
  const factory _EnvironmentVariable({
    required final String uid,
    required final String key,
    final String value,
    final bool isEnabled,
    final bool isSecret,
  }) = _$EnvironmentVariableImpl;

  factory _EnvironmentVariable.fromJson(Map<String, dynamic> json) =
      _$EnvironmentVariableImpl.fromJson;

  @override
  String get uid;
  @override
  String get key;
  @override
  String get value;
  @override
  bool get isEnabled;
  @override
  bool get isSecret;

  /// Create a copy of EnvironmentVariable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnvironmentVariableImplCopyWith<_$EnvironmentVariableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
