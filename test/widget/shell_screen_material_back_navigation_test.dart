import 'package:aun_reqstudio/features/shell/shell_screen_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _routerFor(String initialLocation) {
  Page<void> pageWithText(String text) => MaterialPage<void>(
    child: Scaffold(body: Center(child: Text(text))),
  );

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreenMaterial(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/collections',
                pageBuilder: (context, state) =>
                    pageWithText('Collections Root'),
                routes: [
                  GoRoute(
                    path: 'detail',
                    pageBuilder: (context, state) =>
                        pageWithText('Collection Detail'),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) => pageWithText('History Root'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/environments',
                pageBuilder: (context, state) =>
                    pageWithText('Environments Root'),
                routes: [
                  GoRoute(
                    path: ':uid',
                    pageBuilder: (context, state) =>
                        pageWithText('Environment Detail'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets(
    'Android back from a non-collections root tab goes to collections root',
    (tester) async {
      final router = _routerFor('/history');
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('History Root'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Collections Root'), findsOneWidget);
      expect(find.text('History Root'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Android back pops nested branch routes before returning to collections',
    (tester) async {
      final router = _routerFor('/environments/demo');
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Environment Detail'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Environments Root'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Collections Root'), findsOneWidget);
      expect(find.text('Environments Root'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
