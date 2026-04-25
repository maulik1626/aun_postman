import 'package:aun_reqstudio/core/services/crashlytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrashlyticsService', () {
    test('currentEnvironment defaults by build mode when APP_ENV is unset', () {
      final expected = kReleaseMode ? 'production' : 'development';
      expect(CrashlyticsService.currentEnvironment, expected);
    });

    test('internal verification controls stay out of release builds', () {
      expect(CrashlyticsService.showsInternalTools, !kReleaseMode);
    });
  });
}
