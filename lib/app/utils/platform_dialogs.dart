import 'package:aun_reqstudio/app/platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A single action entry for [showAppAlert] and [showAppActionSheet].
class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Renders red on both platforms.
  final bool isDestructive;

  /// Bold on iOS; has no extra styling on Material (use sparingly).
  final bool isDefault;
}

// ── Alert dialog ─────────────────────────────────────────────────────────────

/// Shows a platform-native alert:
/// - iOS → [CupertinoAlertDialog]
/// - Android → [AlertDialog] (Material 3)
Future<void> showAppAlert({
  required BuildContext context,
  required String title,
  String? message,
  required List<AppDialogAction> actions,
}) {
  if (AppPlatform.isIOS) {
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: message != null ? Text(message) : null,
        actions: actions
            .map(
              (a) => CupertinoDialogAction(
                isDestructiveAction: a.isDestructive,
                isDefaultAction: a.isDefault,
                onPressed: a.onPressed,
                child: Text(a.label),
              ),
            )
            .toList(),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message != null ? Text(message) : null,
      actions: actions
          .map(
            (a) => TextButton(
              style: a.isDestructive
                  ? TextButton.styleFrom(foregroundColor: Colors.red)
                  : null,
              onPressed: a.onPressed,
              child: Text(a.label),
            ),
          )
          .toList(),
    ),
  );
}

// ── Action sheet / bottom sheet ───────────────────────────────────────────────

/// Shows a platform-native action sheet:
/// - iOS → [CupertinoActionSheet]
/// - Android → modal bottom sheet with [ListTile] actions (Material 3)
///
/// Returns the result of type [T] passed via [Navigator.pop].
Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<AppDialogAction> actions,
  String cancelLabel = 'Cancel',
}) {
  if (AppPlatform.isIOS) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: title != null ? Text(title) : null,
        message: message != null ? Text(message) : null,
        actions: actions
            .map(
              (a) => CupertinoActionSheetAction(
                isDestructiveAction: a.isDestructive,
                isDefaultAction: a.isDefault,
                onPressed: a.onPressed ?? () {},
                child: Text(a.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(cancelLabel),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                message,
                style: Theme.of(ctx).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          const Divider(height: 1),
          ...actions.map(
            (a) => ListTile(
              title: Text(
                a.label,
                style: a.isDestructive
                    ? const TextStyle(color: Colors.red)
                    : null,
              ),
              onTap: a.onPressed,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(
              cancelLabel,
              style: Theme.of(
                ctx,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            onTap: () => Navigator.of(ctx).pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
