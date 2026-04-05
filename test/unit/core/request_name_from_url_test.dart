import 'package:aun_postman/core/utils/request_name_from_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty -> New Request', () {
    expect(suggestRequestNameFromUrl(''), 'New Request');
    expect(suggestRequestNameFromUrl('   '), 'New Request');
  });

  test('https URL host + path', () {
    expect(
      suggestRequestNameFromUrl('https://api.example.com/v1/users'),
      'api.example.com/v1/users',
    );
  });

  test('URL without scheme', () {
    expect(
      suggestRequestNameFromUrl('api.foo.com/items'),
      'api.foo.com/items',
    );
  });

  test('host only', () {
    expect(suggestRequestNameFromUrl('https://echo.local/'), 'echo.local');
  });

  test('strips query', () {
    expect(
      suggestRequestNameFromUrl('https://x.test/a?q=1'),
      'x.test/a',
    );
  });

  test('strips {{variable}} in path', () {
    expect(
      suggestRequestNameFromUrl('https://api.example.com/v1/users/{{userId}}'),
      'api.example.com/v1/users',
    );
  });

  test('strips {{variable}} in host; path-only when host was only vars', () {
    expect(
      suggestRequestNameFromUrl('https://{{baseUrl}}/v1/users'),
      'v1/users',
    );
  });

  test('collapses empty path segment after removing variable', () {
    expect(
      suggestRequestNameFromUrl('https://x.test/{{segment}}/items'),
      'x.test/items',
    );
  });
}
