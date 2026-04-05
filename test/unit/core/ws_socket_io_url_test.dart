import 'package:aun_postman/core/utils/ws_socket_io_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('socketIoHandshakeUri', () {
    test('maps ws to http', () {
      expect(
        socketIoHandshakeUri('ws://localhost:3000').toString(),
        'http://localhost:3000',
      );
    });

    test('maps wss to https', () {
      expect(
        socketIoHandshakeUri('wss://api.example.com/path?q=1').toString(),
        'https://api.example.com/path?q=1',
      );
    });
  });

  group('buildSocketIoConnectionUri', () {
    test('default namespace keeps path from URL when non-root', () {
      final u = buildSocketIoConnectionUri('https://h.example/chat', '/');
      expect(u.toString(), 'https://h.example/chat');
    });

    test('namespace replaces path when not default', () {
      final u = buildSocketIoConnectionUri('https://h.example', '/room');
      expect(u.toString(), 'https://h.example/room');
    });

    test('preserves query with custom namespace', () {
      final u = buildSocketIoConnectionUri('https://h.example?x=1', '/ns');
      expect(u.path, '/ns');
      expect(u.queryParameters['x'], '1');
    });
  });
}
