import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Files that are explicitly allowed to import package:flutter/material.dart.
// These are either platform-routing foundation files or *_material.dart screens.
const _allowedSuffixes = [
  // All material-specific screen/widget files
  '_material.dart',
  // Web-specific UI files are allowed to use Material infrastructure.
  '_web.dart',
];

const _allowedPaths = {
  'lib/app/app.dart',
  'lib/app/platform.dart',
  'lib/app/theme/app_theme.dart',
  'lib/app/router/app_router.dart',
  'lib/app/widgets/app_gradient_button.dart',
  'lib/app/utils/platform_dialogs.dart',
  'lib/app/screenshot_feedback/app_feedback_flow.dart',
};

bool _isAllowed(String path) {
  // Normalize Windows separators.
  final p = path.replaceAll(r'\', '/');
  if (p.contains('/web/')) return true;
  if (_allowedSuffixes.any((s) => p.endsWith(s))) return true;
  return _allowedPaths.any((allowed) => p.endsWith(allowed));
}

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
  test(
    'Non-material lib files must not import package:flutter/material.dart',
    () {
      final dir = Directory('lib');
      expect(dir.existsSync(), isTrue);

      final violations = <String>[];
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path;
        if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
          continue;
        }
        if (_isAllowed(path)) continue;
        final content = entity.readAsStringSync();
        if (_importsMaterialUi(content)) {
          violations.add(path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Unexpected material.dart imports found in: ${violations.join(', ')}\n'
            'Add to _allowedPaths or name the file *_material.dart.',
      );
    },
  );

}
