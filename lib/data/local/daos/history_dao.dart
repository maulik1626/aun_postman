import 'dart:convert';

import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/domain/models/history_entry.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryDao {
  HistoryDao(this._box);
  final Box<String> _box;

  List<HistoryEntry> getAll() {
    final list = _box.values
        .map((raw) => _fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.executedAt.compareTo(a.executedAt));
    return list.take(AppConstants.maxHistoryEntries).toList();
  }

  Future<void> save(HistoryEntry entry) async {
    final map = {
      'uid': entry.uid,
      'request': entry.request.toJson(),
      'response': entry.response.toJson(),
      'executedAt': entry.executedAt.toIso8601String(),
      'variableSnapshot': entry.variableSnapshot,
    };
    await _box.put(entry.uid, jsonEncode(map));

    // Trim oldest entries beyond limit
    if (_box.length > AppConstants.maxHistoryEntries) {
      final all = getAll();
      final toDelete = all.skip(AppConstants.maxHistoryEntries).toList();
      for (final e in toDelete) {
        await _box.delete(e.uid);
      }
    }
  }

  Future<void> delete(String uid) => _box.delete(uid);

  Future<void> clearAll() => _box.clear();

  HistoryEntry _fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      uid: json['uid'] as String,
      request:
          HttpRequest.fromJson(json['request'] as Map<String, dynamic>),
      response:
          HttpResponse.fromJson(json['response'] as Map<String, dynamic>),
      executedAt: DateTime.parse(json['executedAt'] as String),
      variableSnapshot: _readStringMap(json['variableSnapshot']),
    );
  }

  static Map<String, String> _readStringMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }
}
