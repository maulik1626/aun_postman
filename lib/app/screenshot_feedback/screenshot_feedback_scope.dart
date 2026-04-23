import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_navigator.dart';
import 'package:aun_reqstudio/app/screenshot_feedback/screenshot_feedback_email.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/platform/feedback_device_info.dart';
import 'package:aun_reqstudio/core/platform/screenshot_event_channel.dart';
import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScreenshotFeedbackScope extends ConsumerStatefulWidget {
  const ScreenshotFeedbackScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ScreenshotFeedbackScope> createState() =>
      _ScreenshotFeedbackScopeState();
}

class _ScreenshotFeedbackScopeState
    extends ConsumerState<ScreenshotFeedbackScope> {
  final GlobalKey _captureKey = GlobalKey();
  StreamSubscription<ScreenshotTakenEvent>? _subscription;
  bool _isHandlingScreenshot = false;
  DateTime? _lastHandledAt;

  @override
  void initState() {
    super.initState();
    _subscription = ScreenshotEventChannel.events().listen(_handleScreenshot);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleScreenshot(ScreenshotTakenEvent event) async {
    if (!mounted || _isHandlingScreenshot) return;

    final lastHandledAt = _lastHandledAt;
    if (lastHandledAt != null &&
        event.takenAt.difference(lastHandledAt).inMilliseconds.abs() < 1500) {
      return;
    }

    _isHandlingScreenshot = true;
    _lastHandledAt = event.takenAt;
    File? screenshotFile;
    ScreenshotFeedbackEmailPayload? payload;
    try {
      screenshotFile = await _captureAppScreenshot();
      if (!mounted) return;
      if (screenshotFile == null) {
        await _showFeedbackNotice(
          title: 'Screenshot unavailable',
          body:
              'We could not prepare the screenshot for feedback. Please try again.',
        );
        return;
      }

      final feedbackMessage = await _showFeedbackDialog();
      if (!mounted || feedbackMessage == null) {
        return;
      }

      final auth = ref.read(authControllerProvider);
      final deviceInfo = await FeedbackDeviceInfoResolver.resolve();
      payload = ScreenshotFeedbackEmailBuilder.build(
        authenticatedEmail: auth.user?.email,
        submittedAt: DateTime.now(),
        platformLabel: AppPlatform.isIOS ? 'iOS' : 'Android',
        deviceContext: ScreenshotFeedbackDeviceContext(
          deviceName: deviceInfo.deviceName,
          osLabel: deviceInfo.osLabel,
        ),
        feedbackMessage: feedbackMessage,
      );

      await FlutterEmailSender.send(
        Email(
          subject: payload.subject,
          body: payload.body,
          recipients: const [ScreenshotFeedbackEmailBuilder.recipient],
          attachmentPaths: [screenshotFile.path],
        ),
      );
    } on MissingPluginException {
      await _handleEmailFailure(
        screenshotFile: screenshotFile,
        payload: payload,
      );
    } on PlatformException catch (error) {
      await _handleEmailFailure(
        screenshotFile: screenshotFile,
        payload: payload,
        canUseShareFallback: _shouldFallbackToShareSheet(
          error.code,
          error.message,
        ),
      );
    } catch (_) {
      await _handleEmailFailure(
        screenshotFile: screenshotFile,
        payload: payload,
      );
    } finally {
      _isHandlingScreenshot = false;
    }
  }

  Future<File?> _captureAppScreenshot() async {
    final pixelRatio = math.max(
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio,
      2.0,
    );
    final image = await _captureBoundaryImage(pixelRatio);
    if (image == null) return null;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/aun_reqstudio_feedback_capture_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file;
  }

  Future<ui.Image?> _captureBoundaryImage(double pixelRatio) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null && !boundary.debugNeedsPaint) {
        try {
          return await boundary.toImage(pixelRatio: pixelRatio);
        } catch (_) {
          // Screenshot notifications can arrive before the boundary's layer is ready.
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
    return null;
  }

  Future<String?> _showFeedbackDialog() async {
    final navigatorContext = appRootNavigatorKey.currentContext;
    if (navigatorContext == null) return null;
    final controller = TextEditingController();
    final result = await showCupertinoDialog<String?>(
      context: navigatorContext,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Send feedback?'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Share this screenshot with AUN ReqStudio support to report a bug or provide app feedback.',
            ),
            const SizedBox(height: 14),
            CupertinoTextField(
              controller: controller,
              maxLines: 5,
              minLines: 3,
              placeholder: 'Describe the issue',
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Optional',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(
                    dialogContext,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Send Feedback'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _handleEmailFailure({
    required File? screenshotFile,
    required ScreenshotFeedbackEmailPayload? payload,
    bool canUseShareFallback = true,
  }) async {
    if (!mounted) return;
    if (screenshotFile == null || payload == null) {
      await _showFeedbackNotice(
        title: 'Feedback unavailable',
        body:
            'We could not prepare the screenshot feedback email. Please try again.',
      );
      return;
    }

    if (canUseShareFallback) {
      final didShare = await _tryShareFeedbackFallback(
        file: screenshotFile,
        subject: payload.subject,
        body: payload.body,
      );
      if (didShare) return;
    }

    await _showFeedbackNotice(
      title: 'Email unavailable',
      body:
          'We prepared the screenshot, but could not open your email app. Please make sure an email account is set up, then try again.',
    );
  }

  Future<bool> _tryShareFeedbackFallback({
    required File file,
    required String subject,
    required String body,
  }) async {
    try {
      await _shareFeedbackFallback(file: file, subject: subject, body: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showFeedbackNotice({
    required String title,
    required String body,
  }) async {
    if (!mounted) return;
    try {
      await UserNotification.show(context: context, title: title, body: body);
    } catch (_) {
      // Notification delivery must never surface implementation exceptions.
    }
  }

  bool _shouldFallbackToShareSheet(String code, String? message) {
    final lowerCode = code.toLowerCase();
    final lowerMessage = (message ?? '').toLowerCase();
    return lowerCode == 'not_available' ||
        lowerCode == 'error' ||
        lowerMessage.contains('not available') ||
        lowerMessage.contains('no mail account');
  }

  Future<void> _shareFeedbackFallback({
    required File file,
    required String subject,
    required String body,
  }) async {
    final navigatorContext = appRootNavigatorKey.currentContext;
    final size = navigatorContext != null
        ? MediaQuery.of(navigatorContext).size
        : const Size(1, 1);
    final origin = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      subject: subject,
      text: body,
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: _captureKey, child: widget.child);
  }
}
