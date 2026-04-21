import 'package:aun_reqstudio/app/app.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAndroidSystemNavColorForLocation', () {
    test('uses shell navigation bar color on root tabs', () {
      final theme = AppTheme.materialThemeLight();

      expect(
        resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: AppRoutes.collections,
        ),
        theme.navigationBarTheme.backgroundColor,
      );
      expect(
        resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: AppRoutes.history,
        ),
        theme.navigationBarTheme.backgroundColor,
      );
      expect(
        resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: AppRoutes.environments,
        ),
        theme.navigationBarTheme.backgroundColor,
      );
      expect(
        resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: AppRoutes.websocket,
        ),
        theme.navigationBarTheme.backgroundColor,
      );
    });

    test('uses auth surface on auth route', () {
      final theme = AppTheme.materialThemeDark();

      expect(
        resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: AppRoutes.auth,
        ),
        const Color(0xFF17110B),
      );
    });

    test('uses scaffold background on inner screens', () {
      final theme = AppTheme.materialThemeLight();

      expect(
        resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: '/collections/demo/request/req-1',
        ),
        theme.scaffoldBackgroundColor,
      );
      expect(
        resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: AppRoutes.settings,
        ),
        theme.scaffoldBackgroundColor,
      );
      expect(
        resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: AppRoutes.importExport,
        ),
        theme.scaffoldBackgroundColor,
      );
    });
  });
}
