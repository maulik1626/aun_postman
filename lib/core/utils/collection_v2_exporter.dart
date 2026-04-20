import 'dart:convert';

import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:aun_reqstudio/domain/models/collection.dart';
import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/folder.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/request_body.dart';
import 'package:uuid/uuid.dart';

class CollectionV21Exporter {
  static const _uuid = Uuid();

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

  /// One or more folders/requests in display order for a partial v2.1 export.
  static String exportFragment({
    required String title,
    String? description,
    required List<CollectionV21FragmentEntry> entries,
  }) {
    if (entries.isEmpty) {
      throw ArgumentError('exportFragment requires at least one entry');
    }
    final item = <Map<String, dynamic>>[];
    for (final e in entries) {
      switch (e) {
        case CollectionV21FragmentFolder(:final folder):
          item.add(_folderToJson(folder));
        case CollectionV21FragmentRequest(:final request):
          item.add(_requestToJson(request));
      }
    }
    final data = {
      'info': {
        '_postman_id': _uuid.v4(),
        'name': title,
        'description': description ?? '',
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      },
      'item': item,
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
      OAuth2Auth(
        :final accessToken,
        :final refreshToken,
        :final tokenType,
        :final tokenUrl,
        :final clientId,
        :final clientSecret,
        :final scope,
        :final username,
        :final password,
        :final grantType,
      ) =>
        {
          'type': 'oauth2',
          'oauth2': [
            {'key': 'accessToken', 'value': accessToken, 'type': 'string'},
            {'key': 'tokenType', 'value': tokenType, 'type': 'string'},
            {'key': 'refreshToken', 'value': refreshToken, 'type': 'string'},
            {'key': 'accessTokenUrl', 'value': tokenUrl, 'type': 'string'},
            {'key': 'clientId', 'value': clientId, 'type': 'string'},
            {'key': 'clientSecret', 'value': clientSecret, 'type': 'string'},
            {'key': 'scope', 'value': scope, 'type': 'string'},
            {'key': 'username', 'value': username, 'type': 'string'},
            {'key': 'password', 'value': password, 'type': 'string'},
            {
              'key': 'grant_type',
              'value': grantType.wireValue,
              'type': 'string',
            },
          ],
        },
      DigestAuth() => {
          'type': 'noauth',
        },
      AwsSigV4Auth() => {'type': 'noauth'},
    };
  }

  /// Standard v2.1-style environment JSON (interoperable with common API clients).
  static String exportEnvironment(Environment env) {
    final data = {
      'id': env.uid,
      'name': env.name,
      '_postman_variable_scope': 'environment',
      'values': env.variables
          .map(
            (v) => {
              'key': v.key,
              'value': v.value,
              'enabled': v.isEnabled,
              'type': v.isSecret ? 'secret' : 'default',
            },
          )
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

sealed class CollectionV21FragmentEntry {
  const CollectionV21FragmentEntry();
}

final class CollectionV21FragmentFolder extends CollectionV21FragmentEntry {
  const CollectionV21FragmentFolder(this.folder);
  final Folder folder;
}

final class CollectionV21FragmentRequest extends CollectionV21FragmentEntry {
  const CollectionV21FragmentRequest(this.request);
  final HttpRequest request;
}
