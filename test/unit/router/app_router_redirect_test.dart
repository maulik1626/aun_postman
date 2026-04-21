import 'package:aun_reqstudio/app/router/auth_redirect.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('appAuthRedirect', () {
    test('holds bootstrap route while auth is initializing', () {
      const auth = AppAuthState(status: AuthBootstrapStatus.initializing);

      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.bootstrap),
        isNull,
      );
      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.collections),
        AppRoutes.bootstrap,
      );
    });

    test('sends signed-out users to auth after bootstrap', () {
      const auth = AppAuthState(status: AuthBootstrapStatus.ready);

      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.bootstrap),
        AppRoutes.auth,
      );
      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.auth),
        isNull,
      );
      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.collections),
        AppRoutes.auth,
      );
    });

    test('sends fatal setup errors to auth', () {
      const auth = AppAuthState(status: AuthBootstrapStatus.setupError);

      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.bootstrap),
        AppRoutes.auth,
      );
      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.settings),
        AppRoutes.auth,
      );
    });

    test('sends authenticated users past bootstrap and auth', () {
      final auth = AppAuthState(
        status: AuthBootstrapStatus.ready,
        user: _MockUser(),
      );

      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.bootstrap),
        AppRoutes.collections,
      );
      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.auth),
        AppRoutes.collections,
      );
      expect(
        appAuthRedirect(auth: auth, matchedLocation: AppRoutes.collections),
        isNull,
      );
    });
  });
}

class _MockUser extends Mock implements User {}
