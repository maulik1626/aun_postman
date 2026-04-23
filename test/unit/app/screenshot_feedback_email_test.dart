import 'package:aun_reqstudio/app/screenshot_feedback/screenshot_feedback_email.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds email payload with optional feedback fallback', () {
    final payload = ScreenshotFeedbackEmailBuilder.build(
      authenticatedEmail: 'user@example.com',
      submittedAt: DateTime(2026, 4, 22, 12, 26),
      platformLabel: 'iOS',
      deviceContext: const ScreenshotFeedbackDeviceContext(
        deviceName: 'iPhone 16 Pro',
        osLabel: 'iOS 26.3',
      ),
      feedbackMessage: '   ',
    );

    expect(payload.subject, contains('AUN ReqStudio Feedback | Screenshot'));
    expect(payload.subject, contains('iOS'));
    expect(payload.body, contains('user@example.com'));
    expect(payload.body, contains('No additional feedback provided.'));
    expect(payload.body, contains('- Device: iPhone 16 Pro'));
    expect(payload.body, contains('- OS: iOS 26.3'));
  });

  test('builds email payload with provided feedback message', () {
    final payload = ScreenshotFeedbackEmailBuilder.build(
      authenticatedEmail: null,
      submittedAt: DateTime(2026, 4, 22, 12, 26),
      platformLabel: 'Android',
      deviceContext: const ScreenshotFeedbackDeviceContext(
        deviceName: 'Samsung Galaxy S25 Ultra',
        osLabel: 'Android 14',
      ),
      feedbackMessage: 'Response body looks clipped in landscape.',
    );

    expect(payload.body, contains('Not signed in'));
    expect(payload.body, contains('Response body looks clipped in landscape.'));
    expect(payload.body, contains('- Platform: Android'));
    expect(payload.body, contains('- Device: Samsung Galaxy S25 Ultra'));
    expect(payload.body, contains('- OS: Android 14'));
  });
}
