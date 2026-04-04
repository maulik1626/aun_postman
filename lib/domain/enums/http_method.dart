enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options;

  String get value => name.toUpperCase();

  static HttpMethod fromString(String value) {
    return HttpMethod.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => HttpMethod.get,
    );
  }
}
