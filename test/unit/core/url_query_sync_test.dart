import 'package:aun_reqstudio/core/utils/url_query_sync.dart';
import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlQuerySync', () {
    test('parseRawQueryToRequestParams preserves duplicate keys and order', () {
      final list = UrlQuerySync.parseRawQueryToRequestParams('a=1&a=2&b=3');
      expect(list.length, 3);
      expect(list[0].key, 'a');
      expect(list[0].value, '1');
      expect(list[1].key, 'a');
      expect(list[1].value, '2');
      expect(list[2].key, 'b');
      expect(list[2].value, '3');
    });

    test('parseRawQueryToRequestParams decodes components', () {
      final list = UrlQuerySync.parseRawQueryToRequestParams('q=hello%20world');
      expect(list.single.key, 'q');
      expect(list.single.value, 'hello world');
    });

    test('buildEncodedQuery skips disabled and empty key+value rows', () {
      final q = UrlQuerySync.buildEncodedQuery([
        const RequestParam(key: 'x', value: '1', isEnabled: true),
        const RequestParam(key: 'y', value: '2', isEnabled: false),
        const RequestParam(key: '', value: '', isEnabled: true),
      ]);
      expect(q, 'x=1');
    });

    test('splitUrlParts and joinUrlParts preserve fragment', () {
      final parts = UrlQuerySync.splitUrlParts(
        'https://ex.com/path?a=1#frag',
      );
      expect(parts.prefix, 'https://ex.com/path');
      expect(parts.rawQuery, 'a=1');
      expect(parts.fragment, '#frag');
      final joined = UrlQuerySync.joinUrlParts(
        prefix: parts.prefix,
        rawQuery: 'b=2',
        fragment: parts.fragment,
      );
      expect(joined, 'https://ex.com/path?b=2#frag');
    });

    test('urlForHttpCall replaces query from enabled params only', () {
      final url = UrlQuerySync.urlForHttpCall(
        'https://ex.com/old?stale=1',
        [
          const RequestParam(key: 'a', value: 'x', isEnabled: true),
        ],
      );
      expect(url, 'https://ex.com/old?a=x');
    });

    test('canonicalizeUrlAndParams prefers params list when non-empty', () {
      final c = UrlQuerySync.canonicalizeUrlAndParams(
        'https://ex.com/p?old=9',
        [
          const RequestParam(key: 'n', value: '1', isEnabled: true),
        ],
      );
      expect(c.url, 'https://ex.com/p?n=1');
      expect(c.params.single.key, 'n');
    });

    test('canonicalizeUrlAndParams parses URL when params empty', () {
      final c = UrlQuerySync.canonicalizeUrlAndParams(
        'https://ex.com?q=1&q=2',
        [],
      );
      expect(c.params.length, 2);
      expect(c.params[0].value, '1');
      expect(c.params[1].value, '2');
    });
  });
}
