import 'package:aun_reqstudio/domain/models/response_cookie.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'http_response.freezed.dart';
part 'http_response.g.dart';

@freezed
class HttpResponse with _$HttpResponse {
  const factory HttpResponse({
    required int statusCode,
    required String statusMessage,
    @Default({}) Map<String, String> headers,
    @Default('') String body,
    required int durationMs,
    required int sizeBytes,
    @Default([]) List<ResponseCookie> cookies,
    required DateTime receivedAt,
  }) = _HttpResponse;

  factory HttpResponse.fromJson(Map<String, dynamic> json) =>
      _$HttpResponseFromJson(json);
}
