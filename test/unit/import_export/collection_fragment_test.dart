import 'dart:convert';

import 'package:aun_reqstudio/core/errors/app_exception.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_importer.dart';
import 'package:aun_reqstudio/domain/enums/http_method.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:aun_reqstudio/domain/models/folder.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/request_body.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Collection fragment export/import', () {
    test('exportFragment round-trips multiple root requests', () {
      final now = DateTime(2024, 1, 1);
      final r1 = HttpRequest(
        uid: 'a',
        name: 'One',
        method: HttpMethod.get,
        url: 'https://a.test',
        body: const NoBody(),
        auth: const NoAuth(),
        collectionUid: 'c',
        folderUid: null,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      final r2 = HttpRequest(
        uid: 'b',
        name: 'Two',
        method: HttpMethod.post,
        url: 'https://b.test',
        body: const NoBody(),
        auth: const NoAuth(),
        collectionUid: 'c',
        folderUid: null,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );
      final json = CollectionV21Exporter.exportFragment(
        title: 'Pick',
        entries: [
          CollectionV21FragmentRequest(r1),
          CollectionV21FragmentRequest(r2),
        ],
      );
      final fragment = CollectionV21Importer.importFragment(json);
      expect(fragment.rootRequests.length, 2);
      expect(fragment.rootRequests.map((e) => e.name).toList(), ['One', 'Two']);
      expect(fragment.rootRequests.first.method, HttpMethod.get);
      expect(fragment.rootRequests.last.url, 'https://b.test');
      expect(fragment.folders, isEmpty);
    });

    test('exportFragment includes folder subtree', () {
      final now = DateTime(2024, 1, 1);
      final inner = HttpRequest(
        uid: 'r',
        name: 'Inner',
        method: HttpMethod.put,
        url: 'https://inner',
        body: const NoBody(),
        auth: const NoAuth(),
        collectionUid: 'c',
        folderUid: 'f',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      final folder = Folder(
        uid: 'f',
        name: 'Outer',
        collectionUid: 'c',
        parentFolderUid: null,
        sortOrder: 0,
        requests: [inner],
        subFolders: const [],
        createdAt: now,
        updatedAt: now,
      );
      final json = CollectionV21Exporter.exportFragment(
        title: 'Frag',
        entries: [CollectionV21FragmentFolder(folder)],
      );
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect((map['item'] as List).length, 1);
      final fragment = CollectionV21Importer.importFragment(json);
      expect(fragment.folders.length, 1);
      expect(fragment.folders.first.name, 'Outer');
      expect(fragment.folders.first.requests.length, 1);
      expect(fragment.folders.first.requests.first.name, 'Inner');
    });

    test('importFragment rejects empty item list', () {
      final json = jsonEncode({
        'info': {'name': 'Empty', 'schema': ''},
        'item': [],
      });
      expect(
        () => CollectionV21Importer.importFragment(json),
        throwsA(isA<ImportException>()),
      );
    });
  });
}
