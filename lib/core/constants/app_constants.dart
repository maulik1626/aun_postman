class AppConstants {
  AppConstants._();

  static const String appName = 'Postman';
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
}
