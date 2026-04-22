import 'dart:ui' show PlatformDispatcher;
import 'dart:async';

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_router.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/theme/app_theme.dart';
import 'package:aun_reqstudio/app/theme/app_theme_provider.dart';
import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/features/settings/providers/ad_session_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget — branches to the correct app shell based on platform.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  VoidCallback? _notificationListener;

  @override
  void initState() {
    super.initState();
    _notificationListener = () {
      _handleNotificationPayload(UserNotification.notificationTapPayload.value);
    };
    UserNotification.notificationTapPayload.addListener(_notificationListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationPayload(UserNotification.consumeLaunchPayload());
    });
  }

  Future<void> _handleNotificationPayload(String? payload) async {
    if (!mounted || !AdConfig.ENABLE_ADS) return;
    if (payload != UserNotification.browseAdsExtendPayload) return;

    UserNotification.notificationTapPayload.value = null;
    final notifier = ref.read(adSessionProvider.notifier);
    final result = await notifier.extendBrowseAdRewardMode();
    if (!mounted) return;

    switch (result) {
      case RewardBrowseAdsResult.earned:
        await UserNotification.show(
          title: 'Ad pause extended',
          body:
              'Browse ads are extended for another ${AdConfig.rewardedBrowseAdsPauseMinutes} mins.',
          context: context,
        );
      case RewardBrowseAdsResult.unavailable:
        await UserNotification.show(
          title: 'Rewarded ad unavailable',
          body: 'Please try again in a moment.',
          context: context,
        );
      case RewardBrowseAdsResult.dismissed:
        break;
    }
  }

  @override
  void dispose() {
    if (_notificationListener != null) {
      UserNotification.notificationTapPayload.removeListener(
        _notificationListener!,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isAndroid
        ? const _MaterialAppShell()
        : const _CupertinoAppShell();
  }
}

Color resolveAndroidSystemNavColorForLocation({
  required ThemeData theme,
  required String location,
}) {
  final shellNavColor =
      theme.navigationBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;

  if (location == AppRoutes.auth) {
    return const Color(0xFF17110B);
  }

  if (location == AppRoutes.collections ||
      location == AppRoutes.history ||
      location == AppRoutes.environments ||
      location == AppRoutes.websocket) {
    return shellNavColor;
  }

  return theme.scaffoldBackgroundColor;
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
        final theme = Theme.of(context);
        final location = router.routerDelegate.currentConfiguration.uri.path;
        final systemNavColor = resolveAndroidSystemNavColorForLocation(
          theme: theme,
          location: location,
        );
        final navBrightness = ThemeData.estimateBrightnessForColor(
          systemNavColor,
        );
        final overlayStyle = SystemUiOverlayStyle(
          systemNavigationBarColor: systemNavColor,
          systemNavigationBarDividerColor: systemNavColor,
          systemNavigationBarIconBrightness: navBrightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: ColoredBox(
            color: systemNavColor,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              maintainBottomViewPadding: true,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
