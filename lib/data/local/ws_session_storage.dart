import 'dart:convert';

import 'package:aun_postman/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WsSessionSnapshot {
  const WsSessionSnapshot({
    required this.url,
    required this.protocolsCsv,
    required this.headers,
  });

  final String url;
  final String protocolsCsv;
  final List<({String key, String value})> headers;
}

class WsSessionStorage {
  WsSessionStorage._();
  static const _storage = FlutterSecureStorage();

  static Future<void> save({
    required String url,
    required String protocolsCsv,
    required List<({String key, String value})> headers,
  }) async {
    final map = {
      'url': url,
      'protocols': protocolsCsv,
      'headers': [
        for (final h in headers) {'k': h.key, 'v': h.value},
      ],
    };
    await _storage.write(
      key: StorageKeys.wsSavedSession,
      value: jsonEncode(map),
    );
  }

  static Future<WsSessionSnapshot?> load() async {
    final raw = await _storage.read(key: StorageKeys.wsSavedSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final url = map['url'] as String? ?? '';
      final protocols = map['protocols'] as String? ?? '';
      final headerList = map['headers'] as List<dynamic>? ?? [];
      final headers = headerList
          .map((e) {
            final m = e as Map<String, dynamic>;
            return (
              key: m['k'] as String? ?? '',
              value: m['v'] as String? ?? '',
            );
          })
          .where((h) => h.key.isNotEmpty)
          .toList();
      if (url.isEmpty) return null;
      return WsSessionSnapshot(
        url: url,
        protocolsCsv: protocols,
        headers: headers,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: StorageKeys.wsSavedSession);
  }
}
