import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android Material screens (`*_material.dart`) must not import Cupertino —
/// see `MATERIAL_ANDROID_TRACKER.md` (strict Material on Android, Cupertino on iOS).
void main() {
  test(
    'Material screen files (*_material.dart) must not import '
    'package:flutter/cupertino.dart',
    () {
      final dir = Directory('lib');
      expect(dir.existsSync(), isTrue);

      final violations = <String>[];
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path.replaceAll(r'\', '/');
        if (!path.endsWith('_material.dart')) continue;

        final content = entity.readAsStringSync();
        for (final line in content.split('\n')) {
          final t = line.trimLeft();
          if (t.startsWith('//')) continue;
          if (t.startsWith('import ') &&
              t.contains('package:flutter/cupertino.dart')) {
            violations.add(path);
            break;
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Cupertino imports found in material screen files: ${violations.join(', ')}',
      );
    },
  );
}
