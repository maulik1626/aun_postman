import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// iOS-only: presents errors (and short info) as system-style local notifications.
///
/// Banners follow the device appearance (including dark mode). There is no
/// in-app colored snackbar; if alerts are disabled, a [CupertinoAlertDialog]
/// is used when [context] is provided.
class UserNotification {
  UserNotification._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static int _id = 0;

  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (_initialized) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestSoundPermission: true,
          requestBadgePermission: false,
          defaultPresentBanner: true,
          defaultPresentList: true,
          defaultPresentSound: true,
          defaultPresentBadge: false,
        ),
      ),
    );

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: false, sound: true);

    _initialized = true;
  }

  /// Shows a banner, or [fallbackDialog] if the user has not granted alerts.
  static Future<void> show({
    required String title,
    required String body,
    BuildContext? context,
  }) async {
    final ctx = context;

    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      await _fallbackDialog(ctx, title, body);
      return;
    }

    if (!_initialized) await init();
    if (ctx != null && !ctx.mounted) return;

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final perms = await ios?.checkPermissions();
    if (ctx != null && !ctx.mounted) return;

    final canBanner = perms != null &&
        (perms.isAlertEnabled || perms.isProvisionalEnabled);

    final text = body.length > 350 ? '${body.substring(0, 347)}…' : body;

    if (canBanner) {
      _id = (_id + 1) % 0x3FFFFFFF;
      await _plugin.show(
        id: _id,
        title: title,
        body: text,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentBanner: true,
            presentList: true,
            presentSound: true,
            presentBadge: false,
            threadIdentifier: 'aun_postman_user',
          ),
        ),
      );
    } else {
      if (ctx != null && !ctx.mounted) return;
      await _fallbackDialog(ctx, title, text);
    }
  }

  static Future<void> _fallbackDialog(
    BuildContext? context,
    String title,
    String body,
  ) async {
    if (context == null || !context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
