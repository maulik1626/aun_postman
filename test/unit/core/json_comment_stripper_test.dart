import 'package:aun_postman/core/utils/json_comment_stripper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('jsonHasLineComments', () {
    test('true when any line is a // comment', () {
      expect(jsonHasLineComments('{"a":1}\n// x'), true);
      expect(jsonHasLineComments('// only'), true);
    });

    test('false when no comment lines', () {
      expect(jsonHasLineComments('{"a":1}'), false);
      expect(jsonHasLineComments('{"a":"// not a comment line"}'), false);
    });
  });

  group('isValidJsonBodyContent', () {
    test('empty or whitespace after strip is valid', () {
      expect(isValidJsonBodyContent(''), true);
      expect(isValidJsonBodyContent('   \n// x\n  '), true);
    });

    test('valid JSON and JSON with stripable comments', () {
      expect(isValidJsonBodyContent('{"a":1}'), true);
      expect(isValidJsonBodyContent('// c\n[1]'), true);
    });

    test('invalid when non-empty and not JSON', () {
      expect(isValidJsonBodyContent('{'), false);
      expect(isValidJsonBodyContent('not json'), false);
    });
  });

  group('stripJsonLineComments', () {
    test('drops full-line // comments and keeps JSON', () {
      const raw = '''
// for pet parent login
// {
//        "phone_number" : "9712097140"
// }
// for doctor login
{
       "phone_number" : "9712084252"
}
// for groomer login
// {
//        "phone_number" : "6666666666"
// }
''';
      final out = stripJsonLineComments(raw);
      expect(out.trim(), '''{
       "phone_number" : "9712084252"
}''');
    });

    test('preserves lines that do not start with // after trim', () {
      expect(
        stripJsonLineComments('{"a":1}\n'),
        '{"a":1}\n',
      );
    });

    test('handles CRLF input (output uses \\n)', () {
      expect(
        stripJsonLineComments('// x\r\n{"b":2}\r\n'),
        '{"b":2}\n',
      );
    });

    test('empty and whitespace-only input', () {
      expect(stripJsonLineComments(''), '');
      expect(stripJsonLineComments('   \n  \n'), '   \n  \n');
    });
  });
}
