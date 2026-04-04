import 'dart:convert';

import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/domain/models/folder.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/request_body.dart';

class PostmanV2Exporter {
  static String export(Collection collection) {
    final data = {
      'info': {
        '_postman_id': collection.uid,
        'name': collection.name,
        'description': collection.description ?? '',
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      },
      'item': [
        ...collection.folders.map(_folderToJson),
        ...collection.requests.map(_requestToJson),
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Map<String, dynamic> _folderToJson(Folder folder) {
    return {
      'name': folder.name,
      'item': [
        ...folder.subFolders.map(_folderToJson),
        ...folder.requests.map(_requestToJson),
      ],
    };
  }

  static Map<String, dynamic> _requestToJson(HttpRequest request) {
    return {
      'name': request.name,
      'request': {
        'method': request.method.value,
        'url': {
          'raw': request.url,
          'query': request.params
              .map((p) => {
                    'key': p.key,
                    'value': p.value,
                    'disabled': !p.isEnabled,
                  })
              .toList(),
        },
        'header': request.headers
            .map((h) => {
                  'key': h.key,
                  'value': h.value,
                  'disabled': !h.isEnabled,
                })
            .toList(),
        'body': _bodyToJson(request.body),
        'auth': _authToJson(request.auth),
      },
      'response': [],
    };
  }

  static Map<String, dynamic>? _bodyToJson(RequestBody body) {
    return switch (body) {
      NoBody() => null,
      RawJsonBody(:final content) => {
          'mode': 'raw',
          'raw': content,
          'options': {
            'raw': {'language': 'json'}
          },
        },
      RawXmlBody(:final content) => {
          'mode': 'raw',
          'raw': content,
          'options': {
            'raw': {'language': 'xml'}
          },
        },
      RawTextBody(:final content) => {
          'mode': 'raw',
          'raw': content,
          'options': {
            'raw': {'language': 'text'}
          },
        },
      RawHtmlBody(:final content) => {
          'mode': 'raw',
          'raw': content,
          'options': {
            'raw': {'language': 'html'}
          },
        },
      UrlEncodedBody(:final fields) => {
          'mode': 'urlencoded',
          'urlencoded': fields
              .map((f) => {
                    'key': f.key,
                    'value': f.value,
                    'disabled': !f.isEnabled,
                  })
              .toList(),
        },
      FormDataBody(:final fields) => {
          'mode': 'formdata',
          'formdata': fields
              .map((f) => {
                    'key': f.key,
                    'value': f.value,
                    'disabled': !f.isEnabled,
                  })
              .toList(),
        },
      BinaryBody() => {'mode': 'file'},
    };
  }

  static Map<String, dynamic>? _authToJson(AuthConfig auth) {
    return switch (auth) {
      NoAuth() => {'type': 'noauth'},
      BearerAuth(:final token) => {
          'type': 'bearer',
          'bearer': [
            {'key': 'token', 'value': token, 'type': 'string'}
          ],
        },
      BasicAuth(:final username, :final password) => {
          'type': 'basic',
          'basic': [
            {'key': 'username', 'value': username, 'type': 'string'},
            {'key': 'password', 'value': password, 'type': 'string'},
          ],
        },
      ApiKeyAuth(:final key, :final value, :final addTo) => {
          'type': 'apikey',
          'apikey': [
            {'key': 'key', 'value': key, 'type': 'string'},
            {'key': 'value', 'value': value, 'type': 'string'},
            {
              'key': 'in',
              'value': addTo.name,
              'type': 'string'
            },
          ],
        },
    };
  }
}
