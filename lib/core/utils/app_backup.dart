import 'dart:convert';

import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/domain/models/environment.dart';
import 'package:aun_postman/domain/models/history_entry.dart';
import 'package:aun_postman/domain/models/ws_saved_compose_message.dart';

/// Single-file backup of local app data (not Postman-compatible).
class AppBackup {
  AppBackup._();

  static const format = 'aun_postman_backup';
  static const version = 1;

  static String buildJson({
    required List<Collection> collections,
    required List<Environment> environments,
    required List<HistoryEntry> history,
    required List<WsSavedComposeMessage> wsSavedCompose,
    String? activeEnvironmentUid,
  }) {
    final map = <String, dynamic>{
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'activeEnvironmentUid': activeEnvironmentUid,
      'collections': collections.map((c) => c.toJson()).toList(),
      'environments': environments.map((e) => e.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
      'wsSavedCompose': wsSavedCompose.map((m) => m.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static AppBackupData parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup must be a JSON object');
    }
    if (decoded['format'] != format) {
      throw const FormatException('Not an Aun Postman backup file');
    }
    final v = decoded['version'];
    if (v is! int || v != version) {
      throw FormatException('Unsupported backup version: $v (need $version)');
    }

    final collections = _listOf(
      decoded['collections'],
      (m) => Collection.fromJson(Map<String, dynamic>.from(m as Map)),
    );
    final environments = _listOf(
      decoded['environments'],
      (m) => Environment.fromJson(Map<String, dynamic>.from(m as Map)),
    );
    final history = _listOf(
      decoded['history'],
      (m) => HistoryEntry.fromJson(Map<String, dynamic>.from(m as Map)),
    );
    final wsSavedCompose = _listOf(
      decoded['wsSavedCompose'],
      (m) =>
          WsSavedComposeMessage.fromJson(Map<String, dynamic>.from(m as Map)),
    );

    final activeUid = decoded['activeEnvironmentUid'] as String?;

    return AppBackupData(
      collections: collections,
      environments: environments,
      history: history,
      wsSavedCompose: wsSavedCompose,
      activeEnvironmentUid: activeUid,
    );
  }

  static List<T> _listOf<T>(dynamic raw, T Function(dynamic) parse) {
    if (raw == null) return [];
    if (raw is! List) return [];
    final out = <T>[];
    for (final e in raw) {
      try {
        out.add(parse(e));
      } catch (_) {
        // Skip malformed rows; rest of backup may still be useful.
      }
    }
    return out;
  }
}

class AppBackupData {
  const AppBackupData({
    required this.collections,
    required this.environments,
    required this.history,
    required this.wsSavedCompose,
    this.activeEnvironmentUid,
  });

  final List<Collection> collections;
  final List<Environment> environments;
  final List<HistoryEntry> history;
  final List<WsSavedComposeMessage> wsSavedCompose;
  final String? activeEnvironmentUid;
}
