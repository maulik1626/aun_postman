DateTime? parseCookieExpiresValue(String value) {
  // Browser Set-Cookie access is generally restricted; keep parser defensive.
  return DateTime.tryParse(value);
}
