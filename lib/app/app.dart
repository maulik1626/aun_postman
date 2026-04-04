import 'package:aun_postman/app/router/app_router.dart';
import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:aun_postman/app/theme/app_theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final brightness = ref.watch(appThemeNotifierProvider);

    return CupertinoApp.router(
      title: 'Postman',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: brightness, // null = follow system
        primaryColor: AppColors.seedColor,
        // Do NOT set barBackgroundColor or scaffoldBackgroundColor —
        // leaving them null lets iOS 26 apply Liquid Glass automatically.
        textTheme: const CupertinoTextThemeData(
          primaryColor: AppColors.seedColor,
          textStyle: TextStyle(fontFamily: 'Satoshi'),
          actionTextStyle: TextStyle(fontFamily: 'Satoshi'),
          tabLabelTextStyle: TextStyle(fontFamily: 'Satoshi'),
          navTitleTextStyle: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          pickerTextStyle: TextStyle(fontFamily: 'Satoshi'),
          dateTimePickerTextStyle: TextStyle(fontFamily: 'Satoshi'),
        ),
      ),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
