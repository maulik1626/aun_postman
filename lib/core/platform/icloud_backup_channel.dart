import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS iCloud Documents bridge — writes a single full-backup JSON in the app’s
/// ubiquity container (`com.aun_postman/icloud_backup` MethodChannel).
class IcloudBackupChannel {
  IcloudBackupChannel._();

  static const _name = 'com.aun_postman/icloud_backup';
  static const MethodChannel _ch = MethodChannel(_name);

  static bool get platformSupported => !kIsWeb && Platform.isIOS;

  static Future<bool> isAvailable() async {
    if (!platformSupported) return false;
    try {
      final v = await _ch.invokeMethod<bool>('isAvailable');
      return v == true;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> backupExists() async {
    if (!platformSupported) return false;
    try {
      final v = await _ch.invokeMethod<bool>('backupExists');
      return v == true;
    } on MissingPluginException {
      return false;
    }
  }

  /// Milliseconds since epoch, or null if missing / error.
  static Future<double?> backupModifiedMsSinceEpoch() async {
    if (!platformSupported) return null;
    try {
      final v = await _ch.invokeMethod<dynamic>('backupModifiedMsSinceEpoch');
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Copies a local file (e.g. temp JSON) into the fixed iCloud backup slot.
  static Future<void> copyFileToICloud(String localPath) async {
    if (!platformSupported) {
      throw IcloudBackupException('iCloud backup is only supported on iOS.');
    }
    try {
      await _ch.invokeMethod<void>('copyToICloud', {'path': localPath});
    } on PlatformException catch (e) {
      throw IcloudBackupException(e.message ?? e.code);
    } on MissingPluginException {
      throw IcloudBackupException('iCloud plugin is not available.');
    }
  }

  /// Returns a temp file path in the app sandbox, or null if no iCloud backup exists.
  static Future<String?> copyFromICloudToTempPath() async {
    if (!platformSupported) return null;
    try {
      return await _ch.invokeMethod<String>('copyFromICloudToTemp');
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      throw IcloudBackupException(e.message ?? e.code);
    }
  }
}

class IcloudBackupException implements Exception {
  IcloudBackupException(this.message);
  final String message;

  @override
  String toString() => message;
}
