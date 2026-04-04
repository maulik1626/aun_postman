// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuthConfig _$AuthConfigFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'none':
      return NoAuth.fromJson(json);
    case 'bearer':
      return BearerAuth.fromJson(json);
    case 'basic':
      return BasicAuth.fromJson(json);
    case 'apiKey':
      return ApiKeyAuth.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'AuthConfig',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$AuthConfig {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String token) bearer,
    required TResult Function(String username, String password) basic,
    required TResult Function(String key, String value, ApiKeyAddTo addTo)
    apiKey,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoAuth value) none,
    required TResult Function(BearerAuth value) bearer,
    required TResult Function(BasicAuth value) basic,
    required TResult Function(ApiKeyAuth value) apiKey,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this AuthConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthConfigCopyWith<$Res> {
  factory $AuthConfigCopyWith(
    AuthConfig value,
    $Res Function(AuthConfig) then,
  ) = _$AuthConfigCopyWithImpl<$Res, AuthConfig>;
}

/// @nodoc
class _$AuthConfigCopyWithImpl<$Res, $Val extends AuthConfig>
    implements $AuthConfigCopyWith<$Res> {
  _$AuthConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NoAuthImplCopyWith<$Res> {
  factory _$$NoAuthImplCopyWith(
    _$NoAuthImpl value,
    $Res Function(_$NoAuthImpl) then,
  ) = __$$NoAuthImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NoAuthImplCopyWithImpl<$Res>
    extends _$AuthConfigCopyWithImpl<$Res, _$NoAuthImpl>
    implements _$$NoAuthImplCopyWith<$Res> {
  __$$NoAuthImplCopyWithImpl(
    _$NoAuthImpl _value,
    $Res Function(_$NoAuthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$NoAuthImpl implements NoAuth {
  const _$NoAuthImpl({final String? $type}) : $type = $type ?? 'none';

  factory _$NoAuthImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoAuthImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'AuthConfig.none()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NoAuthImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String token) bearer,
    required TResult Function(String username, String password) basic,
    required TResult Function(String key, String value, ApiKeyAddTo addTo)
    apiKey,
  }) {
    return none();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
  }) {
    return none?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoAuth value) none,
    required TResult Function(BearerAuth value) bearer,
    required TResult Function(BasicAuth value) basic,
    required TResult Function(ApiKeyAuth value) apiKey,
  }) {
    return none(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
  }) {
    return none?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$NoAuthImplToJson(this);
  }
}

abstract class NoAuth implements AuthConfig {
  const factory NoAuth() = _$NoAuthImpl;

  factory NoAuth.fromJson(Map<String, dynamic> json) = _$NoAuthImpl.fromJson;
}

/// @nodoc
abstract class _$$BearerAuthImplCopyWith<$Res> {
  factory _$$BearerAuthImplCopyWith(
    _$BearerAuthImpl value,
    $Res Function(_$BearerAuthImpl) then,
  ) = __$$BearerAuthImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String token});
}

/// @nodoc
class __$$BearerAuthImplCopyWithImpl<$Res>
    extends _$AuthConfigCopyWithImpl<$Res, _$BearerAuthImpl>
    implements _$$BearerAuthImplCopyWith<$Res> {
  __$$BearerAuthImplCopyWithImpl(
    _$BearerAuthImpl _value,
    $Res Function(_$BearerAuthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? token = null}) {
    return _then(
      _$BearerAuthImpl(
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BearerAuthImpl implements BearerAuth {
  const _$BearerAuthImpl({this.token = '', final String? $type})
    : $type = $type ?? 'bearer';

  factory _$BearerAuthImpl.fromJson(Map<String, dynamic> json) =>
      _$$BearerAuthImplFromJson(json);

  @override
  @JsonKey()
  final String token;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'AuthConfig.bearer(token: $token)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BearerAuthImpl &&
            (identical(other.token, token) || other.token == token));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, token);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BearerAuthImplCopyWith<_$BearerAuthImpl> get copyWith =>
      __$$BearerAuthImplCopyWithImpl<_$BearerAuthImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String token) bearer,
    required TResult Function(String username, String password) basic,
    required TResult Function(String key, String value, ApiKeyAddTo addTo)
    apiKey,
  }) {
    return bearer(token);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
  }) {
    return bearer?.call(token);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    required TResult orElse(),
  }) {
    if (bearer != null) {
      return bearer(token);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoAuth value) none,
    required TResult Function(BearerAuth value) bearer,
    required TResult Function(BasicAuth value) basic,
    required TResult Function(ApiKeyAuth value) apiKey,
  }) {
    return bearer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
  }) {
    return bearer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    required TResult orElse(),
  }) {
    if (bearer != null) {
      return bearer(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$BearerAuthImplToJson(this);
  }
}

abstract class BearerAuth implements AuthConfig {
  const factory BearerAuth({final String token}) = _$BearerAuthImpl;

  factory BearerAuth.fromJson(Map<String, dynamic> json) =
      _$BearerAuthImpl.fromJson;

  String get token;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BearerAuthImplCopyWith<_$BearerAuthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BasicAuthImplCopyWith<$Res> {
  factory _$$BasicAuthImplCopyWith(
    _$BasicAuthImpl value,
    $Res Function(_$BasicAuthImpl) then,
  ) = __$$BasicAuthImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String username, String password});
}

/// @nodoc
class __$$BasicAuthImplCopyWithImpl<$Res>
    extends _$AuthConfigCopyWithImpl<$Res, _$BasicAuthImpl>
    implements _$$BasicAuthImplCopyWith<$Res> {
  __$$BasicAuthImplCopyWithImpl(
    _$BasicAuthImpl _value,
    $Res Function(_$BasicAuthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? username = null, Object? password = null}) {
    return _then(
      _$BasicAuthImpl(
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BasicAuthImpl implements BasicAuth {
  const _$BasicAuthImpl({
    this.username = '',
    this.password = '',
    final String? $type,
  }) : $type = $type ?? 'basic';

  factory _$BasicAuthImpl.fromJson(Map<String, dynamic> json) =>
      _$$BasicAuthImplFromJson(json);

  @override
  @JsonKey()
  final String username;
  @override
  @JsonKey()
  final String password;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'AuthConfig.basic(username: $username, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BasicAuthImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, username, password);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BasicAuthImplCopyWith<_$BasicAuthImpl> get copyWith =>
      __$$BasicAuthImplCopyWithImpl<_$BasicAuthImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String token) bearer,
    required TResult Function(String username, String password) basic,
    required TResult Function(String key, String value, ApiKeyAddTo addTo)
    apiKey,
  }) {
    return basic(username, password);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
  }) {
    return basic?.call(username, password);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    required TResult orElse(),
  }) {
    if (basic != null) {
      return basic(username, password);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoAuth value) none,
    required TResult Function(BearerAuth value) bearer,
    required TResult Function(BasicAuth value) basic,
    required TResult Function(ApiKeyAuth value) apiKey,
  }) {
    return basic(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
  }) {
    return basic?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    required TResult orElse(),
  }) {
    if (basic != null) {
      return basic(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$BasicAuthImplToJson(this);
  }
}

abstract class BasicAuth implements AuthConfig {
  const factory BasicAuth({final String username, final String password}) =
      _$BasicAuthImpl;

  factory BasicAuth.fromJson(Map<String, dynamic> json) =
      _$BasicAuthImpl.fromJson;

  String get username;
  String get password;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BasicAuthImplCopyWith<_$BasicAuthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ApiKeyAuthImplCopyWith<$Res> {
  factory _$$ApiKeyAuthImplCopyWith(
    _$ApiKeyAuthImpl value,
    $Res Function(_$ApiKeyAuthImpl) then,
  ) = __$$ApiKeyAuthImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String key, String value, ApiKeyAddTo addTo});
}

/// @nodoc
class __$$ApiKeyAuthImplCopyWithImpl<$Res>
    extends _$AuthConfigCopyWithImpl<$Res, _$ApiKeyAuthImpl>
    implements _$$ApiKeyAuthImplCopyWith<$Res> {
  __$$ApiKeyAuthImplCopyWithImpl(
    _$ApiKeyAuthImpl _value,
    $Res Function(_$ApiKeyAuthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? key = null, Object? value = null, Object? addTo = null}) {
    return _then(
      _$ApiKeyAuthImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        addTo: null == addTo
            ? _value.addTo
            : addTo // ignore: cast_nullable_to_non_nullable
                  as ApiKeyAddTo,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiKeyAuthImpl implements ApiKeyAuth {
  const _$ApiKeyAuthImpl({
    this.key = '',
    this.value = '',
    this.addTo = ApiKeyAddTo.header,
    final String? $type,
  }) : $type = $type ?? 'apiKey';

  factory _$ApiKeyAuthImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiKeyAuthImplFromJson(json);

  @override
  @JsonKey()
  final String key;
  @override
  @JsonKey()
  final String value;
  @override
  @JsonKey()
  final ApiKeyAddTo addTo;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'AuthConfig.apiKey(key: $key, value: $value, addTo: $addTo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiKeyAuthImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.addTo, addTo) || other.addTo == addTo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, key, value, addTo);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiKeyAuthImplCopyWith<_$ApiKeyAuthImpl> get copyWith =>
      __$$ApiKeyAuthImplCopyWithImpl<_$ApiKeyAuthImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String token) bearer,
    required TResult Function(String username, String password) basic,
    required TResult Function(String key, String value, ApiKeyAddTo addTo)
    apiKey,
  }) {
    return apiKey(key, value, addTo);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
  }) {
    return apiKey?.call(key, value, addTo);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    required TResult orElse(),
  }) {
    if (apiKey != null) {
      return apiKey(key, value, addTo);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoAuth value) none,
    required TResult Function(BearerAuth value) bearer,
    required TResult Function(BasicAuth value) basic,
    required TResult Function(ApiKeyAuth value) apiKey,
  }) {
    return apiKey(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
  }) {
    return apiKey?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    required TResult orElse(),
  }) {
    if (apiKey != null) {
      return apiKey(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiKeyAuthImplToJson(this);
  }
}

abstract class ApiKeyAuth implements AuthConfig {
  const factory ApiKeyAuth({
    final String key,
    final String value,
    final ApiKeyAddTo addTo,
  }) = _$ApiKeyAuthImpl;

  factory ApiKeyAuth.fromJson(Map<String, dynamic> json) =
      _$ApiKeyAuthImpl.fromJson;

  String get key;
  String get value;
  ApiKeyAddTo get addTo;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiKeyAuthImplCopyWith<_$ApiKeyAuthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
