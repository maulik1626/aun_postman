import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureDioAdapter(
  Dio dio, {
  required bool verifySsl,
  required String httpProxy,
}) {
  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) {
    return;
  }

  final proxy = httpProxy.trim();
  adapter.createHttpClient = () {
    final client = HttpClient();
    if (!verifySsl) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    if (proxy.isNotEmpty) {
      client.findProxy = (_) {
        if (proxy.toUpperCase() == 'DIRECT') return 'DIRECT';
        if (proxy.contains('://')) {
          final u = Uri.parse(proxy);
          final h = u.host;
          final p = u.hasPort ? u.port : 8080;
          return 'PROXY $h:$p';
        }
        return 'PROXY $proxy';
      };
    }
    return client;
  };
}
