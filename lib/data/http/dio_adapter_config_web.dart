import 'package:dio/dio.dart';

void configureDioAdapter(
  Dio dio, {
  required bool verifySsl,
  required String httpProxy,
}) {
  // Browser networking does not expose IO-level SSL/proxy hooks.
}
