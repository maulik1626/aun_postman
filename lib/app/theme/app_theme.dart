import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  AppTheme._();

  /// All entries use [TextStyle.inherit] false so Cupertino nav title transitions
  /// can lerp without mixing inherited vs explicit styles.
  static CupertinoTextThemeData cupertinoTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final labelColor =
        isDark ? CupertinoColors.white : CupertinoColors.black;
    final secondaryLabel =
        isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);

    return CupertinoTextThemeData(
      primaryColor: AppColors.seedColor,
      textStyle: TextStyle(
        inherit: false,
        color: labelColor,
        fontFamily: 'Satoshi',
        fontSize: 17,
        decoration: TextDecoration.none,
      ),
      actionTextStyle: const TextStyle(
        inherit: false,
        color: AppColors.seedColor,
        fontFamily: 'Satoshi',
        fontSize: 17,
        decoration: TextDecoration.none,
      ),
      tabLabelTextStyle: TextStyle(
        inherit: false,
        color: secondaryLabel,
        fontFamily: 'Satoshi',
        fontSize: 10,
        decoration: TextDecoration.none,
      ),
      navTitleTextStyle: const TextStyle(
        inherit: false,
        color: AppColors.seedColor,
        fontFamily: 'Satoshi',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
      ),
      navLargeTitleTextStyle: const TextStyle(
        inherit: false,
        color: AppColors.seedColor,
        fontFamily: 'Satoshi',
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        decoration: TextDecoration.none,
      ),
      pickerTextStyle: TextStyle(
        inherit: false,
        color: labelColor,
        fontFamily: 'Satoshi',
        fontSize: 21,
        decoration: TextDecoration.none,
      ),
      dateTimePickerTextStyle: TextStyle(
        inherit: false,
        color: labelColor,
        fontFamily: 'Satoshi',
        fontSize: 17,
        decoration: TextDecoration.none,
      ),
    );
  }

  static final CupertinoThemeData light = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.seedColor,
    scaffoldBackgroundColor: AppColors.brandCream,
    barBackgroundColor: AppColors.brandCream,
    textTheme: cupertinoTextTheme(Brightness.light),
  );

  static final CupertinoThemeData dark = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.seedColor,
    scaffoldBackgroundColor: AppColors.brandCharcoal,
    barBackgroundColor: AppColors.brandCharcoal,
    textTheme: cupertinoTextTheme(Brightness.dark),
  );
}
