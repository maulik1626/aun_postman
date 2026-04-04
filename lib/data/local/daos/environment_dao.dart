import 'dart:convert';

import 'package:aun_postman/domain/models/environment.dart';
import 'package:aun_postman/domain/models/environment_variable.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EnvironmentDao {
  EnvironmentDao(this._envBox, this._varBox);
  final Box<String> _envBox;
  final Box<String> _varBox;

  List<Environment> getAll() {
    return _envBox.values
        .map((raw) => _fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Environment? getActive() {
    try {
      return getAll().firstWhere((e) => e.isActive);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(Environment env) async {
    // Delete old variables for this env then re-write
    final oldVarKeys = _varBox.keys
        .where((k) => (k as String).startsWith('${env.uid}:'))
        .toList();
    for (final k in oldVarKeys) {
      await _varBox.delete(k);
    }

    for (final v in env.variables) {
      final map = {
        'uid': v.uid,
        'environmentUid': env.uid,
        'key': v.key,
        'value': v.value,
        'isEnabled': v.isEnabled,
        'isSecret': v.isSecret,
      };
      await _varBox.put('${env.uid}:${v.uid}', jsonEncode(map));
    }

    final map = {
      'uid': env.uid,
      'name': env.name,
      'isActive': env.isActive,
      'variableUids': env.variables.map((v) => v.uid).toList(),
      'createdAt': env.createdAt.toIso8601String(),
      'updatedAt': env.updatedAt.toIso8601String(),
    };
    await _envBox.put(env.uid, jsonEncode(map));
  }

  Future<void> setActive(String uid) async {
    final all = getAll();
    for (final env in all) {
      if (env.isActive != (env.uid == uid)) {
        await upsert(env.copyWith(isActive: env.uid == uid));
      }
    }
  }

  Future<void> clearActive() async {
    final all = getAll();
    for (final env in all.where((e) => e.isActive)) {
      await upsert(env.copyWith(isActive: false));
    }
  }

  Future<void> delete(String uid) async {
    final oldVarKeys = _varBox.keys
        .where((k) => (k as String).startsWith('$uid:'))
        .toList();
    for (final k in oldVarKeys) {
      await _varBox.delete(k);
    }
    await _envBox.delete(uid);
  }

  Environment _fromJson(Map<String, dynamic> json) {
    final uid = json['uid'] as String;
    final varUids =
        (json['variableUids'] as List? ?? []).cast<String>();

    final variables = varUids
        .map((varUid) {
          final raw = _varBox.get('$uid:$varUid');
          if (raw == null) return null;
          final vJson = jsonDecode(raw) as Map<String, dynamic>;
          return EnvironmentVariable(
            uid: vJson['uid'] as String,
            key: vJson['key'] as String,
            value: vJson['value'] as String? ?? '',
            isEnabled: vJson['isEnabled'] as bool? ?? true,
            isSecret: vJson['isSecret'] as bool? ?? false,
          );
        })
        .whereType<EnvironmentVariable>()
        .toList();

    return Environment(
      uid: uid,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? false,
      variables: variables,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
