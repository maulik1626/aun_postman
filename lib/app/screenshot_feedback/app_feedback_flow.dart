import 'dart:io';

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_navigator.dart';
import 'package:aun_reqstudio/app/screenshot_feedback/screenshot_feedback_email.dart';
import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/platform/feedback_device_info.dart';
import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class AppFeedbackDraft {
  const AppFeedbackDraft({required this.message, this.attachmentFile});

  final String message;
  final File? attachmentFile;

  bool get hasRequiredContent =>
      message.trim().isNotEmpty || attachmentFile != null;
}

class AppFeedbackFlow {
  AppFeedbackFlow._();

  static Future<void> showComposer({
    required BuildContext context,
    required WidgetRef ref,
    required bool useMaterial,
  }) async {
    final dialogContext = appRootNavigatorKey.currentContext ?? context;
    AppFeedbackDraft? draft;
    if (useMaterial) {
      // ignore: use_build_context_synchronously
      draft = await _showMaterialComposer(dialogContext);
    } else {
      // ignore: use_build_context_synchronously
      draft = await _showCupertinoComposer(dialogContext);
    }
    if (draft == null || !context.mounted) return;
    await sendDraft(context: context, ref: ref, draft: draft);
  }

  static Future<void> sendDraft({
    required BuildContext context,
    required WidgetRef ref,
    required AppFeedbackDraft draft,
  }) async {
    if (!draft.hasRequiredContent) {
      await _showNotice(
        context: context,
        title: 'Feedback unavailable',
        body: 'Add a message or attach an image before sending feedback.',
      );
      return;
    }

    final auth = ref.read(authControllerProvider);
    final deviceInfo = await FeedbackDeviceInfoResolver.resolve();
    if (!context.mounted) return;
    final payload = ScreenshotFeedbackEmailBuilder.build(
      authenticatedEmail: auth.user?.email,
      submittedAt: DateTime.now(),
      platformLabel: AppPlatform.isIOS ? 'iOS' : 'Android',
      deviceContext: ScreenshotFeedbackDeviceContext(
        deviceName: deviceInfo.deviceName,
        osLabel: deviceInfo.osLabel,
      ),
      feedbackMessage: draft.message,
    );

    try {
      await FlutterEmailSender.send(
        Email(
          subject: payload.subject,
          body: payload.body,
          recipients: const [ScreenshotFeedbackEmailBuilder.recipient],
          attachmentPaths: draft.attachmentFile != null
              ? [draft.attachmentFile!.path]
              : const <String>[],
        ),
      );
    } on MissingPluginException {
      if (!context.mounted) return;
      await _handleSendFailure(
        context: context,
        draft: draft,
        payload: payload,
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      await _handleSendFailure(
        context: context,
        draft: draft,
        payload: payload,
        canUseShareFallback: _shouldFallbackToShareSheet(
          error.code,
          error.message,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      await _handleSendFailure(
        context: context,
        draft: draft,
        payload: payload,
      );
    }
  }

  static Future<AppFeedbackDraft?> _showCupertinoComposer(
    BuildContext context,
  ) async {
    final controller = TextEditingController();
    File? attachmentFile;
    String? validationMessage;

    final result = await showCupertinoDialog<AppFeedbackDraft?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final bottomInset = MediaQuery.viewInsetsOf(dialogContext).bottom;
          final validationColor = CupertinoColors.systemRed.resolveFrom(
            dialogContext,
          );
          final hintColor = CupertinoColors.secondaryLabel.resolveFrom(
            dialogContext,
          );
          final filename = attachmentFile?.path
              .split(Platform.pathSeparator)
              .last;

          return Center(
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: CupertinoPopupSurface(
                    isSurfacePainted: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground.resolveFrom(
                          dialogContext,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.ctaEnd.withValues(alpha: 0.28),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Share feedback',
                              style: CupertinoTheme.of(
                                dialogContext,
                              ).textTheme.navTitleTextStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Report a bug or share product feedback. Add a clear description, an image, or both.',
                              style: CupertinoTheme.of(
                                dialogContext,
                              ).textTheme.textStyle.copyWith(color: hintColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            CupertinoTextField(
                              controller: controller,
                              maxLines: 6,
                              minLines: 4,
                              padding: const EdgeInsets.all(14),
                              textCapitalization: TextCapitalization.sentences,
                              placeholder:
                                  'Describe what happened and what you expected',
                              textInputAction: TextInputAction.newline,
                              decoration: BoxDecoration(
                                color: CupertinoColors.secondarySystemBackground
                                    .resolveFrom(dialogContext),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: validationMessage == null
                                      ? CupertinoColors.separator.resolveFrom(
                                          dialogContext,
                                        )
                                      : validationColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                final picked = await _pickAttachment();
                                if (picked == null) return;
                                setState(() {
                                  attachmentFile = picked;
                                  validationMessage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors
                                      .secondarySystemBackground
                                      .resolveFrom(dialogContext),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: CupertinoColors.separator
                                        .resolveFrom(dialogContext),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.paperclip),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        attachmentFile == null
                                            ? 'Attach image'
                                            : 'Replace image',
                                        style: CupertinoTheme.of(
                                          dialogContext,
                                        ).textTheme.textStyle,
                                      ),
                                    ),
                                    Text(
                                      attachmentFile == null ? 'Optional' : '',
                                      style: CupertinoTheme.of(dialogContext)
                                          .textTheme
                                          .textStyle
                                          .copyWith(
                                            color: hintColor,
                                            fontSize: 13,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (attachmentFile != null) ...[
                              const SizedBox(height: 12),
                              _CupertinoFeedbackImagePreview(
                                file: attachmentFile!,
                                filename: filename!,
                                onRemove: () {
                                  setState(() {
                                    attachmentFile = null;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              validationMessage ??
                                  'Include a message or an image so the team has enough context to investigate.',
                              style: CupertinoTheme.of(dialogContext)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    color: validationMessage == null
                                        ? hintColor
                                        : validationColor,
                                    fontSize: 12,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton(
                                    color: CupertinoColors.tertiarySystemFill
                                        .resolveFrom(dialogContext),
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppGradientButton(
                                    fullWidth: true,
                                    onPressed: () {
                                      final draft = AppFeedbackDraft(
                                        message: controller.text.trim(),
                                        attachmentFile: attachmentFile,
                                      );
                                      if (!draft.hasRequiredContent) {
                                        setState(() {
                                          validationMessage =
                                              'Please add a message or attach an image.';
                                        });
                                        return;
                                      }
                                      Navigator.of(dialogContext).pop(draft);
                                    },
                                    child: const Text('Send'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    controller.dispose();
    return result;
  }

  static Future<AppFeedbackDraft?> _showMaterialComposer(
    BuildContext context,
  ) async {
    final controller = TextEditingController();
    File? attachmentFile;
    String? validationMessage;

    final result = await showDialog<AppFeedbackDraft?>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final theme = Theme.of(dialogContext);
          final bottomInset = MediaQuery.viewInsetsOf(dialogContext).bottom;
          final filename = attachmentFile?.path
              .split(Platform.pathSeparator)
              .last;

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
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.feedback_outlined),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Share feedback',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Help us investigate faster with a short description and an optional screenshot.',
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
                      TextField(
                        controller: controller,
                        maxLines: 6,
                        minLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: 'Describe the issue',
                          hintText:
                              'What did you try, what happened, and what should have happened instead?',
                          helperText:
                              'A message or image is required before sending.',
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                          errorText: validationMessage,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await _pickAttachment();
                          if (picked == null) return;
                          setState(() {
                            attachmentFile = picked;
                            validationMessage = null;
                          });
                        },
                        icon: const Icon(Icons.attach_file_rounded),
                        label: Text(
                          attachmentFile == null
                              ? 'Attach image'
                              : 'Replace image',
                        ),
                      ),
                      if (attachmentFile != null) ...[
                        const SizedBox(height: 14),
                        _MaterialFeedbackImagePreview(
                          file: attachmentFile!,
                          filename: filename!,
                          onRemove: () {
                            setState(() {
                              attachmentFile = null;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppGradientButton.material(
                              fullWidth: true,
                              onPressed: () {
                                final draft = AppFeedbackDraft(
                                  message: controller.text.trim(),
                                  attachmentFile: attachmentFile,
                                );
                                if (!draft.hasRequiredContent) {
                                  setState(() {
                                    validationMessage =
                                        'Please add a message or attach an image.';
                                  });
                                  return;
                                }
                                Navigator.of(dialogContext).pop(draft);
                              },
                              child: const Text('Send'),
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
      ),
    );
    controller.dispose();
    return result;
  }

  static Future<File?> _pickAttachment() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  static Future<void> _handleSendFailure({
    required BuildContext context,
    required AppFeedbackDraft draft,
    required ScreenshotFeedbackEmailPayload payload,
    bool canUseShareFallback = true,
  }) async {
    if (canUseShareFallback) {
      final didShare = await _tryShareFallback(draft: draft, payload: payload);
      if (didShare) return;
    }

    if (!context.mounted) return;
    await _showNotice(
      context: context,
      title: 'Email unavailable',
      body:
          'We prepared your feedback, but could not open an email app. Please make sure one is set up, then try again.',
    );
  }

  static Future<bool> _tryShareFallback({
    required AppFeedbackDraft draft,
    required ScreenshotFeedbackEmailPayload payload,
  }) async {
    try {
      if (draft.attachmentFile != null) {
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
          [XFile(draft.attachmentFile!.path, mimeType: 'image/png')],
          subject: payload.subject,
          text: payload.body,
          sharePositionOrigin: origin,
        );
      } else {
        await Share.share(payload.body, subject: payload.subject);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showNotice({
    required BuildContext context,
    required String title,
    required String body,
  }) async {
    try {
      if (AppPlatform.isAndroid) {
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
      }

      if (!context.mounted) return;
      await UserNotification.show(context: context, title: title, body: body);
    } catch (_) {
      // Surface nothing if the fallback notice itself fails.
    }
  }

  static bool _shouldFallbackToShareSheet(String code, String? message) {
    final lowerCode = code.toLowerCase();
    final lowerMessage = (message ?? '').toLowerCase();
    return lowerCode == 'not_available' ||
        lowerCode == 'error' ||
        lowerMessage.contains('not available') ||
        lowerMessage.contains('no mail account') ||
        lowerMessage.contains('no email app');
  }
}

class _MaterialFeedbackImagePreview extends StatelessWidget {
  const _MaterialFeedbackImagePreview({
    required this.file,
    required this.filename,
    required this.onRemove,
  });

  final File file;
  final String filename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachment preview',
                      style: theme.textTheme.labelLarge,
                    ),
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
              ),
              IconButton(
                tooltip: 'Remove image',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CupertinoFeedbackImagePreview extends StatelessWidget {
  const _CupertinoFeedbackImagePreview({
    required this.file,
    required this.filename,
    required this.onRemove,
  });

  final File file;
  final String filename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hintColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachment preview',
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CupertinoTheme.of(context).textTheme.textStyle
                          .copyWith(color: hintColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                minSize: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                onPressed: onRemove,
                child: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
