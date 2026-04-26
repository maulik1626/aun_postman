import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor_web.dart';

typedef _Row = ({String key, String value, bool isEnabled});

void main() {
  Future<void> pumpEditor(
    WidgetTester tester, {
    required List<_Row> initialRows,
    required ValueChanged<List<_Row>> onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 600,
            child: KeyValueEditorWeb(
              title: 'Query Params',
              rows: initialRows,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('typing in a row keeps focus and reports changes', (
    tester,
  ) async {
    var current = <_Row>[];
    await pumpEditor(
      tester,
      initialRows: const [],
      onChanged: (rows) => current = rows,
    );

    final keyField = find.widgetWithText(TextField, 'Key');
    expect(keyField, findsOneWidget);

    await tester.tap(keyField);
    await tester.pump();
    await tester.enterText(keyField, 'Authorization');
    await tester.pump();

    expect(current.isNotEmpty, isTrue);
    expect(current.first.key, 'Authorization');

    final controller = (tester.firstWidget(keyField) as TextField).controller;
    expect(controller, isNotNull);
    expect(controller!.text, 'Authorization');
    final focusNode = tester.firstWidget<TextField>(keyField).focusNode;
    if (focusNode != null) {
      expect(focusNode.hasFocus, isTrue);
    }
  });

  testWidgets('Add button adds a new row at the end', (tester) async {
    var rowCount = 0;
    await pumpEditor(
      tester,
      initialRows: const [(key: 'A', value: '1', isEnabled: true)],
      onChanged: (rows) => rowCount = rows.length,
    );

    expect(find.widgetWithText(TextField, 'Key'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Key'), findsNWidgets(2));

    await tester.enterText(
      find.widgetWithText(TextField, 'Key').last,
      'Accept',
    );
    await tester.pump();
    expect(rowCount, 2);
  });

  testWidgets('Bulk Edit dialog parses JSON input into key-value rows', (
    tester,
  ) async {
    var current = <_Row>[];
    await pumpEditor(
      tester,
      initialRows: const [(key: 'page', value: '1', isEnabled: true)],
      onChanged: (rows) => current = rows,
    );

    await tester.tap(find.text('Bulk Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Bulk Edit'), findsWidgets);

    final dialogField = find.byType(TextField).last;
    await tester.enterText(
      dialogField,
      '{ "limit": 25, "filter": { "kind": "doc" } }',
    );
    await tester.pump();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    final keys = current.map((r) => r.key).toList();
    expect(keys, contains('limit'));
    expect(keys.any((k) => k == 'filter.kind'), isTrue);
  });

  testWidgets('removing a row updates state and refocuses cleanly', (
    tester,
  ) async {
    var current = <_Row>[];
    await pumpEditor(
      tester,
      initialRows: const [
        (key: 'A', value: '1', isEnabled: true),
        (key: 'B', value: '2', isEnabled: true),
      ],
      onChanged: (rows) => current = rows,
    );

    expect(find.widgetWithText(TextField, 'Key'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Remove row').first);
    await tester.pumpAndSettle();

    expect(current.length, 1);
    expect(current.first.key, 'B');
  });
}
