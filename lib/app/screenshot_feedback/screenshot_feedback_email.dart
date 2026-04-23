import 'package:intl/intl.dart';

class ScreenshotFeedbackDeviceContext {
  const ScreenshotFeedbackDeviceContext({
    required this.deviceName,
    required this.osLabel,
  });

  final String deviceName;
  final String osLabel;
}

class ScreenshotFeedbackEmailPayload {
  const ScreenshotFeedbackEmailPayload({
    required this.subject,
    required this.body,
  });

  final String subject;
  final String body;
}

class ScreenshotFeedbackEmailBuilder {
  ScreenshotFeedbackEmailBuilder._();

  static const recipient = 'rajamaulik9@gmail.com';

  static ScreenshotFeedbackEmailPayload build({
    required String? authenticatedEmail,
    required DateTime submittedAt,
    required String platformLabel,
    required ScreenshotFeedbackDeviceContext deviceContext,
    String? feedbackMessage,
  }) {
    final trimmedFeedback = feedbackMessage?.trim() ?? '';
    final effectiveEmail =
        (authenticatedEmail == null || authenticatedEmail.trim().isEmpty)
        ? 'Not signed in'
        : authenticatedEmail.trim();
    final timestamp = DateFormat('yyyy-MM-dd hh:mm a').format(submittedAt);
    final subject =
        'AUN ReqStudio Feedback | Screenshot | $platformLabel | $timestamp';
    final body = StringBuffer()
      ..writeln('Hello Maulik,')
      ..writeln()
      ..writeln('A user submitted screenshot feedback from AUN ReqStudio.')
      ..writeln()
      ..writeln('Authenticated user email:')
      ..writeln(effectiveEmail)
      ..writeln()
      ..writeln('Feedback:')
      ..writeln(
        trimmedFeedback.isEmpty
            ? 'No additional feedback provided.'
            : trimmedFeedback,
      )
      ..writeln()
      ..writeln('Context:')
      ..writeln('- App: AUN ReqStudio')
      ..writeln('- Device: ${deviceContext.deviceName}')
      ..writeln('- OS: ${deviceContext.osLabel}')
      ..writeln('- Platform: $platformLabel')
      ..writeln('- Submitted at: $timestamp')
      ..writeln()
      ..writeln('Screenshot:')
      ..writeln('Attached by the app.')
      ..writeln()
      ..writeln('Regards,')
      ..writeln('AUN ReqStudio');

    return ScreenshotFeedbackEmailPayload(
      subject: subject,
      body: body.toString().trimRight(),
    );
  }
}
