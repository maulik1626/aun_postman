import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';

String? appAuthRedirect({
  required AppAuthState auth,
  required String matchedLocation,
}) {
  final goingToBootstrap = matchedLocation == AppRoutes.bootstrap;
  final goingToAuth = matchedLocation == AppRoutes.auth;

  if (auth.status == AuthBootstrapStatus.initializing) {
    return goingToBootstrap ? null : AppRoutes.bootstrap;
  }

  if (auth.hasFatalSetupError || !auth.isAuthenticated) {
    return goingToAuth ? null : AppRoutes.auth;
  }

  if (goingToBootstrap || goingToAuth) {
    return AppRoutes.collections;
  }

  return null;
}

String? appRouteRedirect({
  required AppAuthState auth,
  required Uri uri,
  required String matchedLocation,
}) {
  if (!isSafeAppRouteUri(uri) || !isSafeMatchedLocation(matchedLocation)) {
    return AppRoutes.bootstrap;
  }

  if (isPlatformFileLaunchLocation(uri)) {
    return AppRoutes.bootstrap;
  }

  return appAuthRedirect(auth: auth, matchedLocation: matchedLocation);
}

bool isPlatformFileLaunchLocation(Uri uri) {
  return uri.scheme.toLowerCase() == 'file';
}

bool isSafeAppRouteUri(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme.isNotEmpty &&
      scheme != 'http' &&
      scheme != 'https' &&
      scheme != 'file') {
    return false;
  }

  final raw = uri.toString().toLowerCase();
  if (raw.contains('..') ||
      raw.contains('%2e%2e') ||
      raw.contains('%2f%2e') ||
      raw.contains('%5c')) {
    return false;
  }

  return true;
}

bool isSafeMatchedLocation(String matchedLocation) {
  if (matchedLocation.isEmpty) {
    return false;
  }
  if (!matchedLocation.startsWith('/')) {
    return false;
  }
  final normalized = matchedLocation.toLowerCase();
  if (normalized.contains('..') ||
      normalized.contains('%2e%2e') ||
      normalized.contains('%2f%2e') ||
      normalized.contains('%5c')) {
    return false;
  }
  return true;
}
