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

  factory AuthConfig.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigFromJson(json);
}
