import 'dart:async';

import 'package:aun_reqstudio/app/app.dart';
import 'package:aun_reqstudio/app/icloud_auto_backup_observer.dart';
import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/services/ad_service.dart';
import 'package:aun_reqstudio/core/services/crashlytics_service.dart';
import 'package:aun_reqstudio/data/local/hive_service.dart';
import 'package:aun_reqstudio/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrintStack(
          label: 'Flutter framework error: ${details.exceptionAsString()}',
          stackTrace: details.stack,
        );
        unawaited(CrashlyticsService.recordFlutterFatalError(details));
      };

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await CrashlyticsService.initialize();

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(
          CrashlyticsService.recordError(
            error,
            stackTrace,
            reason: 'PlatformDispatcher error',
            fatal: true,
          ),
        );
        return true;
      };

      try {
        // Open all Hive boxes before the first frame.
        await initHive();
        await CrashlyticsService.log('Hive initialized.');
        if (AppConstants.enableAds) {
          await AdService.instance.initialize();
        }

        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await UserNotification.init();
        }

        // iCloud auto-backup observer is iOS-only.
        const app = App();
        final root = AppPlatform.isIOS
            ? const IcloudAutoBackupObserver(child: app)
            : app;

        runApp(ProviderScope(child: root));
      } catch (error, stackTrace) {
        await CrashlyticsService.recordError(
          error,
          stackTrace,
          reason: 'App startup failure',
          fatal: true,
        );
        debugPrint('Startup failure: $error');
        debugPrintStack(stackTrace: stackTrace);
        runApp(StartupFailureApp(error: error));
      }
    },
    (error, stackTrace) async {
      await CrashlyticsService.recordError(
        error,
        stackTrace,
        reason: 'Uncaught zone error',
        fatal: true,
      );
    },
  );
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFF101010),
      debugShowCheckedModeBanner: false,
      builder: (context, _) => ColoredBox(
        color: const Color(0xFFF6F6F6),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DefaultTextStyle(
                style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '!',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB3261E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'App startup failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text('$error', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
