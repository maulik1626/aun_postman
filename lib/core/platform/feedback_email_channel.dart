import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FeedbackEmailException implements Exception {
  FeedbackEmailException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FeedbackEmailChannel {
  FeedbackEmailChannel._();

  static const MethodChannel _channel = MethodChannel(
    'com.aun.reqstudio/feedback_email',
  );

  static bool get platformSupported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static Future<void> composeEmail({
    required List<String> to,
    required String subject,
    required String body,
    required String attachmentPath,
    String attachmentMimeType = 'image/png',
    String attachmentName = 'aun_reqstudio_feedback.png',
  }) async {
    if (!platformSupported) {
      throw FeedbackEmailException(
        'Email feedback is only supported on iOS and Android.',
      );
    }

    try {
      await _channel.invokeMethod<void>('composeEmail', {
        'to': to,
        'subject': subject,
        'body': body,
        'attachmentPath': attachmentPath,
        'attachmentMimeType': attachmentMimeType,
        'attachmentName': attachmentName,
      });
    } on MissingPluginException {
      throw FeedbackEmailException('Email composer is not available.');
    } on PlatformException catch (error) {
      throw FeedbackEmailException(error.message ?? error.code);
    }
  }
}
