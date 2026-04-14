import 'dart:async';
import 'dart:io';

import 'package:aun_reqstudio/core/platform/icloud_backup_channel.dart';
import 'package:aun_reqstudio/core/utils/full_backup_json.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// When [AppSettingsState.icloudAutoBackup] is on (iOS), pushes a full backup
/// to iCloud shortly after the app goes inactive (debounced).
class IcloudAutoBackupObserver extends ConsumerStatefulWidget {
  const IcloudAutoBackupObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<IcloudAutoBackupObserver> createState() =>
      _IcloudAutoBackupObserverState();
}

class _IcloudAutoBackupObserverState extends ConsumerState<IcloudAutoBackupObserver>
    with WidgetsBindingObserver {
  DateTime? _lastPush;
  Timer? _debounce;

  static const _minInterval = Duration(minutes: 2);
  static const _debounceDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused) {
      return;
    }
    if (!Platform.isIOS) return;
    if (!ref.read(appSettingsProvider).icloudAutoBackup) return;

    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      unawaited(_pushIfNeeded());
    });
  }

  Future<void> _pushIfNeeded() async {
    if (!IcloudBackupChannel.platformSupported) return;
    if (!ref.read(appSettingsProvider).icloudAutoBackup) return;

    final now = DateTime.now();
    if (_lastPush != null && now.difference(_lastPush!) < _minInterval) {
      return;
    }

    final available = await IcloudBackupChannel.isAvailable();
    if (!available || !mounted) return;

    try {
      final json = await buildFullBackupJson(ref);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/aun_reqstudio_autosave_${now.millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json);
      await IcloudBackupChannel.copyFileToICloud(file.path);
      await file.delete();
      _lastPush = now;
    } catch (_) {
      // Silent — user can still export manually; avoids notification spam.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
