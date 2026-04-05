import 'dart:convert';

import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/http_response.dart';
import 'package:aun_postman/domain/models/request_body.dart';

/// Minimal HAR 1.2 for a single HTTP exchange (Chrome-compatible subset).
class HarExporter {
  static String buildEntry({
    required HttpRequest request,
    required HttpResponse response,
    required DateTime startedAt,
  }) {
    final har = {
      'log': {
        'version': '1.2',
        'creator': {
          'name': 'Aun Postman',
          'version': '1.0.0',
        },
        'entries': [
          {
            'startedDateTime': startedAt.toUtc().toIso8601String(),
            'time': response.durationMs.toDouble(),
            'request': {
              'method': request.method.value,
              'url': request.url,
              'httpVersion': 'HTTP/1.1',
              'headers': [
                for (final h in request.headers.where((x) => x.isEnabled))
                  {'name': h.key, 'value': h.value},
              ],
              'queryString': [
                for (final p in request.params.where((x) => x.isEnabled))
                  {'name': p.key, 'value': p.value},
              ],
              if (_bodyText(request).isNotEmpty)
                'postData': {
                  'mimeType': _guessMime(request),
                  'text': _bodyText(request),
                },
            },
            'response': {
              'status': response.statusCode,
              'statusText': response.statusMessage,
              'httpVersion': 'HTTP/1.1',
              'headers': [
                for (final e in response.headers.entries)
                  {'name': e.key, 'value': e.value},
              ],
              'content': {
                'size': response.sizeBytes,
                'mimeType': response.headers['content-type'] ??
                    response.headers['Content-Type'] ??
                    'application/octet-stream',
                'text': response.body,
              },
            },
          },
        ],
      },
    };
    return const JsonEncoder.withIndent('  ').convert(har);
  }

  static String _bodyText(HttpRequest request) {
    return switch (request.body) {
      RawJsonBody(:final content) => content,
      RawXmlBody(:final content) => content,
      RawTextBody(:final content) => content,
      RawHtmlBody(:final content) => content,
      UrlEncodedBody(:final fields) => fields
          .where((f) => f.isEnabled)
          .map((f) => '${Uri.encodeQueryComponent(f.key)}=${Uri.encodeQueryComponent(f.value)}')
          .join('&'),
      _ => '',
    };
  }

  static String _guessMime(HttpRequest request) {
    return switch (request.body) {
      RawJsonBody() => 'application/json',
      RawXmlBody() => 'application/xml',
      RawHtmlBody() => 'text/html',
      UrlEncodedBody() =>
        'application/x-www-form-urlencoded',
      _ => 'text/plain',
    };
  }
}
