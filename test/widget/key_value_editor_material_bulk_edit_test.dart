import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Material key-value bulk edit parses and applies rows',
      (tester) async {
    List<({String key, String value, bool isEnabled})> latest = const [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyValueEditorMaterial(
            rows: const [(key: '', value: '', isEnabled: true)],
            onChanged: (rows) => latest = rows,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Bulk Edit'));
    await tester.pumpAndSettle();

    final bulkField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Content-Type:application/json',
    );
    expect(bulkField, findsOneWidget);

    await tester.enterText(
      bulkField,
      'Content-Type: application/json\nAccept=application/json\nx-user\t42',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(latest.length, 3);
    expect(latest[0].key, 'Content-Type');
    expect(latest[0].value, 'application/json');
    expect(latest[1].key, 'Accept');
    expect(latest[1].value, 'application/json');
    expect(latest[2].key, 'x-user');
    expect(latest[2].value, '42');
    expect(latest.every((r) => r.isEnabled), isTrue);
  });
}
