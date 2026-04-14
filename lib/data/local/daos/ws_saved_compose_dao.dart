import 'dart:convert';

import 'package:aun_reqstudio/domain/models/ws_saved_compose_message.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WsSavedComposeDao {
  WsSavedComposeDao(this._box);
  final Box<String> _box;

  List<WsSavedComposeMessage> getAll() {
    return _box.values
        .map((raw) => WsSavedComposeMessage.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> upsert(WsSavedComposeMessage message) async {
    await _box.put(message.uid, jsonEncode(message.toJson()));
  }

  Future<void> delete(String uid) async {
    await _box.delete(uid);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
