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
    case 'oauth2':
      return OAuth2Auth.fromJson(json);
    case 'digest':
      return DigestAuth.fromJson(json);
    case 'awsSigV4':
      return AwsSigV4Auth.fromJson(json);

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
    required TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )
    oauth2,
    required TResult Function(String username, String password) digest,
    required TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )
    awsSigV4,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    TResult? Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult? Function(String username, String password)? digest,
    TResult? Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult Function(String username, String password)? digest,
    TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoAuth value) none,
    required TResult Function(BearerAuth value) bearer,
    required TResult Function(BasicAuth value) basic,
    required TResult Function(ApiKeyAuth value) apiKey,
    required TResult Function(OAuth2Auth value) oauth2,
    required TResult Function(DigestAuth value) digest,
    required TResult Function(AwsSigV4Auth value) awsSigV4,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
    TResult? Function(OAuth2Auth value)? oauth2,
    TResult? Function(DigestAuth value)? digest,
    TResult? Function(AwsSigV4Auth value)? awsSigV4,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    TResult Function(OAuth2Auth value)? oauth2,
    TResult Function(DigestAuth value)? digest,
    TResult Function(AwsSigV4Auth value)? awsSigV4,
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
    required TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )
    oauth2,
    required TResult Function(String username, String password) digest,
    required TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )
    awsSigV4,
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
    TResult? Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult? Function(String username, String password)? digest,
    TResult? Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
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
    TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult Function(String username, String password)? digest,
    TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
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
    required TResult Function(OAuth2Auth value) oauth2,
    required TResult Function(DigestAuth value) digest,
    required TResult Function(AwsSigV4Auth value) awsSigV4,
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
    TResult? Function(OAuth2Auth value)? oauth2,
    TResult? Function(DigestAuth value)? digest,
    TResult? Function(AwsSigV4Auth value)? awsSigV4,
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
    TResult Function(OAuth2Auth value)? oauth2,
    TResult Function(DigestAuth value)? digest,
    TResult Function(AwsSigV4Auth value)? awsSigV4,
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
    required TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )
    oauth2,
    required TResult Function(String username, String password) digest,
    required TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )
    awsSigV4,
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
    TResult? Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult? Function(String username, String password)? digest,
    TResult? Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
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
    TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult Function(String username, String password)? digest,
    TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
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
    required TResult Function(OAuth2Auth value) oauth2,
    required TResult Function(DigestAuth value) digest,
    required TResult Function(AwsSigV4Auth value) awsSigV4,
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
    TResult? Function(OAuth2Auth value)? oauth2,
    TResult? Function(DigestAuth value)? digest,
    TResult? Function(AwsSigV4Auth value)? awsSigV4,
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
    TResult Function(OAuth2Auth value)? oauth2,
    TResult Function(DigestAuth value)? digest,
    TResult Function(AwsSigV4Auth value)? awsSigV4,
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
    required TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )
    oauth2,
    required TResult Function(String username, String password) digest,
    required TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )
    awsSigV4,
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
    TResult? Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult? Function(String username, String password)? digest,
    TResult? Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
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
    TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult Function(String username, String password)? digest,
    TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
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
    required TResult Function(OAuth2Auth value) oauth2,
    required TResult Function(DigestAuth value) digest,
    required TResult Function(AwsSigV4Auth value) awsSigV4,
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
    TResult? Function(OAuth2Auth value)? oauth2,
    TResult? Function(DigestAuth value)? digest,
    TResult? Function(AwsSigV4Auth value)? awsSigV4,
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
    TResult Function(OAuth2Auth value)? oauth2,
    TResult Function(DigestAuth value)? digest,
    TResult Function(AwsSigV4Auth value)? awsSigV4,
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
    required TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )
    oauth2,
    required TResult Function(String username, String password) digest,
    required TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )
    awsSigV4,
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
    TResult? Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult? Function(String username, String password)? digest,
    TResult? Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
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
    TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult Function(String username, String password)? digest,
    TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
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
    required TResult Function(OAuth2Auth value) oauth2,
    required TResult Function(DigestAuth value) digest,
    required TResult Function(AwsSigV4Auth value) awsSigV4,
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
    TResult? Function(OAuth2Auth value)? oauth2,
    TResult? Function(DigestAuth value)? digest,
    TResult? Function(AwsSigV4Auth value)? awsSigV4,
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
    TResult Function(OAuth2Auth value)? oauth2,
    TResult Function(DigestAuth value)? digest,
    TResult Function(AwsSigV4Auth value)? awsSigV4,
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

/// @nodoc
abstract class _$$OAuth2AuthImplCopyWith<$Res> {
  factory _$$OAuth2AuthImplCopyWith(
    _$OAuth2AuthImpl value,
    $Res Function(_$OAuth2AuthImpl) then,
  ) = __$$OAuth2AuthImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String accessToken,
    String refreshToken,
    String tokenType,
    int? expiresAtSecs,
    String tokenUrl,
    String clientId,
    String clientSecret,
    String scope,
    String username,
    String password,
    OAuth2GrantType grantType,
  });
}

/// @nodoc
class __$$OAuth2AuthImplCopyWithImpl<$Res>
    extends _$AuthConfigCopyWithImpl<$Res, _$OAuth2AuthImpl>
    implements _$$OAuth2AuthImplCopyWith<$Res> {
  __$$OAuth2AuthImplCopyWithImpl(
    _$OAuth2AuthImpl _value,
    $Res Function(_$OAuth2AuthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? tokenType = null,
    Object? expiresAtSecs = freezed,
    Object? tokenUrl = null,
    Object? clientId = null,
    Object? clientSecret = null,
    Object? scope = null,
    Object? username = null,
    Object? password = null,
    Object? grantType = null,
  }) {
    return _then(
      _$OAuth2AuthImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        refreshToken: null == refreshToken
            ? _value.refreshToken
            : refreshToken // ignore: cast_nullable_to_non_nullable
                  as String,
        tokenType: null == tokenType
            ? _value.tokenType
            : tokenType // ignore: cast_nullable_to_non_nullable
                  as String,
        expiresAtSecs: freezed == expiresAtSecs
            ? _value.expiresAtSecs
            : expiresAtSecs // ignore: cast_nullable_to_non_nullable
                  as int?,
        tokenUrl: null == tokenUrl
            ? _value.tokenUrl
            : tokenUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        clientSecret: null == clientSecret
            ? _value.clientSecret
            : clientSecret // ignore: cast_nullable_to_non_nullable
                  as String,
        scope: null == scope
            ? _value.scope
            : scope // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        grantType: null == grantType
            ? _value.grantType
            : grantType // ignore: cast_nullable_to_non_nullable
                  as OAuth2GrantType,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OAuth2AuthImpl implements OAuth2Auth {
  const _$OAuth2AuthImpl({
    this.accessToken = '',
    this.refreshToken = '',
    this.tokenType = 'Bearer',
    this.expiresAtSecs,
    this.tokenUrl = '',
    this.clientId = '',
    this.clientSecret = '',
    this.scope = '',
    this.username = '',
    this.password = '',
    this.grantType = OAuth2GrantType.clientCredentials,
    final String? $type,
  }) : $type = $type ?? 'oauth2';

  factory _$OAuth2AuthImpl.fromJson(Map<String, dynamic> json) =>
      _$$OAuth2AuthImplFromJson(json);

  @override
  @JsonKey()
  final String accessToken;
  @override
  @JsonKey()
  final String refreshToken;
  @override
  @JsonKey()
  final String tokenType;
  @override
  final int? expiresAtSecs;
  @override
  @JsonKey()
  final String tokenUrl;
  @override
  @JsonKey()
  final String clientId;
  @override
  @JsonKey()
  final String clientSecret;
  @override
  @JsonKey()
  final String scope;
  @override
  @JsonKey()
  final String username;
  @override
  @JsonKey()
  final String password;
  @override
  @JsonKey()
  final OAuth2GrantType grantType;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'AuthConfig.oauth2(accessToken: $accessToken, refreshToken: $refreshToken, tokenType: $tokenType, expiresAtSecs: $expiresAtSecs, tokenUrl: $tokenUrl, clientId: $clientId, clientSecret: $clientSecret, scope: $scope, username: $username, password: $password, grantType: $grantType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OAuth2AuthImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.tokenType, tokenType) ||
                other.tokenType == tokenType) &&
            (identical(other.expiresAtSecs, expiresAtSecs) ||
                other.expiresAtSecs == expiresAtSecs) &&
            (identical(other.tokenUrl, tokenUrl) ||
                other.tokenUrl == tokenUrl) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.clientSecret, clientSecret) ||
                other.clientSecret == clientSecret) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.grantType, grantType) ||
                other.grantType == grantType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    accessToken,
    refreshToken,
    tokenType,
    expiresAtSecs,
    tokenUrl,
    clientId,
    clientSecret,
    scope,
    username,
    password,
    grantType,
  );

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OAuth2AuthImplCopyWith<_$OAuth2AuthImpl> get copyWith =>
      __$$OAuth2AuthImplCopyWithImpl<_$OAuth2AuthImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String token) bearer,
    required TResult Function(String username, String password) basic,
    required TResult Function(String key, String value, ApiKeyAddTo addTo)
    apiKey,
    required TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )
    oauth2,
    required TResult Function(String username, String password) digest,
    required TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )
    awsSigV4,
  }) {
    return oauth2(
      accessToken,
      refreshToken,
      tokenType,
      expiresAtSecs,
      tokenUrl,
      clientId,
      clientSecret,
      scope,
      username,
      password,
      grantType,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    TResult? Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult? Function(String username, String password)? digest,
    TResult? Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
  }) {
    return oauth2?.call(
      accessToken,
      refreshToken,
      tokenType,
      expiresAtSecs,
      tokenUrl,
      clientId,
      clientSecret,
      scope,
      username,
      password,
      grantType,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult Function(String username, String password)? digest,
    TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
    required TResult orElse(),
  }) {
    if (oauth2 != null) {
      return oauth2(
        accessToken,
        refreshToken,
        tokenType,
        expiresAtSecs,
        tokenUrl,
        clientId,
        clientSecret,
        scope,
        username,
        password,
        grantType,
      );
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
    required TResult Function(OAuth2Auth value) oauth2,
    required TResult Function(DigestAuth value) digest,
    required TResult Function(AwsSigV4Auth value) awsSigV4,
  }) {
    return oauth2(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
    TResult? Function(OAuth2Auth value)? oauth2,
    TResult? Function(DigestAuth value)? digest,
    TResult? Function(AwsSigV4Auth value)? awsSigV4,
  }) {
    return oauth2?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    TResult Function(OAuth2Auth value)? oauth2,
    TResult Function(DigestAuth value)? digest,
    TResult Function(AwsSigV4Auth value)? awsSigV4,
    required TResult orElse(),
  }) {
    if (oauth2 != null) {
      return oauth2(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$OAuth2AuthImplToJson(this);
  }
}

abstract class OAuth2Auth implements AuthConfig {
  const factory OAuth2Auth({
    final String accessToken,
    final String refreshToken,
    final String tokenType,
    final int? expiresAtSecs,
    final String tokenUrl,
    final String clientId,
    final String clientSecret,
    final String scope,
    final String username,
    final String password,
    final OAuth2GrantType grantType,
  }) = _$OAuth2AuthImpl;

  factory OAuth2Auth.fromJson(Map<String, dynamic> json) =
      _$OAuth2AuthImpl.fromJson;

  String get accessToken;
  String get refreshToken;
  String get tokenType;
  int? get expiresAtSecs;
  String get tokenUrl;
  String get clientId;
  String get clientSecret;
  String get scope;
  String get username;
  String get password;
  OAuth2GrantType get grantType;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OAuth2AuthImplCopyWith<_$OAuth2AuthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DigestAuthImplCopyWith<$Res> {
  factory _$$DigestAuthImplCopyWith(
    _$DigestAuthImpl value,
    $Res Function(_$DigestAuthImpl) then,
  ) = __$$DigestAuthImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String username, String password});
}

/// @nodoc
class __$$DigestAuthImplCopyWithImpl<$Res>
    extends _$AuthConfigCopyWithImpl<$Res, _$DigestAuthImpl>
    implements _$$DigestAuthImplCopyWith<$Res> {
  __$$DigestAuthImplCopyWithImpl(
    _$DigestAuthImpl _value,
    $Res Function(_$DigestAuthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? username = null, Object? password = null}) {
    return _then(
      _$DigestAuthImpl(
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
class _$DigestAuthImpl implements DigestAuth {
  const _$DigestAuthImpl({
    this.username = '',
    this.password = '',
    final String? $type,
  }) : $type = $type ?? 'digest';

  factory _$DigestAuthImpl.fromJson(Map<String, dynamic> json) =>
      _$$DigestAuthImplFromJson(json);

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
    return 'AuthConfig.digest(username: $username, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DigestAuthImpl &&
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
  _$$DigestAuthImplCopyWith<_$DigestAuthImpl> get copyWith =>
      __$$DigestAuthImplCopyWithImpl<_$DigestAuthImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String token) bearer,
    required TResult Function(String username, String password) basic,
    required TResult Function(String key, String value, ApiKeyAddTo addTo)
    apiKey,
    required TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )
    oauth2,
    required TResult Function(String username, String password) digest,
    required TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )
    awsSigV4,
  }) {
    return digest(username, password);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    TResult? Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult? Function(String username, String password)? digest,
    TResult? Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
  }) {
    return digest?.call(username, password);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult Function(String username, String password)? digest,
    TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
    required TResult orElse(),
  }) {
    if (digest != null) {
      return digest(username, password);
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
    required TResult Function(OAuth2Auth value) oauth2,
    required TResult Function(DigestAuth value) digest,
    required TResult Function(AwsSigV4Auth value) awsSigV4,
  }) {
    return digest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
    TResult? Function(OAuth2Auth value)? oauth2,
    TResult? Function(DigestAuth value)? digest,
    TResult? Function(AwsSigV4Auth value)? awsSigV4,
  }) {
    return digest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    TResult Function(OAuth2Auth value)? oauth2,
    TResult Function(DigestAuth value)? digest,
    TResult Function(AwsSigV4Auth value)? awsSigV4,
    required TResult orElse(),
  }) {
    if (digest != null) {
      return digest(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DigestAuthImplToJson(this);
  }
}

abstract class DigestAuth implements AuthConfig {
  const factory DigestAuth({final String username, final String password}) =
      _$DigestAuthImpl;

  factory DigestAuth.fromJson(Map<String, dynamic> json) =
      _$DigestAuthImpl.fromJson;

  String get username;
  String get password;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DigestAuthImplCopyWith<_$DigestAuthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AwsSigV4AuthImplCopyWith<$Res> {
  factory _$$AwsSigV4AuthImplCopyWith(
    _$AwsSigV4AuthImpl value,
    $Res Function(_$AwsSigV4AuthImpl) then,
  ) = __$$AwsSigV4AuthImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String accessKeyId,
    String secretAccessKey,
    String sessionToken,
    String region,
    String service,
  });
}

/// @nodoc
class __$$AwsSigV4AuthImplCopyWithImpl<$Res>
    extends _$AuthConfigCopyWithImpl<$Res, _$AwsSigV4AuthImpl>
    implements _$$AwsSigV4AuthImplCopyWith<$Res> {
  __$$AwsSigV4AuthImplCopyWithImpl(
    _$AwsSigV4AuthImpl _value,
    $Res Function(_$AwsSigV4AuthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessKeyId = null,
    Object? secretAccessKey = null,
    Object? sessionToken = null,
    Object? region = null,
    Object? service = null,
  }) {
    return _then(
      _$AwsSigV4AuthImpl(
        accessKeyId: null == accessKeyId
            ? _value.accessKeyId
            : accessKeyId // ignore: cast_nullable_to_non_nullable
                  as String,
        secretAccessKey: null == secretAccessKey
            ? _value.secretAccessKey
            : secretAccessKey // ignore: cast_nullable_to_non_nullable
                  as String,
        sessionToken: null == sessionToken
            ? _value.sessionToken
            : sessionToken // ignore: cast_nullable_to_non_nullable
                  as String,
        region: null == region
            ? _value.region
            : region // ignore: cast_nullable_to_non_nullable
                  as String,
        service: null == service
            ? _value.service
            : service // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AwsSigV4AuthImpl implements AwsSigV4Auth {
  const _$AwsSigV4AuthImpl({
    this.accessKeyId = '',
    this.secretAccessKey = '',
    this.sessionToken = '',
    this.region = 'us-east-1',
    this.service = 'execute-api',
    final String? $type,
  }) : $type = $type ?? 'awsSigV4';

  factory _$AwsSigV4AuthImpl.fromJson(Map<String, dynamic> json) =>
      _$$AwsSigV4AuthImplFromJson(json);

  @override
  @JsonKey()
  final String accessKeyId;
  @override
  @JsonKey()
  final String secretAccessKey;
  @override
  @JsonKey()
  final String sessionToken;
  @override
  @JsonKey()
  final String region;
  @override
  @JsonKey()
  final String service;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'AuthConfig.awsSigV4(accessKeyId: $accessKeyId, secretAccessKey: $secretAccessKey, sessionToken: $sessionToken, region: $region, service: $service)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AwsSigV4AuthImpl &&
            (identical(other.accessKeyId, accessKeyId) ||
                other.accessKeyId == accessKeyId) &&
            (identical(other.secretAccessKey, secretAccessKey) ||
                other.secretAccessKey == secretAccessKey) &&
            (identical(other.sessionToken, sessionToken) ||
                other.sessionToken == sessionToken) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.service, service) || other.service == service));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    accessKeyId,
    secretAccessKey,
    sessionToken,
    region,
    service,
  );

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AwsSigV4AuthImplCopyWith<_$AwsSigV4AuthImpl> get copyWith =>
      __$$AwsSigV4AuthImplCopyWithImpl<_$AwsSigV4AuthImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String token) bearer,
    required TResult Function(String username, String password) basic,
    required TResult Function(String key, String value, ApiKeyAddTo addTo)
    apiKey,
    required TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )
    oauth2,
    required TResult Function(String username, String password) digest,
    required TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )
    awsSigV4,
  }) {
    return awsSigV4(
      accessKeyId,
      secretAccessKey,
      sessionToken,
      region,
      service,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String token)? bearer,
    TResult? Function(String username, String password)? basic,
    TResult? Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    TResult? Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult? Function(String username, String password)? digest,
    TResult? Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
  }) {
    return awsSigV4?.call(
      accessKeyId,
      secretAccessKey,
      sessionToken,
      region,
      service,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String token)? bearer,
    TResult Function(String username, String password)? basic,
    TResult Function(String key, String value, ApiKeyAddTo addTo)? apiKey,
    TResult Function(
      String accessToken,
      String refreshToken,
      String tokenType,
      int? expiresAtSecs,
      String tokenUrl,
      String clientId,
      String clientSecret,
      String scope,
      String username,
      String password,
      OAuth2GrantType grantType,
    )?
    oauth2,
    TResult Function(String username, String password)? digest,
    TResult Function(
      String accessKeyId,
      String secretAccessKey,
      String sessionToken,
      String region,
      String service,
    )?
    awsSigV4,
    required TResult orElse(),
  }) {
    if (awsSigV4 != null) {
      return awsSigV4(
        accessKeyId,
        secretAccessKey,
        sessionToken,
        region,
        service,
      );
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
    required TResult Function(OAuth2Auth value) oauth2,
    required TResult Function(DigestAuth value) digest,
    required TResult Function(AwsSigV4Auth value) awsSigV4,
  }) {
    return awsSigV4(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoAuth value)? none,
    TResult? Function(BearerAuth value)? bearer,
    TResult? Function(BasicAuth value)? basic,
    TResult? Function(ApiKeyAuth value)? apiKey,
    TResult? Function(OAuth2Auth value)? oauth2,
    TResult? Function(DigestAuth value)? digest,
    TResult? Function(AwsSigV4Auth value)? awsSigV4,
  }) {
    return awsSigV4?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoAuth value)? none,
    TResult Function(BearerAuth value)? bearer,
    TResult Function(BasicAuth value)? basic,
    TResult Function(ApiKeyAuth value)? apiKey,
    TResult Function(OAuth2Auth value)? oauth2,
    TResult Function(DigestAuth value)? digest,
    TResult Function(AwsSigV4Auth value)? awsSigV4,
    required TResult orElse(),
  }) {
    if (awsSigV4 != null) {
      return awsSigV4(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AwsSigV4AuthImplToJson(this);
  }
}

abstract class AwsSigV4Auth implements AuthConfig {
  const factory AwsSigV4Auth({
    final String accessKeyId,
    final String secretAccessKey,
    final String sessionToken,
    final String region,
    final String service,
  }) = _$AwsSigV4AuthImpl;

  factory AwsSigV4Auth.fromJson(Map<String, dynamic> json) =
      _$AwsSigV4AuthImpl.fromJson;

  String get accessKeyId;
  String get secretAccessKey;
  String get sessionToken;
  String get region;
  String get service;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AwsSigV4AuthImplCopyWith<_$AwsSigV4AuthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
