import 'package:aun_postman/core/constants/app_constants.dart';
import 'package:aun_postman/domain/enums/theme_preference.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_theme_provider.g.dart';

@Riverpod(keepAlive: true)
class AppThemeNotifier extends _$AppThemeNotifier {
  static const _storage = FlutterSecureStorage();

  @override
  Brightness? build() {
    _load();
    return null; // null = follow system
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: StorageKeys.themePreference);
    if (saved != null) {
      final pref = ThemePreference.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemePreference.system,
      );
      state = pref.brightness;
    }
  }

  Future<void> setTheme(ThemePreference pref) async {
    state = pref.brightness;
    await _storage.write(
      key: StorageKeys.themePreference,
      value: pref.name,
    );
  }
}
