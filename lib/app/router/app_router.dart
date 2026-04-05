import 'package:aun_postman/app/router/app_routes.dart';
import 'package:aun_postman/domain/models/history_entry.dart';
import 'package:aun_postman/features/collections/collection_auth_screen.dart';
import 'package:aun_postman/features/collections/collection_detail_screen.dart';
import 'package:aun_postman/features/collections/collections_screen.dart';
import 'package:aun_postman/features/environments/environment_detail_screen.dart';
import 'package:aun_postman/features/environments/environments_screen.dart';
import 'package:aun_postman/features/history/history_screen.dart';
import 'package:aun_postman/features/import_export/import_export_screen.dart';
import 'package:aun_postman/features/request_builder/request_builder_screen.dart';
import 'package:aun_postman/features/settings/default_headers_settings_screen.dart';
import 'package:aun_postman/features/settings/proxy_settings_screen.dart';
import 'package:aun_postman/features/settings/settings_screen.dart';
import 'package:aun_postman/features/shell/shell_screen.dart';
import 'package:aun_postman/features/websocket/websocket_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.collections,
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.collections,
                pageBuilder: (context, state) => const CupertinoPage(
                  child: CollectionsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':uid',
                    pageBuilder: (context, state) => CupertinoPage(
                      child: CollectionDetailScreen(
                        uid: state.pathParameters['uid']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'request/new',
                        pageBuilder: (context, state) => CupertinoPage(
                          child: RequestBuilderScreen(
                            collectionUid: state.pathParameters['uid']!,
                            folderUid:
                                state.extra is String ? state.extra as String : null,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'request/:reqUid',
                        pageBuilder: (context, state) => CupertinoPage(
                          child: RequestBuilderScreen(
                            collectionUid: state.pathParameters['uid']!,
                            requestUid: state.pathParameters['reqUid'],
                            openedFromHistory: switch (state.extra) {
                              final HistoryEntry e => e,
                              _ => null,
                            },
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'auth',
                        pageBuilder: (context, state) => CupertinoPage(
                          child: CollectionAuthScreen(
                            collectionUid: state.pathParameters['uid']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                pageBuilder: (context, state) => const CupertinoPage(
                  child: HistoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.environments,
                pageBuilder: (context, state) => const CupertinoPage(
                  child: EnvironmentsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':uid',
                    pageBuilder: (context, state) => CupertinoPage(
                      child: EnvironmentDetailScreen(
                        uid: state.pathParameters['uid']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.websocket,
                pageBuilder: (context, state) => const CupertinoPage(
                  child: WebSocketScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => const CupertinoPage(
          child: SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'default-headers',
            pageBuilder: (context, state) => const CupertinoPage(
              child: DefaultHeadersSettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'proxy',
            pageBuilder: (context, state) => const CupertinoPage(
              child: ProxySettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.importExport,
        pageBuilder: (context, state) => CupertinoPage(
          fullscreenDialog: true,
          child: const ImportExportScreen(),
        ),
      ),
    ],
  );
}
