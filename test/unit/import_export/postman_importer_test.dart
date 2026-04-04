import 'dart:convert';

import 'package:aun_postman/core/utils/postman_v2_importer.dart';
import 'package:aun_postman/domain/enums/http_method.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostmanV2Importer', () {
    test('imports collection name and description', () {
      final json = jsonEncode({
        'info': {
          'name': 'My API',
          'description': 'Test collection',
          'schema': 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        },
        'item': [],
      });

      final collection = PostmanV2Importer.import(json);
      expect(collection.name, 'My API');
      expect(collection.description, 'Test collection');
    });

    test('imports a simple GET request', () {
      final json = jsonEncode({
        'info': {'name': 'Test', 'schema': ''},
        'item': [
          {
            'name': 'Get Users',
            'request': {
              'method': 'GET',
              'url': {'raw': 'https://api.example.com/users'},
              'header': [],
            },
          },
        ],
      });

      final collection = PostmanV2Importer.import(json);
      expect(collection.requests.length, 1);
      expect(collection.requests.first.name, 'Get Users');
      expect(collection.requests.first.method, HttpMethod.get);
      expect(collection.requests.first.url, 'https://api.example.com/users');
    });

    test('imports folder with nested requests', () {
      final json = jsonEncode({
        'info': {'name': 'Test', 'schema': ''},
        'item': [
          {
            'name': 'Users',
            'item': [
              {
                'name': 'List Users',
                'request': {
                  'method': 'GET',
                  'url': {'raw': 'https://api.example.com/users'},
                  'header': [],
                },
              },
            ],
          },
        ],
      });

      final collection = PostmanV2Importer.import(json);
      expect(collection.folders.length, 1);
      expect(collection.folders.first.name, 'Users');
      expect(collection.folders.first.requests.length, 1);
    });

    test('imports bearer auth', () {
      final json = jsonEncode({
        'info': {'name': 'Test', 'schema': ''},
        'item': [
          {
            'name': 'Authed Request',
            'request': {
              'method': 'GET',
              'url': {'raw': 'https://api.example.com'},
              'header': [],
              'auth': {
                'type': 'bearer',
                'bearer': [
                  {'key': 'token', 'value': 'mytoken123', 'type': 'string'},
                ],
              },
            },
          },
        ],
      });

      final collection = PostmanV2Importer.import(json);
      final auth = collection.requests.first.auth;
      expect(auth, isA<BearerAuth>());
      expect((auth as BearerAuth).token, 'mytoken123');
    });

    test('imports JSON body', () {
      final json = jsonEncode({
        'info': {'name': 'Test', 'schema': ''},
        'item': [
          {
            'name': 'Create User',
            'request': {
              'method': 'POST',
              'url': {'raw': 'https://api.example.com/users'},
              'header': [],
              'body': {
                'mode': 'raw',
                'raw': '{"name":"Alice"}',
                'options': {
                  'raw': {'language': 'json'},
                },
              },
            },
          },
        ],
      });

      final collection = PostmanV2Importer.import(json);
      expect(collection.requests.first.body, isA<RawJsonBody>());
    });

    test('throws ImportException on invalid JSON', () {
      expect(
        () => PostmanV2Importer.import('not valid json'),
        throwsA(anything),
      );
    });
  });
}
