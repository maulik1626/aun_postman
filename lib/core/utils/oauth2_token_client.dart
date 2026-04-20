import 'package:aun_reqstudio/domain/enums/auth_type.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:dio/dio.dart';

/// Fetches OAuth 2.0 access tokens (client credentials or password grant).
class OAuth2TokenClient {
  OAuth2TokenClient._();

  /// POSTs `application/x-www-form-urlencoded` to [auth.tokenUrl].
  static Future<OAuth2Auth> fetchAndMerge(OAuth2Auth auth) async {
    final url = auth.tokenUrl.trim();
    if (url.isEmpty) {
      throw StateError('Token URL is required');
    }
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (s) => s != null && s < 500,
        headers: {Headers.acceptHeader: 'application/json'},
      ),
    );

    final body = <String, dynamic>{
      'grant_type': auth.grantType.wireValue,
      'client_id': auth.clientId,
      'client_secret': auth.clientSecret,
      if (auth.scope.trim().isNotEmpty) 'scope': auth.scope.trim(),
      if (auth.grantType == OAuth2GrantType.password) ...{
        'username': auth.username,
        'password': auth.password,
      },
    };

    final response = await dio.post<Map<String, dynamic>>(
      url,
      data: body,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final data = response.data;
    if (response.statusCode != 200 || data == null) {
      final msg = data?['error_description'] as String? ??
          data?['error'] as String? ??
          response.statusMessage ??
          'Token request failed (${response.statusCode})';
      throw StateError(msg);
    }

    final access = data['access_token'] as String? ?? '';
    if (access.isEmpty) {
      throw StateError('Token response missing access_token');
    }
    final refresh = data['refresh_token'] as String? ?? '';
    final tType = data['token_type'] as String? ?? 'Bearer';
    int? expiresAt;
    final expIn = data['expires_in'];
    if (expIn is int) {
      expiresAt = DateTime.now().toUtc().add(Duration(seconds: expIn)).millisecondsSinceEpoch ~/ 1000;
    } else if (expIn is num) {
      expiresAt = DateTime.now()
          .toUtc()
          .add(Duration(seconds: expIn.toInt()))
          .millisecondsSinceEpoch ~/
          1000;
    }

    return auth.copyWith(
      accessToken: access,
      refreshToken: refresh.isNotEmpty ? refresh : auth.refreshToken,
      tokenType: tType,
      expiresAtSecs: expiresAt,
    );
  }

  /// True when [accessToken] is empty but enough fields exist to request one.
  static bool canAutoFetch(OAuth2Auth auth) {
    if (auth.accessToken.trim().isNotEmpty) return false;
    if (auth.tokenUrl.trim().isEmpty) return false;
    if (auth.clientId.trim().isEmpty) return false;
    if (auth.grantType == OAuth2GrantType.password) {
      if (auth.username.trim().isEmpty || auth.password.isEmpty) return false;
    }
    return true;
  }

  /// Before Send: fetch when there is no token, or refresh when [isExpired].
  static bool shouldFetch(OAuth2Auth auth) {
    if (auth.tokenUrl.trim().isEmpty || auth.clientId.trim().isEmpty) {
      return false;
    }
    if (auth.grantType == OAuth2GrantType.password) {
      if (auth.username.trim().isEmpty) return false;
    }
    if (auth.accessToken.trim().isEmpty) return true;
    return isExpired(auth);
  }

  /// True if [expiresAtSecs] is in the past (or within [skewSeconds]).
  static bool isExpired(OAuth2Auth auth, {int skewSeconds = 60}) {
    final exp = auth.expiresAtSecs;
    if (exp == null) return false;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return now >= exp - skewSeconds;
  }
}
