import 'package:aun_reqstudio/features/request_builder/widgets/key_value_bulk_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBulkKeyValueRows', () {
    test('parses classic bulk edit separators', () {
      final rows = parseBulkKeyValueRows(
        'Content-Type: application/json\nAccept=application/json\nx-user\t42',
      );

      expect(rows.length, 3);
      expect(rows[0].key, 'Content-Type');
      expect(rows[0].value, 'application/json');
      expect(rows[1].key, 'Accept');
      expect(rows[1].value, 'application/json');
      expect(rows[2].key, 'x-user');
      expect(rows[2].value, '42');
    });

    test('detects json and flattens nested values into bulk rows', () {
      final rows = parseBulkKeyValueRows('''
{
  "Content-Type": "application/json",
  "meta": {
    "enabled": true,
    "retryCount": 3
  },
  "tags": ["one", "two"],
  "nullable": null
}
''');

      expect(rows.length, 6);
      expect(rows[0], (
        key: 'Content-Type',
        value: 'application/json',
        isEnabled: true,
      ));
      expect(rows[1], (key: 'meta.enabled', value: 'true', isEnabled: true));
      expect(rows[2], (key: 'meta.retryCount', value: '3', isEnabled: true));
      expect(rows[3], (key: 'tags[0]', value: 'one', isEnabled: true));
      expect(rows[4], (key: 'tags[1]', value: 'two', isEnabled: true));
      expect(rows[5], (key: 'nullable', value: 'null', isEnabled: true));
    });

    test('falls back to plain text parsing when json is invalid', () {
      final rows = parseBulkKeyValueRows('{"broken":');

      expect(rows.length, 1);
      expect(rows.single.key, '{"broken"');
      expect(rows.single.value, '');
    });
  });
}
