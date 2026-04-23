import 'package:aun_reqstudio/core/constants/legal_urls.dart';

/// HTTPS host for [LegalUrls] pages allowed inside the in-app WebView.
/// Other navigations are opened in the system browser.
abstract final class LegalWebViewAllowlist {
  LegalWebViewAllowlist._();

  static String get _allowedHost => Uri.parse(LegalUrls.support).host;

  static bool isAllowedInAppNavigation(Uri uri) {
    if (uri.scheme != 'https') return false;
    return uri.host == _allowedHost;
  }
}
