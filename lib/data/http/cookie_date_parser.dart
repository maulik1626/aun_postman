import 'cookie_date_parser_web.dart'
    if (dart.library.io) 'cookie_date_parser_io.dart'
    as impl;

DateTime? parseCookieExpiresValue(String value) {
  return impl.parseCookieExpiresValue(value);
}
