import 'package:aun_reqstudio/app/app.dart';
import 'package:aun_reqstudio/app/icloud_auto_backup_observer.dart';
import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/data/local/hive_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open all Hive boxes before the first frame.
  await initHive();

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await UserNotification.init();
  }

  // iCloud auto-backup observer is iOS-only.
  const app = App();
  final root = AppPlatform.isIOS
      ? const IcloudAutoBackupObserver(child: app)
      : app;

  runApp(ProviderScope(child: root));
}
