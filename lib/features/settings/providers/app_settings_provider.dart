import 'package:aun_postman/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_provider.g.dart';

class AppSettingsState {
  const AppSettingsState({
    this.timeoutSeconds = AppConstants.defaultTimeoutSeconds,
    this.followRedirects = true,
  });

  final int timeoutSeconds;
  final bool followRedirects;

  AppSettingsState copyWith({int? timeoutSeconds, bool? followRedirects}) =>
      AppSettingsState(
        timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
        followRedirects: followRedirects ?? this.followRedirects,
      );
}

@Riverpod(keepAlive: true)
class AppSettings extends _$AppSettings {
  static const _storage = FlutterSecureStorage();

  @override
  AppSettingsState build() {
    _load();
    return const AppSettingsState();
  }

  Future<void> _load() async {
    final timeoutStr =
        await _storage.read(key: StorageKeys.defaultTimeout);
    final followStr =
        await _storage.read(key: StorageKeys.followRedirects);
    state = AppSettingsState(
      timeoutSeconds: (timeoutStr != null
              ? int.tryParse(timeoutStr) ?? AppConstants.defaultTimeoutSeconds
              : AppConstants.defaultTimeoutSeconds)
          .clamp(5, 300),
      followRedirects: followStr != 'false',
    );
  }

  Future<void> setTimeoutSeconds(int seconds) async {
    final clamped = seconds.clamp(5, 300);
    state = state.copyWith(timeoutSeconds: clamped);
    await _storage.write(
        key: StorageKeys.defaultTimeout, value: clamped.toString());
  }

  Future<void> setFollowRedirects(bool value) async {
    state = state.copyWith(followRedirects: value);
    await _storage.write(
        key: StorageKeys.followRedirects, value: value.toString());
  }
}
