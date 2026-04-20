import 'package:aun_reqstudio/core/utils/curl_parser.dart';
import 'package:aun_reqstudio/domain/enums/http_method.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:aun_reqstudio/domain/models/request_body.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurlParser', () {
    test('parses simple GET', () {
      final req = CurlParser.parse("curl 'https://api.example.com/users'");
      expect(req, isNotNull);
      expect(req!.method, HttpMethod.get);
      expect(req.url, 'https://api.example.com/users');
    });

    test('parses explicit method', () {
      final req = CurlParser.parse(
        "curl -X DELETE 'https://api.example.com/users/1'",
      );
      expect(req!.method, HttpMethod.delete);
    });

    test('parses POST with JSON body', () {
      final req = CurlParser.parse(
        """curl -X POST 'https://api.example.com/users' """
        """-H 'Content-Type: application/json' """
        """--data-raw '{"name":"Alice"}'""",
      );
      expect(req!.method, HttpMethod.post);
      expect(req.body, isA<RawJsonBody>());
    });

    test('parses headers', () {
      final req = CurlParser.parse(
        """curl 'https://api.example.com' -H 'X-Token: abc123'""",
      );
      expect(req!.headers.any((h) => h.key == 'X-Token'), isTrue);
    });

    test('parses basic auth', () {
      final req = CurlParser.parse(
        "curl -u admin:secret 'https://api.example.com'",
      );
      expect(req!.auth, isA<BasicAuth>());
      final auth = req.auth as BasicAuth;
      expect(auth.username, 'admin');
      expect(auth.password, 'secret');
    });

    test('returns null for empty input', () {
      expect(CurlParser.parse(''), isNull);
    });

    test('infers POST when -d is present', () {
      final req = CurlParser.parse(
        "curl 'https://api.example.com' -d 'foo=bar'",
      );
      expect(req!.method, HttpMethod.post);
    });

    test('parses duplicate query keys into separate params', () {
      final req = CurlParser.parse(
        "curl 'https://api.example.com/search?tag=a&tag=b'",
      );
      expect(req, isNotNull);
      expect(req!.url, 'https://api.example.com/search');
      expect(req.params.length, 2);
      expect(req.params[0].key, 'tag');
      expect(req.params[0].value, 'a');
      expect(req.params[1].key, 'tag');
      expect(req.params[1].value, 'b');
    });
  });
}
