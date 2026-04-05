import 'package:aun_postman/core/utils/json_comment_stripper.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';

class CurlExporter {
  /// [defaultHeaders] are merged before [request.headers]; the request wins on same name.
  static String toCurl(
    HttpRequest request, {
    List<RequestHeader> defaultHeaders = const [],
  }) {
    final parts = <String>['curl'];
    parts.add("-X '${request.method.value}'");

    // URL with params
    var url = request.url;
    final enabledParams = request.params.where((p) => p.isEnabled).toList();
    if (enabledParams.isNotEmpty) {
      final query =
          enabledParams.map((p) => '${_enc(p.key)}=${_enc(p.value)}').join('&');
      url = url.contains('?') ? '$url&$query' : '$url?$query';
    }
    parts.add("'$url'");

    // Auth headers
    switch (request.auth) {
      case BearerAuth(:final token):
        parts.add("-H 'Authorization: Bearer $token'");
      case BasicAuth(:final username, :final password):
        parts.add("-u '$username:$password'");
      case ApiKeyAuth(:final key, :final value, :final addTo):
        if (addTo.name == 'header') {
          parts.add("-H '$key: $value'");
        }
      case OAuth2Auth(:final accessToken, :final tokenType):
        if (accessToken.isNotEmpty) {
          final p = tokenType.trim().isEmpty ? 'Bearer' : tokenType.trim();
          parts.add("-H 'Authorization: $p $accessToken'");
        }
      case DigestAuth(:final username, :final password):
        parts.add("-u '$username:$password'");
        parts.add(
            "# Note: use curl --digest for full RFC 7616 flow; above is a hint only");
      case AwsSigV4Auth():
        parts.add(
            "# AWS SigV4 signing is applied when sending in the app (not in plain cURL)");
      case NoAuth():
        break;
    }

    // Headers: app defaults first, then request (request overwrites same name).
    final merged = <String, String>{};
    for (final d in defaultHeaders.where((h) => h.isEnabled)) {
      final k = d.key.trim();
      if (k.isEmpty) continue;
      merged[k] = d.value;
    }
    for (final h in request.headers.where((h) => h.isEnabled)) {
      merged[h.key] = h.value;
    }
    for (final e in merged.entries) {
      parts.add(
          "-H '${e.key}: ${_escapeSingleQuoted(e.value)}'");
    }

    // Body
    switch (request.body) {
      case RawJsonBody(:final content):
        parts.add("-H 'Content-Type: application/json'");
        parts.add(
            "--data-raw '${_escapeSingleQuoted(stripJsonLineComments(content))}'");
      case RawXmlBody(:final content):
        parts.add("-H 'Content-Type: application/xml'");
        parts.add("--data-raw '${_escapeSingleQuoted(content)}'");
      case RawTextBody(:final content):
        parts.add("--data-raw '${_escapeSingleQuoted(content)}'");
      case RawHtmlBody(:final content):
        parts.add("-H 'Content-Type: text/html'");
        parts.add("--data-raw '${_escapeSingleQuoted(content)}'");
      case UrlEncodedBody(:final fields):
        final encoded =
            fields.where((f) => f.isEnabled).map((f) => '${_enc(f.key)}=${_enc(f.value)}').join('&');
        parts.add("-H 'Content-Type: application/x-www-form-urlencoded'");
        parts.add("--data-raw '$encoded'");
      case FormDataBody(:final fields):
        for (final f in fields.where((f) => f.isEnabled)) {
          if (f.isFile &&
              f.filePath != null &&
              f.filePath!.trim().isNotEmpty) {
            parts.add(
                "-F '${f.key}=@${_escapeSingleQuoted(f.filePath!.trim())}'");
          } else {
            parts.add(
                "-F '${f.key}=${_escapeSingleQuoted(f.value)}'");
          }
        }
      case BinaryBody(:final filePath):
        parts.add("--data-binary '@${_escapeSingleQuoted(filePath)}'");
      case NoBody():
        break;
    }

    return parts.join(' \\\n  ');
  }

  static String _enc(String s) => Uri.encodeQueryComponent(s);

  static String _escapeSingleQuoted(String s) =>
      s.replaceAll("'", r"'\''");
}
