import 'dart:convert';

import 'package:aun_postman/domain/enums/http_method.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/domain/models/folder.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:aun_postman/domain/models/test_assertion.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists [Collection] objects (and their [Folder]s and [HttpRequest]s)
/// as JSON strings in three separate Hive boxes keyed by UID.
class CollectionDao {
  CollectionDao(this._collections, this._folders, this._requests);

  final Box<String> _collections;
  final Box<String> _folders;
  final Box<String> _requests;

  // ── Reads ────────────────────────────────────────────────────────────────

  List<Collection> getAll() {
    final list = _collections.values
        .map((json) => _collectionFromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Collection? getByUid(String uid) {
    final raw = _collections.get(uid);
    if (raw == null) return null;
    return _collectionFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  Future<void> upsert(Collection collection) async {
    // Persist direct requests
    for (final req in collection.requests) {
      await _requests.put(req.uid, jsonEncode(_requestToJson(req)));
    }
    // Persist folders (recursively)
    for (final folder in collection.folders) {
      await _upsertFolder(folder);
    }
    // Persist the collection header (without inline requests/folders to avoid
    // duplication — we reconstruct them from their own boxes at read time)
    final header = {
      'uid': collection.uid,
      'name': collection.name,
      'description': collection.description,
      'sortOrder': collection.sortOrder,
      'auth': collection.auth.toJson(),
      'requestUids': collection.requests.map((r) => r.uid).toList(),
      'folderUids': collection.folders.map((f) => f.uid).toList(),
      'createdAt': collection.createdAt.toIso8601String(),
      'updatedAt': collection.updatedAt.toIso8601String(),
    };
    await _collections.put(collection.uid, jsonEncode(header));
  }

  Future<void> delete(String uid) async {
    final raw = _collections.get(uid);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    // Delete direct requests
    for (final reqUid in (json['requestUids'] as List? ?? [])) {
      await _requests.delete(reqUid as String);
    }
    // Delete folders (and their requests)
    for (final folderUid in (json['folderUids'] as List? ?? [])) {
      await _deleteFolder(folderUid as String);
    }
    await _collections.delete(uid);
  }

  Future<void> updateSortOrders(List<String> orderedUids) async {
    for (int i = 0; i < orderedUids.length; i++) {
      final raw = _collections.get(orderedUids[i]);
      if (raw == null) continue;
      final map = Map<String, dynamic>.from(
          jsonDecode(raw) as Map<String, dynamic>);
      map['sortOrder'] = i;
      await _collections.put(orderedUids[i], jsonEncode(map));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _upsertFolder(Folder folder) async {
    for (final req in folder.requests) {
      await _requests.put(req.uid, jsonEncode(_requestToJson(req)));
    }
    for (final sub in folder.subFolders) {
      await _upsertFolder(sub);
    }
    final header = {
      'uid': folder.uid,
      'name': folder.name,
      'collectionUid': folder.collectionUid,
      'parentFolderUid': folder.parentFolderUid,
      'sortOrder': folder.sortOrder,
      'requestUids': folder.requests.map((r) => r.uid).toList(),
      'subFolderUids': folder.subFolders.map((f) => f.uid).toList(),
      'createdAt': folder.createdAt.toIso8601String(),
      'updatedAt': folder.updatedAt.toIso8601String(),
    };
    await _folders.put(folder.uid, jsonEncode(header));
  }

  Future<void> _deleteFolder(String uid) async {
    final raw = _folders.get(uid);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    for (final reqUid in (json['requestUids'] as List? ?? [])) {
      await _requests.delete(reqUid as String);
    }
    for (final subUid in (json['subFolderUids'] as List? ?? [])) {
      await _deleteFolder(subUid as String);
    }
    await _folders.delete(uid);
  }

  Collection _collectionFromJson(Map<String, dynamic> json) {
    final requestUids =
        (json['requestUids'] as List? ?? []).cast<String>();
    final folderUids = (json['folderUids'] as List? ?? []).cast<String>();

    final requests = requestUids
        .map((uid) {
          final raw = _requests.get(uid);
          if (raw == null) return null;
          return _requestFromJson(
              jsonDecode(raw) as Map<String, dynamic>);
        })
        .whereType<HttpRequest>()
        .toList();

    final folders = folderUids
        .map((uid) {
          final raw = _folders.get(uid);
          if (raw == null) return null;
          return _folderFromJson(
              jsonDecode(raw) as Map<String, dynamic>);
        })
        .whereType<Folder>()
        .toList();

    return Collection(
      uid: json['uid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      requests: requests,
      folders: folders,
      auth: AuthConfig.fromJson(
        Map<String, dynamic>.from(
          json['auth'] as Map? ?? const {'runtimeType': 'none'},
        ),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Folder _folderFromJson(Map<String, dynamic> json) {
    final requestUids =
        (json['requestUids'] as List? ?? []).cast<String>();
    final subFolderUids =
        (json['subFolderUids'] as List? ?? []).cast<String>();

    final requests = requestUids
        .map((uid) {
          final raw = _requests.get(uid);
          if (raw == null) return null;
          return _requestFromJson(
              jsonDecode(raw) as Map<String, dynamic>);
        })
        .whereType<HttpRequest>()
        .toList();

    final subFolders = subFolderUids
        .map((uid) {
          final raw = _folders.get(uid);
          if (raw == null) return null;
          return _folderFromJson(
              jsonDecode(raw) as Map<String, dynamic>);
        })
        .whereType<Folder>()
        .toList();

    return Folder(
      uid: json['uid'] as String,
      name: json['name'] as String,
      collectionUid: json['collectionUid'] as String,
      parentFolderUid: json['parentFolderUid'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      requests: requests,
      subFolders: subFolders,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  HttpRequest _requestFromJson(Map<String, dynamic> json) {
    return HttpRequest(
      uid: json['uid'] as String,
      name: json['name'] as String,
      method: HttpMethod.fromString(json['method'] as String),
      url: json['url'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      collectionUid: json['collectionUid'] as String?,
      folderUid: json['folderUid'] as String?,
      params: (json['params'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(RequestParam.fromJson)
          .toList(),
      headers: (json['headers'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(RequestHeader.fromJson)
          .toList(),
      body: RequestBody.fromJson(
          json['body'] as Map<String, dynamic>? ?? {'runtimeType': 'none'}),
      auth: AuthConfig.fromJson(
          json['auth'] as Map<String, dynamic>? ?? {'runtimeType': 'none'}),
      assertions: (json['assertions'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(TestAssertion.fromJson)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> _requestToJson(HttpRequest r) => {
        'uid': r.uid,
        'name': r.name,
        'method': r.method.value,
        'url': r.url,
        'sortOrder': r.sortOrder,
        'collectionUid': r.collectionUid,
        'folderUid': r.folderUid,
        'params': r.params.map((p) => p.toJson()).toList(),
        'headers': r.headers.map((h) => h.toJson()).toList(),
        'body': r.body.toJson(),
        'auth': r.auth.toJson(),
        'assertions': r.assertions.map((a) => a.toJson()).toList(),
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };
}
