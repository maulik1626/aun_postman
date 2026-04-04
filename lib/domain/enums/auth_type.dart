enum AuthType {
  none,
  bearer,
  basic,
  apiKey;

  String get label {
    switch (this) {
      case AuthType.none:
        return 'No Auth';
      case AuthType.bearer:
        return 'Bearer Token';
      case AuthType.basic:
        return 'Basic Auth';
      case AuthType.apiKey:
        return 'API Key';
    }
  }
}

enum ApiKeyAddTo {
  header,
  query;

  String get label {
    switch (this) {
      case ApiKeyAddTo.header:
        return 'Header';
      case ApiKeyAddTo.query:
        return 'Query Param';
    }
  }
}
