import 'package:aun_postman/app/app.dart';
import 'package:aun_postman/app/icloud_auto_backup_observer.dart';
import 'package:aun_postman/core/notifications/user_notification.dart';
import 'package:aun_postman/data/local/hive_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open all Hive boxes before the first frame.
  await initHive();

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await UserNotification.init();
  }

  runApp(
    const ProviderScope(
      child: IcloudAutoBackupObserver(
        child: App(),
      ),
    ),
  );
}
