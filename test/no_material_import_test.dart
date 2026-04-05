import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

bool _importsMaterialUi(String content) {
  for (final line in content.split('\n')) {
    final t = line.trimLeft();
    if (t.startsWith('//')) continue;
    if (t.startsWith('import ') && t.contains('package:flutter/material.dart')) {
      return true;
    }
  }
  return false;
}

void main() {
  test('lib must not import package:flutter/material.dart', () {
    final dir = Directory('lib');
    expect(dir.existsSync(), isTrue);

    final violations = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path;
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
        continue;
      }
      final content = entity.readAsStringSync();
      if (_importsMaterialUi(content)) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Remove material.dart imports from: ${violations.join(', ')}',
    );
  });
}
