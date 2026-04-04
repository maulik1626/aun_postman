import 'package:dio/dio.dart';

class TimingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['request_start_time'] =
        DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start =
        response.requestOptions.extra['request_start_time'] as int?;
    if (start != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - start;
      response.requestOptions.extra['duration_ms'] = elapsed;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final start = err.requestOptions.extra['request_start_time'] as int?;
    if (start != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - start;
      err.requestOptions.extra['duration_ms'] = elapsed;
    }
    handler.next(err);
  }
}
