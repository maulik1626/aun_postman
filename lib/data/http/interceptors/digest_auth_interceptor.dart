import 'package:aun_reqstudio/core/utils/digest_auth_header.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:dio/dio.dart';

/// On 401 + `WWW-Authenticate: Digest`, retries once with a computed Digest header.
class DigestAuthInterceptor extends Interceptor {
  DigestAuthInterceptor(this._dio, this._auth);

  final Dio _dio;
  final DigestAuth _auth;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_auth.username.isEmpty) {
      handler.next(err);
      return;
    }
    if (err.type != DioExceptionType.badResponse ||
        err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    final www = err.response?.headers.value('www-authenticate') ??
        err.response?.headers.value('WWW-Authenticate');
    if (www == null || !www.toLowerCase().contains('digest')) {
      handler.next(err);
      return;
    }

    final opts = err.requestOptions;
    if (opts.extra['_digest_retried'] == true) {
      handler.next(err);
      return;
    }

    try {
      final challenge = DigestAuthHeader.parseParams(www);
      final uri = opts.uri;
      final pathQuery =
          uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      final digestValue = DigestAuthHeader.buildAuthorizationValue(
        method: opts.method,
        requestUriPathAndQuery: pathQuery.isEmpty ? '/' : pathQuery,
        username: _auth.username,
        password: _auth.password,
        challenge: challenge,
      );

      final headers = Map<String, dynamic>.from(opts.headers);
      headers['Authorization'] = digestValue;
      final extra = Map<String, dynamic>.from(opts.extra)
        ..['_digest_retried'] = true;
      final next = opts.copyWith(headers: headers, extra: extra);

      _dio.fetch<dynamic>(next).then(handler.resolve).catchError((Object _) {
        handler.next(err);
      });
    } catch (_) {
      handler.next(err);
    }
  }
}
