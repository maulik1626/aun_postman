import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// iOS-only: presents errors (and short info) as system-style local notifications.
///
/// Banners follow the device appearance (including dark mode). There is no
/// in-app colored snackbar; if alerts are disabled, a [CupertinoAlertDialog]
/// is used when [context] is provided.
class UserNotification {
  UserNotification._();

  static const String browseAdsExtendPayload = 'browse_ads_extend';
  static const int _browseAdsReminderId = 71001;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final ValueNotifier<String?> notificationTapPayload =
      ValueNotifier<String?>(null);

  static bool _initialized = false;
  static int _id = 0;
  static bool _timezoneInitialized = false;
  static String? _launchPayload;

  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (_initialized) return;

    if (!_timezoneInitialized) {
      tz_data.initializeTimeZones();
      _timezoneInitialized = true;
    }

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
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        notificationTapPayload.value = payload;
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.isNotEmpty) {
      _launchPayload = payload;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: false, sound: true);

    _initialized = true;
  }

  static String? consumeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
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

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final perms = await ios?.checkPermissions();
    if (ctx != null && !ctx.mounted) return;

    final canBanner =
        perms != null && (perms.isAlertEnabled || perms.isProvisionalEnabled);

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
            threadIdentifier: 'aun_reqstudio_user',
          ),
        ),
      );
    } else {
      if (ctx != null && !ctx.mounted) return;
      await _fallbackDialog(ctx, title, text);
    }
  }

  static Future<void> scheduleBrowseAdsExpiryReminder({
    required DateTime pausedUntil,
    required int extensionMinutes,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!_initialized) await init();

    final remindAt = pausedUntil.subtract(const Duration(minutes: 1));
    if (!remindAt.isAfter(DateTime.now())) {
      await cancelBrowseAdsExpiryReminder();
      return;
    }

    await _plugin.zonedSchedule(
      id: _browseAdsReminderId,
      title: 'Ad pause ending soon',
      body:
          'Ad pause expires in 1 min. Rewatch to extend for another $extensionMinutes mins.',
      scheduledDate: tz.TZDateTime.from(remindAt.toUtc(), tz.UTC),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentBanner: true,
          presentList: true,
          presentSound: true,
          presentBadge: false,
          threadIdentifier: 'aun_reqstudio_user',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: browseAdsExtendPayload,
    );
  }

  static Future<void> cancelBrowseAdsExpiryReminder() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!_initialized) await init();
    await _plugin.cancel(id: _browseAdsReminderId);
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
