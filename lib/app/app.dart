import 'dart:ui' show PlatformDispatcher;

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_router.dart';
import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/theme/app_theme.dart';
import 'package:aun_reqstudio/app/theme/app_theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget — branches to the correct app shell based on platform.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPlatform.isAndroid
        ? const _MaterialAppShell()
        : const _CupertinoAppShell();
  }
}

// ── iOS — Cupertino ──────────────────────────────────────────────────────────

class _CupertinoAppShell extends ConsumerWidget {
  const _CupertinoAppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final brightness = ref.watch(appThemeNotifierProvider);
    final effectiveBrightness =
        brightness ?? PlatformDispatcher.instance.platformBrightness;

    return CupertinoApp.router(
      title: 'AUN - ReqStudio',
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

// ── Android — Material ───────────────────────────────────────────────────────

class _MaterialAppShell extends ConsumerWidget {
  const _MaterialAppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final override = ref.watch(appThemeNotifierProvider);

    final ThemeMode themeMode;
    if (override == null) {
      themeMode = ThemeMode.system;
    } else if (override == Brightness.dark) {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.light;
    }

    return MaterialApp.router(
      title: 'AUN - ReqStudio',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.materialThemeLight(),
      darkTheme: AppTheme.materialThemeDark(),
      // Edge-to-edge Android: 3-button nav overlaps content because [Scaffold]
      // does not inset [body] by [MediaQuery.padding] (see framework docs).
      // Physical bottom [SafeArea] shrinks the subtree (incl. navigator overlay),
      // so screens and modal bottom sheets lay out above the system nav bar.
      // [maintainBottomViewPadding] keeps bottom inset when the keyboard opens.
      // iOS uses [_CupertinoAppShell] only — this builder runs on Android.
      builder: (context, child) {
        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          maintainBottomViewPadding: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
