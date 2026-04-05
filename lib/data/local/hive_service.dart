import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hive_service.g.dart';

/// Box names used throughout the app.
class HiveBoxes {
  HiveBoxes._();

  static const String collections = 'collections';
  static const String folders = 'folders';
  static const String requests = 'requests';
  static const String history = 'history';
  static const String environments = 'environments';
  static const String envVariables = 'env_variables';
  static const String wsSavedCompose = 'ws_saved_compose';
  static const String requestBuilderDrafts = 'request_builder_drafts';
}

/// Initialises Hive and opens all boxes. Called once at app startup.
Future<void> initHive() async {
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<String>(HiveBoxes.collections),
    Hive.openBox<String>(HiveBoxes.folders),
    Hive.openBox<String>(HiveBoxes.requests),
    Hive.openBox<String>(HiveBoxes.history),
    Hive.openBox<String>(HiveBoxes.environments),
    Hive.openBox<String>(HiveBoxes.envVariables),
    Hive.openBox<String>(HiveBoxes.wsSavedCompose),
    Hive.openBox<String>(HiveBoxes.requestBuilderDrafts),
  ]);
}

/// Provider that exposes a named Hive box of JSON strings.
/// Boxes are opened during [initHive] at app start so this is always sync.
@Riverpod(keepAlive: true)
Box<String> hiveBox(HiveBoxRef ref, String boxName) {
  return Hive.box<String>(boxName);
}
