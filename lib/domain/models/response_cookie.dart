import 'package:freezed_annotation/freezed_annotation.dart';

part 'response_cookie.freezed.dart';
part 'response_cookie.g.dart';

@freezed
class ResponseCookie with _$ResponseCookie {
  const factory ResponseCookie({
    required String name,
    required String value,
    String? domain,
    String? path,
    DateTime? expires,
    @Default(false) bool httpOnly,
    @Default(false) bool secure,
  }) = _ResponseCookie;

  factory ResponseCookie.fromJson(Map<String, dynamic> json) =>
      _$ResponseCookieFromJson(json);
}
