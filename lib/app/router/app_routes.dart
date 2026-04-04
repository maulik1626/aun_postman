class AppRoutes {
  AppRoutes._();

  static const String collections = '/collections';
  static const String collectionDetail = '/collections/:uid';
  static const String newRequest = '/collections/:uid/request/new';
  static const String editRequest = '/collections/:uid/request/:reqUid';
  static const String history = '/history';
  static const String environments = '/environments';
  static const String environmentDetail = '/environments/:uid';
  static const String websocket = '/websocket';
  static const String settings = '/settings';
  static const String importExport = '/import';
}
