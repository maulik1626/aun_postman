import 'package:aun_postman/domain/models/auth_config.dart';

/// Request auth wins when set; otherwise collection default applies (Postman-style).
AuthConfig mergeRequestAndCollectionAuth(
  AuthConfig requestAuth,
  AuthConfig collectionAuth,
) {
  return switch (requestAuth) {
    NoAuth() => switch (collectionAuth) {
        NoAuth() => const NoAuth(),
        _ => collectionAuth,
      },
    _ => requestAuth,
  };
}
