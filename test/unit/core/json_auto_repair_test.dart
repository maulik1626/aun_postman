import 'dart:convert';

import 'package:aun_reqstudio/core/utils/json_auto_repair.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Decodes repaired output so we compare structure, not exact whitespace.
  Object? decodeRepaired(String? s) {
    if (s == null) return null;
    return jsonDecode(s);
  }

  group('tryAutoRepairJson', () {
    test('null for empty after cleanup', () {
      expect(tryAutoRepairJson(''), null);
      expect(tryAutoRepairJson('// only\n'), null);
    });

    test('pretty-prints valid JSON', () {
      expect(tryAutoRepairJson('{"a":1}'), '{\n  "a": 1\n}');
    });

    test('strips BOM', () {
      expect(tryAutoRepairJson('\uFEFF{"x":true}'), '{\n  "x": true\n}');
    });

    test('removes trailing commas', () {
      expect(
        tryAutoRepairJson('{"a":1,}'),
        '{\n  "a": 1\n}',
      );
      expect(
        tryAutoRepairJson('[1,2,]'),
        '[\n  1,\n  2\n]',
      );
    });

    test('does not remove comma inside string', () {
      final out = tryAutoRepairJson('{"a": "x,}"}');
      expect(out, isNotNull);
      expect(out, contains('x,}'));
    });

    test('line comments and block comments', () {
      final out = tryAutoRepairJson('''
// top
/* head */ {"a": 1} // tail
''');
      expect(out, '{\n  "a": 1\n}');
    });

    test('null when still broken', () {
      expect(tryAutoRepairJson('{'), null);
      expect(tryAutoRepairJson("{'a':1}"), null);
    });

    test('inserts missing comma between object properties', () {
      expect(
        tryAutoRepairJson('{"a":1 "b":2}'),
        '{\n  "a": 1,\n  "b": 2\n}',
      );
      expect(
        tryAutoRepairJson('{"phone":"971" "name":"x"}'),
        '{\n  "phone": "971",\n  "name": "x"\n}',
      );
    });

    test('inserts missing comma between array elements', () {
      expect(
        tryAutoRepairJson('[1 2 3]'),
        '[\n  1,\n  2,\n  3\n]',
      );
    });

    test('does not add comma to already valid JSON', () {
      const ok = '{"a":1,"b":2}';
      expect(tryAutoRepairJson(ok), contains('"a": 1'));
      expect(insertMissingCommasBetweenValues(ok), ok);
    });

    test('many missing commas in one object', () {
      final out = tryAutoRepairJson(
        '{"a":1 "b":2 "c":3 "d":4 "e":"five"}',
      );
      expect(
        decodeRepaired(out),
        equals({
          'a': 1,
          'b': 2,
          'c': 3,
          'd': 4,
          'e': 'five',
        }),
      );
    });

    test('many missing commas in array', () {
      final out = tryAutoRepairJson('[1 2 3 4 5]');
      expect(decodeRepaired(out), equals([1, 2, 3, 4, 5]));
    });

    test('missing commas between literals in array', () {
      final out = tryAutoRepairJson('[true false null 42]');
      expect(decodeRepaired(out), equals([true, false, null, 42]));
    });

    test('nested object with inner and outer missing commas', () {
      final out = tryAutoRepairJson('{"outer":{"x":1 "y":2} "k":3}');
      expect(
        decodeRepaired(out),
        equals({
          'outer': {'x': 1, 'y': 2},
          'k': 3,
        }),
      );
    });

    test('array of objects without commas between elements', () {
      final out = tryAutoRepairJson('[{"a":1}{"b":2}{"c":3}]');
      expect(decodeRepaired(out), equals([
        {'a': 1},
        {'b': 2},
        {'c': 3},
      ]));
    });

    test('nested arrays with missing commas inside and between', () {
      final out = tryAutoRepairJson('[[1 2] [3 4]]');
      expect(decodeRepaired(out), equals([
        [1, 2],
        [3, 4],
      ]));
    });

    test('string values with missing commas between properties', () {
      final out = tryAutoRepairJson('{"a":"one" "b":"two" "c":"three"}');
      expect(
        decodeRepaired(out),
        equals({'a': 'one', 'b': 'two', 'c': 'three'}),
      );
    });

    test('newlines between tokens with multiple gaps', () {
      final out = tryAutoRepairJson('''{
  "a": 1
  "b": 2
  "c": {"x": true "y": false}
}''');
      expect(
        decodeRepaired(out),
        equals({
          'a': 1,
          'b': 2,
          'c': {'x': true, 'y': false},
        }),
      );
    });

    test('missing comma plus trailing comma in same payload', () {
      final out = tryAutoRepairJson('{"a":1 "b":2,}');
      expect(decodeRepaired(out), equals({'a': 1, 'b': 2}));
    });

    test('missing commas and line comments together', () {
      final out = tryAutoRepairJson('''
{"a": 1 // first
"b": 2 "c": 3}
''');
      expect(decodeRepaired(out), equals({'a': 1, 'b': 2, 'c': 3}));
    });
  });

  group('insertMissingCommasBetweenValues', () {
    test('idempotent on repaired object', () {
      const once = '{"a":1,"b":2,"c":3}';
      final twice = insertMissingCommasBetweenValues(once);
      expect(twice, once);
      expect(insertMissingCommasBetweenValues(twice), once);
    });

    test('multiple gaps in one pass output parses', () {
      final s = insertMissingCommasBetweenValues('{ "x":1 "y":2 "z":3 }');
      expect(jsonDecode(s), {'x': 1, 'y': 2, 'z': 3});
    });
  });

  group('jsonRepairMayRemoveComments', () {
    test('detects // and /* that repair will strip', () {
      expect(jsonRepairMayRemoveComments('//x\n{"a":1}'), true);
      expect(jsonRepairMayRemoveComments('{"a":1}/*x*/'), true);
      expect(jsonRepairMayRemoveComments('{"a":1}//x'), true);
      expect(jsonRepairMayRemoveComments('{"a":1}'), false);
      expect(jsonRepairMayRemoveComments('{"u":"http://x"}'), false);
    });
  });
}
