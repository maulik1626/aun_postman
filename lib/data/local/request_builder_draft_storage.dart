import 'dart:convert';

import 'package:aun_postman/data/local/request_builder_draft_codec.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed drafts for the request builder (one entry per route scope).
class RequestBuilderDraftStorage {
  RequestBuilderDraftStorage._();

  /// Stable key for [collectionUid] + optional [requestUid] / [folderUid].
  static String scopeKey({
    required String collectionUid,
    String? requestUid,
    String? folderUid,
  }) {
    final r = requestUid ?? 'new';
    final f = folderUid ?? '';
    return '$collectionUid|$r|$f';
  }

  static Future<void> save(
    Box<String> box,
    String scope,
    RequestBuilderState state,
  ) async {
    final envelope = {
      'scope': scope,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'state': RequestBuilderDraftCodec.encode(state),
    };
    await box.put(scope, jsonEncode(envelope));
  }

  /// Returns restored state only if [scope] matches and the draft is dirty.
  static RequestBuilderState? tryLoad(Box<String> box, String scope) {
    final raw = box.get(scope);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if ((map['scope'] as String?) != scope) return null;
      final stateMap = map['state'];
      if (stateMap is! Map) return null;
      final state = RequestBuilderDraftCodec.decode(
        Map<String, dynamic>.from(stateMap),
      );
      if (!state.isDirty) return null;
      return state;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(Box<String> box, String scope) async {
    await box.delete(scope);
  }
}
