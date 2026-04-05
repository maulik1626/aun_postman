enum AuthType {
  none,
  bearer,
  basic,
  apiKey,
  oauth2,
  digest,
  awsSigV4;

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
      case AuthType.oauth2:
        return 'OAuth 2.0';
      case AuthType.digest:
        return 'Digest Auth';
      case AuthType.awsSigV4:
        return 'AWS Signature';
    }
  }
}

/// Stored on [AuthConfig.oauth2] — token request `grant_type`.
enum OAuth2GrantType {
  clientCredentials,
  password;

  String get wireValue {
    switch (this) {
      case OAuth2GrantType.clientCredentials:
        return 'client_credentials';
      case OAuth2GrantType.password:
        return 'password';
    }
  }

  static OAuth2GrantType fromWire(String? raw) {
    switch (raw) {
      case 'password':
        return OAuth2GrantType.password;
      case 'client_credentials':
      default:
        return OAuth2GrantType.clientCredentials;
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
