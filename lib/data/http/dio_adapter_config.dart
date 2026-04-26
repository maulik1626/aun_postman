import 'package:dio/dio.dart';

import 'dio_adapter_config_web.dart'
    if (dart.library.io) 'dio_adapter_config_io.dart'
    as impl;

void configureDioAdapter(
  Dio dio, {
  required bool verifySsl,
  required String httpProxy,
}) {
  impl.configureDioAdapter(dio, verifySsl: verifySsl, httpProxy: httpProxy);
}
