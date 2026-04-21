class AppConstants {
  AppConstants._();

  static const String appName = 'AUN - ReqStudio';
  static const String dbName = 'aun_postman_db';
  static const int defaultTimeoutSeconds = 30;
  static const int maxHistoryEntries = 500;
  static const int maxResponseSizeBytes = 10 * 1024 * 1024; // 10 MB
}

class StorageKeys {
  StorageKeys._();

  static const String themePreference = 'theme_preference';
  static const String defaultTimeout = 'default_timeout';
  static const String followRedirects = 'follow_redirects';
  static const String sslVerification = 'ssl_verification';
  static const String defaultHeaders = 'default_headers_json';
  static const String httpProxy = 'http_proxy';
  static const String wsAutoReconnect = 'ws_auto_reconnect';
  static const String wsSavedSession = 'ws_saved_session_json';
  static const String requestAutoSave = 'request_auto_save';
  static const String icloudAutoBackup = 'icloud_auto_backup';
  static const String adsCollectionsInterval = 'ads_collections_interval';
  static const String adsHistoryInterval = 'ads_history_interval';
  static const String adsEnvironmentsInterval = 'ads_environments_interval';
  static const String backendSessionToken = 'backend_session_token';
  static const String backendSessionIssuedAt = 'backend_session_issued_at';
  static const String hasSignedInBefore = 'has_signed_in_before';
}
