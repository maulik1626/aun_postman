import 'package:aun_postman/domain/enums/auth_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_config.freezed.dart';
part 'auth_config.g.dart';

@freezed
sealed class AuthConfig with _$AuthConfig {
  const factory AuthConfig.none() = NoAuth;

  const factory AuthConfig.bearer({
    @Default('') String token,
  }) = BearerAuth;

  const factory AuthConfig.basic({
    @Default('') String username,
    @Default('') String password,
  }) = BasicAuth;

  const factory AuthConfig.apiKey({
    @Default('') String key,
    @Default('') String value,
    @Default(ApiKeyAddTo.header) ApiKeyAddTo addTo,
  }) = ApiKeyAuth;

  /// Client credentials or password grant; [accessToken] sent as Bearer after **Get token** or auto-fetch on Send.
  const factory AuthConfig.oauth2({
    @Default('') String accessToken,
    @Default('') String refreshToken,
    @Default('Bearer') String tokenType,
    int? expiresAtSecs,
    @Default('') String tokenUrl,
    @Default('') String clientId,
    @Default('') String clientSecret,
    @Default('') String scope,
    @Default('') String username,
    @Default('') String password,
    @Default(OAuth2GrantType.clientCredentials) OAuth2GrantType grantType,
  }) = OAuth2Auth;

  /// RFC 7616 HTTP Digest — first request unauthenticated; [DigestAuthInterceptor] retries after `WWW-Authenticate`.
  const factory AuthConfig.digest({
    @Default('') String username,
    @Default('') String password,
  }) = DigestAuth;

  /// AWS Signature Version 4 (e.g. API Gateway, IAM-authenticated REST). Best with JSON/text body; FormData may fail to sign.
  const factory AuthConfig.awsSigV4({
    @Default('') String accessKeyId,
    @Default('') String secretAccessKey,
    @Default('') String sessionToken,
    @Default('us-east-1') String region,
    @Default('execute-api') String service,
  }) = AwsSigV4Auth;

  factory AuthConfig.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigFromJson(json);
}
