import 'package:aun_reqstudio/core/utils/variable_interpolator.dart';
import 'package:aun_reqstudio/domain/enums/http_method.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/request_body.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final interpolator = VariableInterpolator();

  Environment makeEnv(Map<String, String> vars) {
    return Environment(
      uid: 'env-1',
      name: 'Test',
      isActive: true,
      variables: vars.entries
          .map(
            (e) => EnvironmentVariable(uid: e.key, key: e.key, value: e.value),
          )
          .toList(),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  HttpRequest makeRequest(String url) {
    final now = DateTime(2026);
    return HttpRequest(
      uid: 'req-1',
      name: 'Test',
      method: HttpMethod.get,
      url: url,
      body: const NoBody(),
      auth: const NoAuth(),
      createdAt: now,
      updatedAt: now,
    );
  }

  group('VariableInterpolator.interpolate', () {
    test('replaces single variable', () {
      final result = interpolator.interpolate(
        'https://{{host}}/api',
        {'host': 'api.example.com'},
      );
      expect(result, 'https://api.example.com/api');
    });

    test('replaces multiple variables', () {
      final result = interpolator.interpolate(
        '{{scheme}}://{{host}}/{{path}}',
        {'scheme': 'https', 'host': 'example.com', 'path': 'users'},
      );
      expect(result, 'https://example.com/users');
    });

    test('leaves unknown variables unchanged', () {
      final result = interpolator.interpolate(
        'Hello {{unknown}}',
        {'other': 'value'},
      );
      expect(result, 'Hello {{unknown}}');
    });

    test('handles empty input', () {
      expect(interpolator.interpolate('', {'key': 'val'}), '');
    });

    test('handles no variables in string', () {
      expect(
        interpolator.interpolate('no vars here', {'key': 'val'}),
        'no vars here',
      );
    });

    test('trims whitespace inside braces', () {
      final result = interpolator.interpolate('{{ key }}', {'key': 'value'});
      expect(result, 'value');
    });
  });

  group('VariableInterpolator.interpolateRequest', () {
    test('returns request unchanged when env is null', () {
      final request = makeRequest('https://{{host}}');
      final result = interpolator.interpolateRequest(request, null);
      expect(result.url, 'https://{{host}}');
    });

    test('interpolates URL', () {
      final env = makeEnv({'host': 'api.example.com'});
      final request = makeRequest('https://{{host}}/users');
      final result = interpolator.interpolateRequest(request, env);
      expect(result.url, 'https://api.example.com/users');
    });
  });
}
