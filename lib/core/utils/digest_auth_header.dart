import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// RFC 7616 / 2617 HTTP Digest `Authorization` header value (without the `Digest ` prefix).
class DigestAuthHeader {
  DigestAuthHeader._();

  static final _paramRe = RegExp(r'(\w+)=("([^"]*)"|([^\s,]+))');

  /// Parses `WWW-Authenticate: Digest ...` parameters.
  static Map<String, String> parseParams(String wwwAuthenticate) {
    final lower = wwwAuthenticate.trim();
    final idx = lower.toLowerCase().indexOf('digest');
    if (idx < 0) return {};
    final rest = wwwAuthenticate.substring(idx + 'digest'.length).trim();
    final out = <String, String>{};
    for (final m in _paramRe.allMatches(rest)) {
      final key = m.group(1)!;
      final v = m.group(3) ?? m.group(4) ?? '';
      out[key] = v;
    }
    return out;
  }

  static String _md5(String s) => md5.convert(utf8.encode(s)).toString();

  /// [requestUriPathAndQuery] e.g. `/api/v1?x=1` from the request line.
  static String buildAuthorizationValue({
    required String method,
    required String requestUriPathAndQuery,
    required String username,
    required String password,
    required Map<String, String> challenge,
  }) {
    final realm = challenge['realm'] ?? '';
    final nonce = challenge['nonce'] ?? '';
    if (nonce.isEmpty) {
      throw StateError('Digest challenge missing nonce');
    }
    final qopRaw = (challenge['qop'] ?? '').toLowerCase();
    final qopList = qopRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final useQopAuth = qopList.contains('auth');
    final algorithm = (challenge['algorithm'] ?? 'MD5').toUpperCase();

    final ha1 = _md5('$username:$realm:$password');
    final ha2 = _md5('${method.toUpperCase()}:$requestUriPathAndQuery');

    late final String responseDigest;
    late final String nc;
    late final String cnonce;

    if (useQopAuth) {
      final rnd = Random.secure();
      final bytes = List<int>.generate(8, (_) => rnd.nextInt(256));
      cnonce = base64Url.encode(bytes).replaceAll('=', '');
      nc = '00000001';
      responseDigest = _md5('$ha1:$nonce:$nc:$cnonce:auth:$ha2');
    } else {
      cnonce = '';
      nc = '';
      responseDigest = _md5('$ha1:$nonce:$ha2');
    }

    final buf = StringBuffer('Digest username="${_esc(username)}", realm="${_esc(realm)}", nonce="${_esc(nonce)}", uri="${_esc(requestUriPathAndQuery)}", response="$responseDigest"');
    if (algorithm != 'MD5') {
      buf.write(', algorithm=$algorithm');
    }
    if (useQopAuth) {
      buf.write(', qop=auth, nc=$nc, cnonce="$cnonce"');
    }
    final opaque = challenge['opaque'];
    if (opaque != null && opaque.isNotEmpty) {
      buf.write(', opaque="${_esc(opaque)}"');
    }
    return buf.toString();
  }

  static String _esc(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}
