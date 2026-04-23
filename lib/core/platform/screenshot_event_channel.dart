import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class ScreenshotTakenEvent {
  const ScreenshotTakenEvent({
    required this.platform,
    required this.takenAt,
  });

  final String platform;
  final DateTime takenAt;

  factory ScreenshotTakenEvent.fromMap(Map<Object?, Object?> map) {
    final rawMs = map['takenAtMs'];
    final takenAtMs = switch (rawMs) {
      final int value => value,
      final double value => value.toInt(),
      _ => DateTime.now().millisecondsSinceEpoch,
    };
    return ScreenshotTakenEvent(
      platform: (map['platform'] as String?) ?? 'unknown',
      takenAt: DateTime.fromMillisecondsSinceEpoch(takenAtMs),
    );
  }
}

class ScreenshotEventChannel {
  ScreenshotEventChannel._();

  static const String _name = 'com.aun.reqstudio/screenshot_events';
  static const EventChannel _channel = EventChannel(_name);

  static bool get platformSupported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static Stream<ScreenshotTakenEvent> events() {
    if (!platformSupported) {
      return const Stream<ScreenshotTakenEvent>.empty();
    }

    return _channel.receiveBroadcastStream().map((dynamic event) {
      final map = event is Map<Object?, Object?> ? event : <Object?, Object?>{};
      return ScreenshotTakenEvent.fromMap(map);
    }).handleError((Object _) {
      return const Stream<ScreenshotTakenEvent>.empty();
    });
  }
}
