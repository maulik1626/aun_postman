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
