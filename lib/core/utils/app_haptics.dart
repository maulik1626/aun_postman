import 'package:flutter/services.dart';

/// Central place for light tactile feedback on primary actions (roadmap 6.8).
class AppHaptics {
  AppHaptics._();

  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }
}
