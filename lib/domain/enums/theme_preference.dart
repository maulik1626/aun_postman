import 'package:flutter/cupertino.dart';

enum ThemePreference {
  light,
  dark,
  system;

  Brightness? get brightness {
    switch (this) {
      case ThemePreference.light:
        return Brightness.light;
      case ThemePreference.dark:
        return Brightness.dark;
      case ThemePreference.system:
        return null;
    }
  }

  String get label {
    switch (this) {
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
      case ThemePreference.system:
        return 'System';
    }
  }
}
