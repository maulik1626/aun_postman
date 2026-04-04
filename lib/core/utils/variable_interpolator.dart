import 'dart:math';

import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/environment.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:uuid/uuid.dart';

class VariableInterpolator {
  static final RegExp _pattern = RegExp(r'\{\{([^}]+)\}\}');
  static final _random = Random();
  static const _uuid = Uuid();

  /// Resolves built-in dynamic variables (prefix `$`).
  static String? _resolveDynamic(String key) {
    switch (key) {
      case r'$timestamp':
        return DateTime.now().millisecondsSinceEpoch.toString();
      case r'$isoTimestamp':
        return DateTime.now().toUtc().toIso8601String();
      case r'$randomInt':
        return _random.nextInt(1000).toString();
      case r'$guid':
      case r'$uuid':
        return _uuid.v4();
      case r'$randomAlphaNumeric':
        const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
        return List.generate(
            10, (_) => chars[_random.nextInt(chars.length)]).join();
      case r'$randomBoolean':
        return _random.nextBool().toString();
      case r'$randomEmail':
        return '${_uuid.v4().substring(0, 8)}@example.com';
      default:
        return null;
    }
  }

  String interpolate(String input, Map<String, String> variables) {
    return input.replaceAllMapped(_pattern, (match) {
      final key = match.group(1)!.trim();
      // Dynamic built-in variables take precedence
      final dynamic = _resolveDynamic(key);
      if (dynamic != null) return dynamic;
      return variables[key] ?? match.group(0)!;
    });
  }

  /// Returns dynamic variable names for tooltip/autocomplete display.
  static const List<String> dynamicVariables = [
    r'$timestamp',
    r'$isoTimestamp',
    r'$randomInt',
    r'$guid',
    r'$uuid',
    r'$randomAlphaNumeric',
    r'$randomBoolean',
    r'$randomEmail',
  ];

  HttpRequest interpolateRequest(HttpRequest request, Environment? env) {
    // Dynamic variables resolve even without an active environment
    final vars = env?.variableMap ?? {};
    return request.copyWith(
      url: interpolate(request.url, vars),
      params: request.params
          .map(
            (p) => p.copyWith(
              key: interpolate(p.key, vars),
              value: interpolate(p.value, vars),
            ),
          )
          .toList(),
      headers: request.headers
          .map(
            (h) => h.copyWith(
              key: interpolate(h.key, vars),
              value: interpolate(h.value, vars),
            ),
          )
          .toList(),
      body: _interpolateBody(request.body, vars),
      auth: _interpolateAuth(request.auth, vars),
    );
  }

  RequestBody _interpolateBody(RequestBody body, Map<String, String> vars) {
    return switch (body) {
      NoBody() => body,
      RawJsonBody(:final content) =>
        RawJsonBody(content: interpolate(content, vars)),
      RawXmlBody(:final content) =>
        RawXmlBody(content: interpolate(content, vars)),
      RawTextBody(:final content) =>
        RawTextBody(content: interpolate(content, vars)),
      RawHtmlBody(:final content) =>
        RawHtmlBody(content: interpolate(content, vars)),
      FormDataBody(:final fields) => FormDataBody(
          fields: fields
              .map(
                (f) => f.copyWith(
                  key: interpolate(f.key, vars),
                  value: interpolate(f.value, vars),
                ),
              )
              .toList(),
        ),
      UrlEncodedBody(:final fields) => UrlEncodedBody(
          fields: fields
              .map(
                (f) => f.copyWith(
                  key: interpolate(f.key, vars),
                  value: interpolate(f.value, vars),
                ),
              )
              .toList(),
        ),
      BinaryBody() => body,
    };
  }

  AuthConfig _interpolateAuth(AuthConfig auth, Map<String, String> vars) {
    return switch (auth) {
      NoAuth() => auth,
      BearerAuth(:final token) =>
        BearerAuth(token: interpolate(token, vars)),
      BasicAuth(:final username, :final password) => BasicAuth(
          username: interpolate(username, vars),
          password: interpolate(password, vars),
        ),
      ApiKeyAuth(:final key, :final value, :final addTo) => ApiKeyAuth(
          key: interpolate(key, vars),
          value: interpolate(value, vars),
          addTo: addTo,
        ),
    };
  }
}
