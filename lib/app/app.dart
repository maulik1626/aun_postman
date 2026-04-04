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
        scaffoldBackgroundColor: brightness == Brightness.dark
            ? AppColors.brandCharcoal
            : AppColors.brandCream,
        barBackgroundColor: brightness == Brightness.dark
            ? AppColors.brandCharcoal
            : AppColors.brandCream,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.seedColor,
          textStyle: const TextStyle(fontFamily: 'Satoshi'),
          actionTextStyle: const TextStyle(fontFamily: 'Satoshi'),
          tabLabelTextStyle: const TextStyle(fontFamily: 'Satoshi'),
          navTitleTextStyle: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          navLargeTitleTextStyle: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          pickerTextStyle: const TextStyle(fontFamily: 'Satoshi'),
          dateTimePickerTextStyle: const TextStyle(fontFamily: 'Satoshi'),
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
