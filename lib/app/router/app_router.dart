import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_navigator.dart';
import 'package:aun_reqstudio/app/router/auth_redirect.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/domain/models/history_entry.dart';
import 'package:aun_reqstudio/features/auth/auth_bootstrap_screen.dart';
import 'package:aun_reqstudio/features/auth/auth_bootstrap_screen_material.dart';
import 'package:aun_reqstudio/features/auth/auth_screen.dart';
import 'package:aun_reqstudio/features/auth/auth_screen_material.dart';
import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:aun_reqstudio/features/collections/collection_auth_screen.dart';
import 'package:aun_reqstudio/features/collections/collection_auth_screen_material.dart';
import 'package:aun_reqstudio/features/collections/collection_detail_screen.dart';
import 'package:aun_reqstudio/features/collections/collection_detail_screen_material.dart';
import 'package:aun_reqstudio/features/collections/collections_screen.dart';
import 'package:aun_reqstudio/features/collections/collections_screen_material.dart';
import 'package:aun_reqstudio/features/environments/environment_detail_screen.dart';
import 'package:aun_reqstudio/features/environments/environment_detail_screen_material.dart';
import 'package:aun_reqstudio/features/environments/environments_screen.dart';
import 'package:aun_reqstudio/features/environments/environments_screen_material.dart';
import 'package:aun_reqstudio/features/history/history_screen.dart';
import 'package:aun_reqstudio/features/history/history_screen_material.dart';
import 'package:aun_reqstudio/features/import_export/import_export_screen.dart';
import 'package:aun_reqstudio/features/import_export/import_export_screen_material.dart';
import 'package:aun_reqstudio/features/request_builder/request_builder_screen.dart';
import 'package:aun_reqstudio/features/request_builder/request_builder_screen_material.dart';
import 'package:aun_reqstudio/features/settings/default_headers_settings_screen.dart';
import 'package:aun_reqstudio/features/settings/default_headers_settings_screen_material.dart';
import 'package:aun_reqstudio/features/settings/proxy_settings_screen.dart';
import 'package:aun_reqstudio/features/settings/proxy_settings_screen_material.dart';
import 'package:aun_reqstudio/features/settings/settings_screen.dart';
import 'package:aun_reqstudio/features/settings/settings_screen_material.dart';
import 'package:aun_reqstudio/features/shell/shell_screen.dart';
import 'package:aun_reqstudio/features/shell/shell_screen_material.dart';
import 'package:aun_reqstudio/features/websocket/websocket_screen.dart';
import 'package:aun_reqstudio/features/websocket/websocket_screen_material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Returns the correct [Page] wrapper for the current platform.
/// iOS uses [CupertinoPage] (swipe-back, hero transitions).
/// Android uses [MaterialPage] (slide-left push transitions).
Page<void> _page(Widget child, {bool fullscreenDialog = false}) {
  if (AppPlatform.isAndroid) {
    return MaterialPage(child: child, fullscreenDialog: fullscreenDialog);
  }
  return CupertinoPage(child: child, fullscreenDialog: fullscreenDialog);
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: AppRoutes.bootstrap,
    // iOS share-sheet launches can arrive with a raw `file:///...json` platform
    // route. Shared JSON imports are handled by the native bridge instead of
    // router deep links, so we always start from our app bootstrap route.
    overridePlatformDefaultLocation: true,
    debugLogDiagnostics: false,
    redirect: (context, state) => appRouteRedirect(
      auth: auth,
      uri: state.uri,
      matchedLocation: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.bootstrap,
        pageBuilder: (context, state) => _page(
          AppPlatform.isAndroid
              ? const AuthBootstrapScreenMaterial()
              : const AuthBootstrapScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (context, state) => _page(
          AppPlatform.isAndroid
              ? const AuthScreenMaterial()
              : const AuthScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppPlatform.isAndroid
            ? ShellScreenMaterial(shell: shell)
            : ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.collections,
                pageBuilder: (context, state) => _page(
                  AppPlatform.isAndroid
                      ? const CollectionsScreenMaterial()
                      : const CollectionsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':uid',
                    pageBuilder: (context, state) => _page(
                      AppPlatform.isAndroid
                          ? CollectionDetailScreenMaterial(
                              uid: state.pathParameters['uid']!,
                            )
                          : CollectionDetailScreen(
                              uid: state.pathParameters['uid']!,
                            ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'request/new',
                        pageBuilder: (context, state) => _page(
                          AppPlatform.isAndroid
                              ? RequestBuilderScreenMaterial(
                                  collectionUid: state.pathParameters['uid']!,
                                  folderUid: state.extra is String
                                      ? state.extra as String
                                      : null,
                                )
                              : RequestBuilderScreen(
                                  collectionUid: state.pathParameters['uid']!,
                                  folderUid: state.extra is String
                                      ? state.extra as String
                                      : null,
                                ),
                        ),
                      ),
                      GoRoute(
                        path: 'request/:reqUid',
                        pageBuilder: (context, state) => _page(
                          AppPlatform.isAndroid
                              ? RequestBuilderScreenMaterial(
                                  collectionUid: state.pathParameters['uid']!,
                                  requestUid: state.pathParameters['reqUid'],
                                  openedFromHistory: switch (state.extra) {
                                    final HistoryEntry e => e,
                                    _ => null,
                                  },
                                )
                              : RequestBuilderScreen(
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
                        pageBuilder: (context, state) => _page(
                          AppPlatform.isAndroid
                              ? CollectionAuthScreenMaterial(
                                  collectionUid: state.pathParameters['uid']!,
                                )
                              : CollectionAuthScreen(
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
                pageBuilder: (context, state) => _page(
                  AppPlatform.isAndroid
                      ? const HistoryScreenMaterial()
                      : const HistoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.environments,
                pageBuilder: (context, state) => _page(
                  AppPlatform.isAndroid
                      ? const EnvironmentsScreenMaterial()
                      : const EnvironmentsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':uid',
                    pageBuilder: (context, state) => _page(
                      AppPlatform.isAndroid
                          ? EnvironmentDetailScreenMaterial(
                              uid: state.pathParameters['uid']!,
                            )
                          : EnvironmentDetailScreen(
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
                pageBuilder: (context, state) => _page(
                  AppPlatform.isAndroid
                      ? const WebSocketScreenMaterial()
                      : const WebSocketScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _page(
          AppPlatform.isAndroid
              ? const SettingsScreenMaterial()
              : const SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'default-headers',
            pageBuilder: (context, state) => _page(
              AppPlatform.isAndroid
                  ? const DefaultHeadersSettingsScreenMaterial()
                  : const DefaultHeadersSettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'proxy',
            pageBuilder: (context, state) => _page(
              AppPlatform.isAndroid
                  ? const ProxySettingsScreenMaterial()
                  : const ProxySettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.importExport,
        pageBuilder: (context, state) => _page(
          AppPlatform.isAndroid
              ? const ImportExportScreenMaterial()
              : const ImportExportScreen(),
          fullscreenDialog: true,
        ),
      ),
    ],
  );
}
