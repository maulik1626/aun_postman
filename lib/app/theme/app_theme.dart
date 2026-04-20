import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  // ── Material themes ─────────────────────────────────────────────────────────

  static ThemeData materialThemeLight() => _materialTheme(Brightness.light);
  static ThemeData materialThemeDark() => _materialTheme(Brightness.dark);

  static ThemeData _materialTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: 'Satoshi',
      scaffoldBackgroundColor:
          isDark ? AppColors.brandCharcoal : AppColors.brandCream,

      // ── App bar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.brandCharcoal : AppColors.brandCream,
        foregroundColor: AppColors.seedColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.5,
        titleTextStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.seedColor,
        ),
        iconTheme: const IconThemeData(color: AppColors.seedColor),
        actionsIconTheme: const IconThemeData(color: AppColors.seedColor),
      ),

      // ── Bottom nav / rail ──────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.brandCharcoal : AppColors.brandCream,
        indicatorColor: AppColors.seedColor.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.seedColor, size: 22);
          }
          return IconThemeData(
            color: isDark
                ? const Color(0x99EBEBF5)
                : const Color(0x993C3C43),
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? AppColors.seedColor
              : (isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43));
          return TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isDark ? AppColors.brandCharcoal : AppColors.brandCream,
        selectedIconTheme:
            const IconThemeData(color: AppColors.seedColor, size: 22),
        unselectedIconTheme: IconThemeData(
          color:
              isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43),
          size: 22,
        ),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.seedColor,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 12,
          color: isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43),
        ),
        indicatorColor: AppColors.seedColor.withValues(alpha: 0.18),
      ),

      // ── Inputs ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF2A2520)
            : const Color(0xFFF0E8D8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF3A3530)
                : const Color(0xFFDDD3C0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.seedColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: TextStyle(
          fontFamily: 'Satoshi',
          color: isDark ? const Color(0x66EBEBF5) : const Color(0x663C3C43),
        ),
      ),

      // ── Switch ─────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.seedColor;
          }
          return null;
        }),
      ),

      // ── Cards ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF252018) : const Color(0xFFF5EDD8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF3A3530)
                : const Color(0xFFDDD3C0),
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Dialogs ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? const Color(0xFF252018) : AppColors.brandCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.brandCharcoal,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          color: isDark
              ? const Color(0x99EBEBF5)
              : const Color(0x993C3C43),
        ),
      ),

      // ── Bottom sheet ───────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? const Color(0xFF252018) : AppColors.brandCream,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Text ───────────────────────────────────────────────────────────────
      textTheme: _materialTextTheme(isDark),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark
            ? const Color(0xFF3A3530)
            : const Color(0xFFDDD3C0),
        thickness: 0.5,
        space: 0,
      ),

      // ── List tiles ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.brandCharcoal,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 13,
          color: isDark
              ? const Color(0x99EBEBF5)
              : const Color(0x993C3C43),
        ),
      ),

      // ── Chips ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static TextTheme _materialTextTheme(bool isDark) {
    final baseColor =
        isDark ? Colors.white : AppColors.brandCharcoal;
    final mutedColor =
        isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);

    TextStyle s(double size, FontWeight weight, Color color) => TextStyle(
          fontFamily: 'Satoshi',
          fontSize: size,
          fontWeight: weight,
          color: color,
        );

    return TextTheme(
      displayLarge: s(57, FontWeight.w700, baseColor),
      displayMedium: s(45, FontWeight.w700, baseColor),
      displaySmall: s(36, FontWeight.w700, baseColor),
      headlineLarge: s(32, FontWeight.w700, baseColor),
      headlineMedium: s(28, FontWeight.w600, baseColor),
      headlineSmall: s(24, FontWeight.w600, baseColor),
      titleLarge: s(22, FontWeight.w600, baseColor),
      titleMedium: s(16, FontWeight.w600, baseColor),
      titleSmall: s(14, FontWeight.w600, baseColor),
      bodyLarge: s(16, FontWeight.w400, baseColor),
      bodyMedium: s(14, FontWeight.w400, baseColor),
      bodySmall: s(12, FontWeight.w400, mutedColor),
      labelLarge: s(14, FontWeight.w600, baseColor),
      labelMedium: s(12, FontWeight.w500, baseColor),
      labelSmall: s(11, FontWeight.w500, mutedColor),
    );
  }
}
