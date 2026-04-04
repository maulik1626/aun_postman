import 'dart:convert';

import 'package:aun_postman/domain/enums/auth_type.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:dio/dio.dart';

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
    }
    handler.next(options);
  }
}
