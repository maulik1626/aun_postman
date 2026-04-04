// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'response_cookie.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ResponseCookie _$ResponseCookieFromJson(Map<String, dynamic> json) {
  return _ResponseCookie.fromJson(json);
}

/// @nodoc
mixin _$ResponseCookie {
  String get name => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  String? get domain => throw _privateConstructorUsedError;
  String? get path => throw _privateConstructorUsedError;
  DateTime? get expires => throw _privateConstructorUsedError;
  bool get httpOnly => throw _privateConstructorUsedError;
  bool get secure => throw _privateConstructorUsedError;

  /// Serializes this ResponseCookie to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ResponseCookie
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResponseCookieCopyWith<ResponseCookie> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResponseCookieCopyWith<$Res> {
  factory $ResponseCookieCopyWith(
    ResponseCookie value,
    $Res Function(ResponseCookie) then,
  ) = _$ResponseCookieCopyWithImpl<$Res, ResponseCookie>;
  @useResult
  $Res call({
    String name,
    String value,
    String? domain,
    String? path,
    DateTime? expires,
    bool httpOnly,
    bool secure,
  });
}

/// @nodoc
class _$ResponseCookieCopyWithImpl<$Res, $Val extends ResponseCookie>
    implements $ResponseCookieCopyWith<$Res> {
  _$ResponseCookieCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ResponseCookie
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? value = null,
    Object? domain = freezed,
    Object? path = freezed,
    Object? expires = freezed,
    Object? httpOnly = null,
    Object? secure = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            domain: freezed == domain
                ? _value.domain
                : domain // ignore: cast_nullable_to_non_nullable
                      as String?,
            path: freezed == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String?,
            expires: freezed == expires
                ? _value.expires
                : expires // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            httpOnly: null == httpOnly
                ? _value.httpOnly
                : httpOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            secure: null == secure
                ? _value.secure
                : secure // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ResponseCookieImplCopyWith<$Res>
    implements $ResponseCookieCopyWith<$Res> {
  factory _$$ResponseCookieImplCopyWith(
    _$ResponseCookieImpl value,
    $Res Function(_$ResponseCookieImpl) then,
  ) = __$$ResponseCookieImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String value,
    String? domain,
    String? path,
    DateTime? expires,
    bool httpOnly,
    bool secure,
  });
}

/// @nodoc
class __$$ResponseCookieImplCopyWithImpl<$Res>
    extends _$ResponseCookieCopyWithImpl<$Res, _$ResponseCookieImpl>
    implements _$$ResponseCookieImplCopyWith<$Res> {
  __$$ResponseCookieImplCopyWithImpl(
    _$ResponseCookieImpl _value,
    $Res Function(_$ResponseCookieImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ResponseCookie
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? value = null,
    Object? domain = freezed,
    Object? path = freezed,
    Object? expires = freezed,
    Object? httpOnly = null,
    Object? secure = null,
  }) {
    return _then(
      _$ResponseCookieImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        domain: freezed == domain
            ? _value.domain
            : domain // ignore: cast_nullable_to_non_nullable
                  as String?,
        path: freezed == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String?,
        expires: freezed == expires
            ? _value.expires
            : expires // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        httpOnly: null == httpOnly
            ? _value.httpOnly
            : httpOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        secure: null == secure
            ? _value.secure
            : secure // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ResponseCookieImpl implements _ResponseCookie {
  const _$ResponseCookieImpl({
    required this.name,
    required this.value,
    this.domain,
    this.path,
    this.expires,
    this.httpOnly = false,
    this.secure = false,
  });

  factory _$ResponseCookieImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResponseCookieImplFromJson(json);

  @override
  final String name;
  @override
  final String value;
  @override
  final String? domain;
  @override
  final String? path;
  @override
  final DateTime? expires;
  @override
  @JsonKey()
  final bool httpOnly;
  @override
  @JsonKey()
  final bool secure;

  @override
  String toString() {
    return 'ResponseCookie(name: $name, value: $value, domain: $domain, path: $path, expires: $expires, httpOnly: $httpOnly, secure: $secure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResponseCookieImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.domain, domain) || other.domain == domain) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.expires, expires) || other.expires == expires) &&
            (identical(other.httpOnly, httpOnly) ||
                other.httpOnly == httpOnly) &&
            (identical(other.secure, secure) || other.secure == secure));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    value,
    domain,
    path,
    expires,
    httpOnly,
    secure,
  );

  /// Create a copy of ResponseCookie
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResponseCookieImplCopyWith<_$ResponseCookieImpl> get copyWith =>
      __$$ResponseCookieImplCopyWithImpl<_$ResponseCookieImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ResponseCookieImplToJson(this);
  }
}

abstract class _ResponseCookie implements ResponseCookie {
  const factory _ResponseCookie({
    required final String name,
    required final String value,
    final String? domain,
    final String? path,
    final DateTime? expires,
    final bool httpOnly,
    final bool secure,
  }) = _$ResponseCookieImpl;

  factory _ResponseCookie.fromJson(Map<String, dynamic> json) =
      _$ResponseCookieImpl.fromJson;

  @override
  String get name;
  @override
  String get value;
  @override
  String? get domain;
  @override
  String? get path;
  @override
  DateTime? get expires;
  @override
  bool get httpOnly;
  @override
  bool get secure;

  /// Create a copy of ResponseCookie
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResponseCookieImplCopyWith<_$ResponseCookieImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
