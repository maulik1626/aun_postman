import 'package:aun_postman/core/utils/app_backup.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/domain/models/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppBackup roundtrip preserves collections and environments', () {
    final now = DateTime.utc(2026, 4, 5, 12);
    final col = Collection(
      uid: 'c1',
      name: 'API',
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
    final env = Environment(
      uid: 'e1',
      name: 'Dev',
      createdAt: now,
      updatedAt: now,
    );

    final json = AppBackup.buildJson(
      collections: [col],
      environments: [env],
      history: const [],
      wsSavedCompose: const [],
      activeEnvironmentUid: 'e1',
    );

    final data = AppBackup.parse(json);
    expect(data.collections, hasLength(1));
    expect(data.collections.first.uid, 'c1');
    expect(data.collections.first.name, 'API');
    expect(data.environments, hasLength(1));
    expect(data.environments.first.uid, 'e1');
    expect(data.activeEnvironmentUid, 'e1');
    expect(data.history, isEmpty);
    expect(data.wsSavedCompose, isEmpty);
  });

  test('parse rejects wrong format', () {
    expect(
      () => AppBackup.parse('{"format":"other"}'),
      throwsA(isA<FormatException>()),
    );
  });
}
