import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final shellWeb = File('lib/features/shell/shell_screen_web.dart');
  final importExportWeb = File(
    'lib/features/import_export/import_export_screen_web.dart',
  );
  final browserExport = File('lib/app/web/browser_json_export.dart');

  test('web explorer keeps desktop interaction primitives in place', () {
    final source = shellWeb.readAsStringSync();

    expect(source, contains('Scrollbar('));
    expect(source, contains('ListView.builder'));
    expect(source, contains('class _CollectionsExplorerWebState'));
    expect(source, contains('class _CollectionsExplorerWebState'));
    expect(source, contains('Focus('));
    expect(source, contains('onKeyEvent'));
    expect(source, contains('LogicalKeyboardKey.arrowDown'));
    expect(source, contains('LogicalKeyboardKey.arrowUp'));
    expect(source, contains('LogicalKeyboardKey.arrowLeft'));
    expect(source, contains('LogicalKeyboardKey.arrowRight'));
    expect(source, contains('LogicalKeyboardKey.enter'));
    expect(source, contains('LogicalKeyboardKey.space'));
    expect(source, contains('onSecondaryTapDown'));
    expect(source, contains('showMenu<_ExplorerMenuAction>'));
    expect(source, contains('class _MethodBadgeWeb'));
    expect(source, contains('_methodColor'));
  });

  test(
    'web explorer keeps new-request keyboard shortcut local to selection',
    () {
      final source = shellWeb.readAsStringSync();

      expect(source, contains('LogicalKeyboardKey.keyN'));
      expect(source, contains('HardwareKeyboard.instance.logicalKeysPressed'));
      expect(source, contains('_openNewRequestNearSelection'));
      expect(source, contains('folderUid: row.containingFolderUid'));
    },
  );

  test('web explorer collapse avoids remount flicker', () {
    final source = shellWeb.readAsStringSync();

    expect(source, contains('_rows = _visibleRows();'));
    expect(source, contains('ListView.builder'));
    expect(source, contains('KeyedSubtree('));
    expect(source, isNot(contains('FadeTransition(')));
  });

  test('web shell explorer width bounds never invert clamp on web', () {
    final source = shellWeb.readAsStringSync();
    expect(source, contains('_explorerPaneBoundsForViewport'));
    expect(source, contains('_webShellCompactBreakpoint'));
  });

  test('web compact shell uses full-width drawer for explorer', () {
    final source = shellWeb.readAsStringSync();
    expect(source, contains('_WebCompactShellBar'));
    expect(source, contains('Icons.menu_rounded'));
    expect(source, contains('Drawer('));
    expect(source, contains('width: viewportWidth'));
  });

  test('web explorer and import export avoid mobile bottom sheets', () {
    expect(
      shellWeb.readAsStringSync(),
      isNot(contains('showModalBottomSheet')),
    );
    expect(
      importExportWeb.readAsStringSync(),
      isNot(contains('showModalBottomSheet')),
    );
  });

  test('browser JSON export helper owns dart html download behavior', () {
    final helper = browserExport.readAsStringSync();
    final shell = shellWeb.readAsStringSync();
    final importExport = importExportWeb.readAsStringSync();

    expect(helper, contains("import 'dart:html' as html;"));
    expect(helper, contains('downloadJsonFile'));
    expect(helper, contains('copyJsonToClipboard'));
    expect(shell, contains('downloadJsonFile'));
    expect(importExport, contains('downloadJsonFile'));
  });
}
