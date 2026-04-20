import 'package:aun_reqstudio/domain/models/key_value_pair.dart';

/// Keeps the request URL query string and [RequestParam] rows in sync (Postman-style).
///
/// Uses a custom split of the raw query (not [Uri.queryParameters]) so duplicate keys
/// and order are preserved (`?a=1&a=2`).
class UrlQuerySync {
  UrlQuerySync._();

  /// Splits [url] into path/prefix (no `?` query), raw query without `?`, and `#fragment`.
  static ({String prefix, String rawQuery, String fragment}) splitUrlParts(
    String url,
  ) {
    var rest = url;
    var fragment = '';
    final hi = rest.indexOf('#');
    if (hi >= 0) {
      fragment = rest.substring(hi);
      rest = rest.substring(0, hi);
    }
    final qi = rest.indexOf('?');
    if (qi < 0) {
      return (prefix: rest, rawQuery: '', fragment: fragment);
    }
    return (
      prefix: rest.substring(0, qi),
      rawQuery: rest.substring(qi + 1),
      fragment: fragment,
    );
  }

  static String joinUrlParts({
    required String prefix,
    required String rawQuery,
    required String fragment,
  }) {
    if (rawQuery.isEmpty) return '$prefix$fragment';
    return '$prefix?$rawQuery$fragment';
  }

  /// Ordered pairs from `application/x-www-form-urlencoded` query syntax.
  static List<RequestParam> parseRawQueryToRequestParams(String rawQuery) {
    if (rawQuery.isEmpty) return [];
    final out = <RequestParam>[];
    for (final segment in rawQuery.split('&')) {
      if (segment.isEmpty) continue;
      final eq = segment.indexOf('=');
      if (eq < 0) {
        out.add(
          RequestParam(
            key: Uri.decodeQueryComponent(segment),
            value: '',
          ),
        );
      } else {
        final keyPart = segment.substring(0, eq);
        final valuePart = segment.substring(eq + 1);
        out.add(
          RequestParam(
            key: Uri.decodeQueryComponent(keyPart),
            value: Uri.decodeQueryComponent(valuePart),
          ),
        );
      }
    }
    return out;
  }

  /// Enabled params only; skips rows where both key and value are empty.
  static String buildEncodedQuery(List<RequestParam> params) {
    final parts = <String>[];
    for (final p in params) {
      if (!p.isEnabled) continue;
      if (p.key.isEmpty && p.value.isEmpty) continue;
      parts.add(
        '${Uri.encodeQueryComponent(p.key)}=${Uri.encodeQueryComponent(p.value)}',
      );
    }
    return parts.join('&');
  }

  /// Final URL for HTTP: base from [url] without its query, query only from enabled [params].
  static String urlForHttpCall(String url, List<RequestParam> params) {
    final parts = splitUrlParts(url);
    final q = buildEncodedQuery(params);
    return joinUrlParts(
      prefix: parts.prefix,
      rawQuery: q,
      fragment: parts.fragment,
    );
  }

  /// Reconcile saved or imported [url] + [params] (legacy data may have only one side set).
  static ({String url, List<RequestParam> params}) canonicalizeUrlAndParams(
    String url,
    List<RequestParam> params,
  ) {
    final parts = splitUrlParts(url);
    if (params.isNotEmpty) {
      final q = buildEncodedQuery(params);
      return (
        url: joinUrlParts(
          prefix: parts.prefix,
          rawQuery: q,
          fragment: parts.fragment,
        ),
        params: params,
      );
    }
    if (parts.rawQuery.isNotEmpty) {
      final parsed = parseRawQueryToRequestParams(parts.rawQuery);
      return (url: url, params: parsed);
    }
    return (
      url: joinUrlParts(
        prefix: parts.prefix,
        rawQuery: '',
        fragment: parts.fragment,
      ),
      params: const [],
    );
  }
}
