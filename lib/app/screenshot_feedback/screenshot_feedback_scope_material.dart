import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_navigator.dart';
import 'package:aun_reqstudio/app/screenshot_feedback/screenshot_feedback_email.dart';
import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/core/platform/feedback_device_info.dart';
import 'package:aun_reqstudio/core/platform/screenshot_event_channel.dart';
import 'package:aun_reqstudio/core/services/crashlytics_service.dart';
import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScreenshotFeedbackScopeMaterial extends ConsumerStatefulWidget {
  const ScreenshotFeedbackScopeMaterial({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ScreenshotFeedbackScopeMaterial> createState() =>
      _ScreenshotFeedbackScopeMaterialState();
}

class _ScreenshotFeedbackScopeMaterialState
    extends ConsumerState<ScreenshotFeedbackScopeMaterial> {
  final GlobalKey _captureKey = GlobalKey();
  StreamSubscription<ScreenshotTakenEvent>? _subscription;
  bool _isHandlingScreenshot = false;
  DateTime? _lastHandledAt;

  @override
  void initState() {
    super.initState();
    if (AppConstants.enableScreenshotFeedbackTrigger) {
      _subscription = ScreenshotEventChannel.events().listen(_handleScreenshot);
    }
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
        await _reportScreenshotFeedbackFailure(
          'capture_returned_null',
          event: event,
        );
        await _showFeedbackNotice(
          title: 'Screenshot unavailable',
          body:
              'We could not prepare the screenshot for feedback. Please try again.',
        );
        return;
      }

      final feedbackMessage = await _showFeedbackDialog(screenshotFile);
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
    } on MissingPluginException catch (error, stackTrace) {
      await _reportScreenshotFeedbackFailure(
        'missing_plugin',
        error: error,
        stackTrace: stackTrace,
        event: event,
      );
      await _handleEmailFailure(
        screenshotFile: screenshotFile,
        payload: payload,
      );
    } on PlatformException catch (error, stackTrace) {
      await _reportScreenshotFeedbackFailure(
        'platform_exception',
        error: error,
        stackTrace: stackTrace,
        event: event,
      );
      await _handleEmailFailure(
        screenshotFile: screenshotFile,
        payload: payload,
        canUseShareFallback: _shouldFallbackToShareSheet(
          error.code,
          error.message,
        ),
      );
    } catch (error, stackTrace) {
      await _reportScreenshotFeedbackFailure(
        'unexpected_exception',
        error: error,
        stackTrace: stackTrace,
        event: event,
      );
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
    final keyboardInset = MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0;
    final image = await _captureBoundaryImage(pixelRatio);
    if (image == null) return null;
    final normalizedImage = await _normalizeCapturedImage(
      image: image,
      pixelRatio: pixelRatio,
      keyboardInset: keyboardInset,
    );
    final bytes = await normalizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
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
    await Future<void>.delayed(const Duration(milliseconds: 180));
    for (var attempt = 0; attempt < 20; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null && !boundary.debugNeedsPaint) {
        try {
          return await boundary.toImage(pixelRatio: pixelRatio);
        } catch (_) {
          // iOS posts the screenshot notification before Flutter is always ready
          // to rasterize the current frame, especially in optimized builds.
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }

  Future<ui.Image> _normalizeCapturedImage({
    required ui.Image image,
    required double pixelRatio,
    required double keyboardInset,
  }) async {
    final cropHeight = _croppedImageHeight(
      imageHeight: image.height,
      pixelRatio: pixelRatio,
      keyboardInset: keyboardInset,
    );
    if (cropHeight == image.height) {
      return image;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), cropHeight.toDouble()),
      Rect.fromLTWH(0, 0, image.width.toDouble(), cropHeight.toDouble()),
      Paint(),
    );
    return recorder.endRecording().toImage(image.width, cropHeight);
  }

  int _croppedImageHeight({
    required int imageHeight,
    required double pixelRatio,
    required double keyboardInset,
  }) {
    if (keyboardInset <= 0) return imageHeight;
    final croppedHeight = imageHeight - (keyboardInset * pixelRatio).round();
    return math.max(1, math.min(imageHeight, croppedHeight));
  }

  Future<void> _reportScreenshotFeedbackFailure(
    String stage, {
    ScreenshotTakenEvent? event,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final info = <Object>[
      'scope=material',
      'platform=${event?.platform ?? (AppPlatform.isIOS ? 'ios' : 'android')}',
      'eventTakenAt=${event?.takenAt.toIso8601String() ?? 'unknown'}',
      'keyboardInset=${MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0}',
      'mounted=$mounted',
    ];
    await CrashlyticsService.recordError(
      error ?? StateError('Screenshot feedback failed at $stage'),
      stackTrace ?? StackTrace.current,
      reason: 'screenshot_feedback_$stage',
      information: info,
    );
  }

  Future<String?> _showFeedbackDialog(File screenshotFile) async {
    final navigatorContext = appRootNavigatorKey.currentContext;
    if (navigatorContext == null) return null;
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: navigatorContext,
      useRootNavigator: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final bottomInset = MediaQuery.viewInsetsOf(dialogContext).bottom;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: AppColors.ctaEnd.withValues(alpha: 0.35)),
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.bug_report_outlined),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share screenshot',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The current screen will be attached automatically so support gets the full context.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ScreenshotFeedbackPreviewMaterial(file: screenshotFile),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 6,
                      minLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Describe the issue',
                        hintText:
                            'Optional: explain what you were doing and what felt wrong.',
                        helperText: 'Optional',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(null),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppGradientButton.material(
                            fullWidth: true,
                            onPressed: () => Navigator.of(
                              dialogContext,
                            ).pop(controller.text.trim()),
                            child: const Text('Send feedback'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: subject,
        text: body,
      );
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
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('$title\n$body'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
        lowerMessage.contains('no mail account') ||
        lowerMessage.contains('no email app');
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: _captureKey, child: widget.child);
  }
}

class _ScreenshotFeedbackPreviewMaterial extends StatelessWidget {
  const _ScreenshotFeedbackPreviewMaterial({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filename = file.path.split(Platform.pathSeparator).last;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Text('Attachment preview', style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(
            filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
