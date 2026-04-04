import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/request_body.dart';

class CurlExporter {
  static String toCurl(HttpRequest request) {
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
      case NoAuth():
        break;
    }

    // Headers
    for (final h in request.headers.where((h) => h.isEnabled)) {
      parts.add("-H '${h.key}: ${h.value}'");
    }

    // Body
    switch (request.body) {
      case RawJsonBody(:final content):
        parts.add("-H 'Content-Type: application/json'");
        parts.add("--data-raw '${content.replaceAll("'", "\\'")}'");
      case RawXmlBody(:final content):
        parts.add("-H 'Content-Type: application/xml'");
        parts.add("--data-raw '${content.replaceAll("'", "\\'")}'");
      case RawTextBody(:final content):
        parts.add("--data-raw '${content.replaceAll("'", "\\'")}'");
      case RawHtmlBody(:final content):
        parts.add("-H 'Content-Type: text/html'");
        parts.add("--data-raw '${content.replaceAll("'", "\\'")}'");
      case UrlEncodedBody(:final fields):
        final encoded =
            fields.where((f) => f.isEnabled).map((f) => '${_enc(f.key)}=${_enc(f.value)}').join('&');
        parts.add("-H 'Content-Type: application/x-www-form-urlencoded'");
        parts.add("--data-raw '$encoded'");
      case FormDataBody(:final fields):
        parts.add("-H 'Content-Type: multipart/form-data'");
        for (final f in fields.where((f) => f.isEnabled)) {
          parts.add("-F '${f.key}=${f.value.replaceAll("'", "\\'")}'");
        }
      case BinaryBody(:final filePath):
        parts.add("--data-binary '@$filePath'");
      case NoBody():
        break;
    }

    return parts.join(' \\\n  ');
  }

  static String _enc(String s) => Uri.encodeQueryComponent(s);
}
