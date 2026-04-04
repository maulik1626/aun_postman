import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  AppTheme._();

  static const _textTheme = CupertinoTextThemeData(
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
  );

  static const CupertinoThemeData light = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.seedColor,
    scaffoldBackgroundColor: AppColors.brandCream,
    barBackgroundColor: AppColors.brandCream,
    textTheme: _textTheme,
  );

  static const CupertinoThemeData dark = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.seedColor,
    scaffoldBackgroundColor: AppColors.brandCharcoal,
    barBackgroundColor: AppColors.brandCharcoal,
    textTheme: _textTheme,
  );
}
