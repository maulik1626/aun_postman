import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CrashlyticsService {
  CrashlyticsService._();

  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static FirebaseAnalytics? _analytics;
  static bool _initialized = false;

  static String get currentEnvironment {
    const configured = String.fromEnvironment('APP_ENV');
    if (configured.isNotEmpty) {
      return configured;
    }
    return kReleaseMode ? 'production' : 'development';
  }

  static bool get showsInternalTools => !kReleaseMode;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _analytics = FirebaseAnalytics.instance;
    await _analytics!.setAnalyticsCollectionEnabled(true);
    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    final info = await PackageInfo.fromPlatform();
    final buildMode = switch (kDebugMode) {
      true => 'debug',
      false => kProfileMode ? 'profile' : 'release',
    };

    await Future.wait([
      _crashlytics.setCustomKey('app_name', info.appName),
      _crashlytics.setCustomKey('app_version', info.version),
      _crashlytics.setCustomKey('build_number', info.buildNumber),
      _crashlytics.setCustomKey('package_name', info.packageName),
      _crashlytics.setCustomKey('environment', currentEnvironment),
      _crashlytics.setCustomKey('build_mode', buildMode),
      _crashlytics.setCustomKey('platform', defaultTargetPlatform.name),
    ]);

    await _crashlytics.log(
      'Crashlytics initialized for $buildMode / ${currentEnvironment.toLowerCase()}',
    );
    _initialized = true;
  }

  static Future<void> setUser(User? user) async {
    if (!_initialized) {
      return;
    }

    final identifier = user?.uid ?? '';
    await _crashlytics.setUserIdentifier(identifier);
    await _crashlytics.setCustomKey('signed_in', user != null);

    if (user != null) {
      final providerIds = user.providerData
          .map((provider) => provider.providerId)
          .where((providerId) => providerId.isNotEmpty)
          .join(',');
      await _crashlytics.setCustomKey(
        'auth_providers',
        providerIds.isEmpty ? 'unknown' : providerIds,
      );
      await _crashlytics.setCustomKey('email_verified', user.emailVerified);
    } else {
      await _crashlytics.setCustomKey('auth_providers', 'signed_out');
      await _crashlytics.setCustomKey('email_verified', false);
    }
  }

  static Future<void> log(String message) async {
    if (!_initialized) {
      return;
    }
    await _crashlytics.log(message);
  }

  static Future<void> recordFlutterFatalError(
    FlutterErrorDetails details,
  ) async {
    if (!_initialized) {
      return;
    }
    await _crashlytics.recordFlutterFatalError(details);
  }

  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_initialized) {
      return;
    }
    await _crashlytics.recordFlutterError(details);
  }

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    if (!_initialized) {
      return;
    }

    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
      information: information,
    );
  }

  static Future<void> recordTestNonFatal() async {
    await recordError(
      StateError('Crashlytics test non-fatal'),
      StackTrace.current,
      reason: 'Internal QA verification',
      information: [
        'Triggered from the internal Crashlytics verification controls.',
      ],
    );
    await log('Recorded internal Crashlytics test non-fatal.');
  }

  static Never forceCrash() {
    throw StateError('Crashlytics test crash');
  }
}
