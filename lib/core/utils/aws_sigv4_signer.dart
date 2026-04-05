import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// AWS Signature Version 4 for a single HTTP request ([RequestOptions]).
class AwsSigV4Signer {
  AwsSigV4Signer._();

  static void apply(
    RequestOptions options, {
    required String accessKeyId,
    required String secretAccessKey,
    required String region,
    required String service,
    String sessionToken = '',
  }) {
    if (accessKeyId.isEmpty || secretAccessKey.isEmpty) return;

    final uri = options.uri;
    final method = options.method.toUpperCase();
    final now = DateTime.now().toUtc();
    final amzDate = _amzDate(now);
    final dateStamp = _dateStamp(now);

    final payloadHash = _hashPayload(options.data);

    final lower = <String, String>{};
    for (final e in options.headers.entries) {
      final k = e.key.toLowerCase();
      if (e.value != null) lower[k] = e.value.toString();
    }

    lower['host'] = _hostHeader(uri);
    lower['x-amz-date'] = amzDate;
    lower['x-amz-content-sha256'] = payloadHash;
    if (sessionToken.trim().isNotEmpty) {
      lower['x-amz-security-token'] = sessionToken.trim();
    }

    final signedNames = lower.keys
        .where((k) => k == 'host' || k.startsWith('x-amz-'))
        .toList()
      ..sort();

    final canonicalHeaders = signedNames
        .map((k) => '$k:${_trimHeader(lower[k]!)}\n')
        .join();

    final signedHeadersStr = signedNames.join(';');
    final canonicalUri = _canonicalUri(uri);
    final canonicalQuery = _canonicalQuery(uri);

    final canonicalRequest = '$method\n$canonicalUri\n$canonicalQuery\n'
        '$canonicalHeaders\n$signedHeadersStr\n$payloadHash';

    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final hashedCanon =
        sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign =
        'AWS4-HMAC-SHA256\n$amzDate\n$credentialScope\n$hashedCanon';

    final signingKey =
        _signingKey(secretAccessKey, dateStamp, region, service);
    final signature =
        Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    final auth =
        'AWS4-HMAC-SHA256 Credential=$accessKeyId/$credentialScope, '
        'SignedHeaders=$signedHeadersStr, Signature=$signature';

    options.headers['Authorization'] = auth;
    for (final k in signedNames) {
      options.headers[k] = lower[k]!;
    }
  }

  static String _hostHeader(Uri uri) {
    if (!uri.hasPort) return uri.host;
    final def = uri.scheme == 'https' ? 443 : 80;
    return uri.port == def ? uri.host : '${uri.host}:${uri.port}';
  }

  static String _amzDate(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final mo = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final mi = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '${y}${mo}${d}T${h}${mi}${s}Z';
  }

  static String _dateStamp(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final mo = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y$mo$d';
  }

  static String _canonicalUri(Uri uri) {
    if (uri.path.isEmpty || uri.path == '/') return '/';
    final enc = uri.pathSegments.map(_encodeSegment).join('/');
    return '/$enc';
  }

  static String _encodeSegment(String s) {
    return Uri.encodeComponent(s).replaceAll('+', '%20');
  }

  static String _canonicalQuery(Uri uri) {
    if (!uri.hasQuery) return '';
    final pairs = <List<String>>[];
    uri.queryParametersAll.forEach((k, values) {
      for (final v in values) {
        pairs.add([_encodeRfc3986(k), _encodeRfc3986(v)]);
      }
    });
    pairs.sort((a, b) {
      final c = a[0].compareTo(b[0]);
      if (c != 0) return c;
      return a[1].compareTo(b[1]);
    });
    return pairs.map((p) => '${p[0]}=${p[1]}').join('&');
  }

  static String _encodeRfc3986(String s) {
    return Uri.encodeQueryComponent(s)
        .replaceAll('+', '%20')
        .replaceAll('%7E', '~');
  }

  static String _trimHeader(String v) {
    return v.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _hashPayload(Object? data) {
    if (data == null) {
      return sha256.convert(<int>[]).toString();
    }
    if (data is String) {
      return sha256.convert(utf8.encode(data)).toString();
    }
    if (data is List<int>) {
      return sha256.convert(data).toString();
    }
    throw UnsupportedError(
      'AWS SigV4: use a raw JSON/text body for signing (got ${data.runtimeType}).',
    );
  }

  static List<int> _signingKey(
    String secret,
    String dateStamp,
    String region,
    String service,
  ) {
    List<int> k = utf8.encode('AWS4$secret');
    k = Hmac(sha256, k).convert(utf8.encode(dateStamp)).bytes;
    k = Hmac(sha256, k).convert(utf8.encode(region)).bytes;
    k = Hmac(sha256, k).convert(utf8.encode(service)).bytes;
    return Hmac(sha256, k).convert(utf8.encode('aws4_request')).bytes;
  }
}
