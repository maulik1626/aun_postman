import 'package:aun_postman/core/utils/aws_sigv4_signer.dart';
import 'package:aun_postman/domain/enums/auth_type.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._auth);
  final AuthConfig _auth;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    switch (_auth) {
      case NoAuth():
        break;
      case BearerAuth(:final token):
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      case BasicAuth(:final username, :final password):
        if (username.isNotEmpty) {
          final credentials = base64Encode(
            utf8.encode('$username:$password'),
          );
          options.headers['Authorization'] = 'Basic $credentials';
        }
      case ApiKeyAuth(:final key, :final value, :final addTo):
        if (key.isNotEmpty) {
          if (addTo == ApiKeyAddTo.header) {
            options.headers[key] = value;
          } else {
            options.queryParameters[key] = value;
          }
        }
      case OAuth2Auth(:final accessToken, :final tokenType):
        if (accessToken.isNotEmpty) {
          final prefix =
              tokenType.trim().isEmpty ? 'Bearer' : tokenType.trim();
          options.headers['Authorization'] = '$prefix $accessToken';
        }
      case DigestAuth():
        break;
      case AwsSigV4Auth(
          :final accessKeyId,
          :final secretAccessKey,
          :final sessionToken,
          :final region,
          :final service,
        ):
        try {
          AwsSigV4Signer.apply(
            options,
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            region: region.trim().isEmpty ? 'us-east-1' : region.trim(),
            service: service.trim().isEmpty ? 'execute-api' : service.trim(),
            sessionToken: sessionToken,
          );
        } on UnsupportedError catch (_) {
          // Leave unsigned; server will reject with a clear error.
        }
    }
    handler.next(options);
  }
}
