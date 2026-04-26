import 'dart:io';

DateTime? parseCookieExpiresValue(String value) {
  try {
    return HttpDate.parse(value);
  } catch (_) {
    return DateTime.tryParse(value);
  }
}
