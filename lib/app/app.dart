import 'dart:ui' show PlatformDispatcher;

import 'package:aun_postman/app/router/app_router.dart';
import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:aun_postman/app/theme/app_theme.dart';
import 'package:aun_postman/app/theme/app_theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final brightness = ref.watch(appThemeNotifierProvider);
    final effectiveBrightness =
        brightness ?? PlatformDispatcher.instance.platformBrightness;

    return CupertinoApp.router(
      title: 'Postman',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: brightness, // null = follow system
        primaryColor: AppColors.seedColor,
        // Do NOT set barBackgroundColor or scaffoldBackgroundColor —
        // leaving them null lets iOS 26 apply Liquid Glass automatically.
        textTheme: AppTheme.cupertinoTextTheme(effectiveBrightness),
      ),
      localizationsDelegates: const [
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
