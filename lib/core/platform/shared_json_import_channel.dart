import 'dart:async';
import 'dart:collection';

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/core/services/crashlytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharedJsonImportPayload {
  const SharedJsonImportPayload({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.action,
  });

  final String path;
  final String fileName;
  final String mimeType;
  final String action;

  static SharedJsonImportPayload? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final path = raw['path'] as String?;
    if (path == null || path.isEmpty) return null;
    return SharedJsonImportPayload(
      path: path,
      fileName: (raw['fileName'] as String?)?.trim().isNotEmpty == true
          ? (raw['fileName'] as String).trim()
          : 'shared.json',
      mimeType: (raw['mimeType'] as String?)?.trim().isNotEmpty == true
          ? (raw['mimeType'] as String).trim()
          : 'application/json',
      action: (raw['action'] as String?)?.trim().isNotEmpty == true
          ? (raw['action'] as String).trim()
          : 'shared',
    );
  }
}

class SharedJsonImportCoordinator extends ChangeNotifier {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.aun.reqstudio/shared_json_import',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.aun.reqstudio/shared_json_import/events',
  );

  final Queue<SharedJsonImportPayload> _pending = Queue();
  StreamSubscription<dynamic>? _eventSubscription;
  bool _initialized = false;

  bool get hasPending => _pending.isNotEmpty;

  SharedJsonImportPayload? consumeNext() {
    if (_pending.isEmpty) return null;
    final next = _pending.removeFirst();
    notifyListeners();
    return next;
  }

  Future<void> initialize() async {
    if (_initialized || (!AppPlatform.isAndroid && !AppPlatform.isIOS)) return;
    _initialized = true;

    try {
      final initial = SharedJsonImportPayload.fromMap(
        await _methodChannel.invokeMethod<dynamic>('getInitialSharedJson'),
      );
      if (initial != null) {
        _enqueue(initial);
      }
    } catch (error, stackTrace) {
      await CrashlyticsService.recordError(
        error,
        stackTrace,
        reason: 'Failed to fetch initial shared JSON payload',
      );
    }

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        final payload = SharedJsonImportPayload.fromMap(event);
        if (payload != null) {
          _enqueue(payload);
        }
      },
      onError: (Object error, StackTrace stackTrace) async {
        await CrashlyticsService.recordError(
          error,
          stackTrace,
          reason: 'Shared JSON import event stream failed',
        );
      },
    );
  }

  void _enqueue(SharedJsonImportPayload payload) {
    final alreadyQueued = _pending.any(
      (item) =>
          item.path == payload.path &&
          item.fileName == payload.fileName &&
          item.action == payload.action,
    );
    if (alreadyQueued) return;
    _pending.add(payload);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    super.dispose();
  }
}

final sharedJsonImportCoordinatorProvider =
    Provider<SharedJsonImportCoordinator>((ref) {
      final coordinator = SharedJsonImportCoordinator();
      ref.onDispose(coordinator.dispose);
      return coordinator;
    });
