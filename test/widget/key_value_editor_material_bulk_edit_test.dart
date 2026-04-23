import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MaterialRowsHost extends StatefulWidget {
  const _MaterialRowsHost({super.key});

  @override
  State<_MaterialRowsHost> createState() => _MaterialRowsHostState();
}

class _MaterialRowsHostState extends State<_MaterialRowsHost> {
  List<({String key, String value, bool isEnabled})> rows = const [];

  void setRows(List<({String key, String value, bool isEnabled})> next) {
    setState(() => rows = next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: KeyValueEditorMaterial(rows: rows, onChanged: (_) {}),
      ),
    );
  }
}

void main() {
  testWidgets('Material key-value bulk edit parses and applies rows', (
    tester,
  ) async {
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
      (w) =>
          w is TextField &&
          w.decoration?.hintText == 'Content-Type:application/json',
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

  testWidgets('Material key-value bulk edit detects raw json', (tester) async {
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
      (w) =>
          w is TextField &&
          w.decoration?.hintText == 'Content-Type:application/json',
    );

    await tester.enterText(
      bulkField,
      '{"Authorization":"Bearer token","meta":{"env":"prod"},"flags":[true,false]}',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(latest.length, 4);
    expect(latest[0].key, 'Authorization');
    expect(latest[0].value, 'Bearer token');
    expect(latest[1].key, 'meta.env');
    expect(latest[1].value, 'prod');
    expect(latest[2].key, 'flags[0]');
    expect(latest[2].value, 'true');
    expect(latest[3].key, 'flags[1]');
    expect(latest[3].value, 'false');
  });

  testWidgets('Material key-value editor syncs when rows prop changes', (
    tester,
  ) async {
    final hostKey = GlobalKey<_MaterialRowsHostState>();
    await tester.pumpWidget(_MaterialRowsHost(key: hostKey));
    expect(find.text('userid'), findsNothing);

    hostKey.currentState!.setRows([
      (key: 'userid', value: '12133', isEnabled: true),
      (key: 'version', value: '1.0.1', isEnabled: true),
    ]);
    await tester.pump();

    expect(find.text('userid'), findsOneWidget);
    expect(find.text('12133'), findsOneWidget);
    expect(find.text('version'), findsOneWidget);
    expect(find.text('1.0.1'), findsOneWidget);
  });
}
