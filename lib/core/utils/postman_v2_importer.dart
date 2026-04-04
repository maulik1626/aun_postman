import 'dart:convert';

import 'package:aun_postman/core/errors/app_exception.dart';
import 'package:aun_postman/domain/enums/auth_type.dart';
import 'package:aun_postman/domain/enums/http_method.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/domain/models/environment.dart';
import 'package:aun_postman/domain/models/environment_variable.dart';
import 'package:aun_postman/domain/models/folder.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:uuid/uuid.dart';

class PostmanV2Importer {
  static const _uuid = Uuid();

  static Collection import(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final info = json['info'] as Map<String, dynamic>? ?? {};
      final name = (info['name'] as String?) ?? 'Imported Collection';
      final description = info['description'] as String?;
      final items = json['item'] as List<dynamic>? ?? [];

      final now = DateTime.now();
      final collectionUid = _uuid.v4();

      final folders = <Folder>[];
      final requests = <HttpRequest>[];
      int sortOrder = 0;

      for (final item in items) {
        final map = item as Map<String, dynamic>;
        if (map.containsKey('item')) {
          // It's a folder
          folders.add(
            _parseFolder(map, collectionUid, null, sortOrder++),
          );
        } else {
          requests.add(
            _parseRequest(map, collectionUid, null, sortOrder++),
          );
        }
      }

      return Collection(
        uid: collectionUid,
        name: name,
        description: description,
        folders: folders,
        requests: requests,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw ImportException('Invalid Postman collection: $e');
    }
  }

  static Folder _parseFolder(
    Map<String, dynamic> map,
    String collectionUid,
    String? parentFolderUid,
    int sortOrder,
  ) {
    final uid = _uuid.v4();
    final name = (map['name'] as String?) ?? 'Folder';
    final items = map['item'] as List<dynamic>? ?? [];
    final now = DateTime.now();

    final requests = <HttpRequest>[];
    final subFolders = <Folder>[];
    int childSort = 0;

    for (final item in items) {
      final m = item as Map<String, dynamic>;
      if (m.containsKey('item')) {
        subFolders.add(_parseFolder(m, collectionUid, uid, childSort++));
      } else {
        requests.add(_parseRequest(m, collectionUid, uid, childSort++));
      }
    }

    return Folder(
      uid: uid,
      name: name,
      collectionUid: collectionUid,
      parentFolderUid: parentFolderUid,
      sortOrder: sortOrder,
      requests: requests,
      subFolders: subFolders,
      createdAt: now,
      updatedAt: now,
    );
  }

  static HttpRequest _parseRequest(
    Map<String, dynamic> map,
    String collectionUid,
    String? folderUid,
    int sortOrder,
  ) {
    final name = (map['name'] as String?) ?? 'Request';
    final req = map['request'] as Map<String, dynamic>? ?? {};
    final now = DateTime.now();

    final method = HttpMethod.fromString(
      (req['method'] as String?) ?? 'GET',
    );

    // URL
    final urlObj = req['url'];
    String url = '';
    final params = <RequestParam>[];
    if (urlObj is String) {
      url = urlObj;
    } else if (urlObj is Map<String, dynamic>) {
      final raw = (urlObj['raw'] as String?) ?? '';
      final query = urlObj['query'] as List<dynamic>? ?? [];
      for (final q in query) {
        final qMap = q as Map<String, dynamic>;
        params.add(RequestParam(
          key: (qMap['key'] as String?) ?? '',
          value: (qMap['value'] as String?) ?? '',
          isEnabled: (qMap['disabled'] as bool? ?? false) == false,
        ));
      }
      // Use raw URL but strip inline query string when we have a parsed query
      // array — otherwise params are duplicated on execution.
      if (params.isNotEmpty && raw.contains('?')) {
        url = raw.substring(0, raw.indexOf('?'));
      } else {
        url = raw;
      }
    }

    // Headers
    final headerList = req['header'] as List<dynamic>? ?? [];
    final headers = headerList.map((h) {
      final hMap = h as Map<String, dynamic>;
      return RequestHeader(
        key: (hMap['key'] as String?) ?? '',
        value: (hMap['value'] as String?) ?? '',
        isEnabled: (hMap['disabled'] as bool? ?? false) == false,
      );
    }).toList();

    // Body
    final bodyMap = req['body'] as Map<String, dynamic>?;
    final body = _parseBody(bodyMap);

    // Auth
    final authMap = req['auth'] as Map<String, dynamic>?;
    final auth = _parseAuth(authMap);

    return HttpRequest(
      uid: _uuid.v4(),
      name: name,
      method: method,
      url: url,
      params: params,
      headers: headers,
      body: body,
      auth: auth,
      collectionUid: collectionUid,
      folderUid: folderUid,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  static RequestBody _parseBody(Map<String, dynamic>? bodyMap) {
    if (bodyMap == null) return const NoBody();
    final mode = bodyMap['mode'] as String?;
    switch (mode) {
      case 'raw':
        final raw = (bodyMap['raw'] as String?) ?? '';
        final options = bodyMap['options'] as Map<String, dynamic>?;
        final lang =
            (options?['raw'] as Map<String, dynamic>?)?['language'] as String?;
        if (lang == 'json') return RawJsonBody(content: raw);
        if (lang == 'xml') return RawXmlBody(content: raw);
        if (lang == 'html') return RawHtmlBody(content: raw);
        return RawTextBody(content: raw);
      case 'urlencoded':
        final fields = (bodyMap['urlencoded'] as List<dynamic>? ?? [])
            .map((e) {
              final m = e as Map<String, dynamic>;
              return KeyValuePair(
                key: (m['key'] as String?) ?? '',
                value: (m['value'] as String?) ?? '',
                isEnabled: (m['disabled'] as bool? ?? false) == false,
              );
            })
            .toList();
        return UrlEncodedBody(fields: fields);
      case 'formdata':
        final formFields = (bodyMap['formdata'] as List<dynamic>? ?? [])
            .map((e) {
              final m = e as Map<String, dynamic>;
              final isFile = (m['type'] as String?) == 'file';
              final src = m['src'];
              final filePath = isFile
                  ? (src is String ? src : null)
                  : null;
              return FormDataField(
                key: (m['key'] as String?) ?? '',
                value: isFile ? '' : (m['value'] as String?) ?? '',
                isEnabled: (m['disabled'] as bool? ?? false) == false,
                isFile: isFile,
                filePath: filePath,
              );
            })
            .toList();
        return FormDataBody(fields: formFields);
      default:
        return const NoBody();
    }
  }

  static AuthConfig _parseAuth(Map<String, dynamic>? authMap) {
    if (authMap == null) return const NoAuth();
    final type = authMap['type'] as String?;
    switch (type) {
      case 'bearer':
        final bearer = authMap['bearer'] as List<dynamic>? ?? [];
        final token = bearer
                .cast<Map<String, dynamic>>()
                .firstWhere(
                  (e) => e['key'] == 'token',
                  orElse: () => {'value': ''},
                )['value'] as String? ??
            '';
        return BearerAuth(token: token);
      case 'basic':
        final basic = authMap['basic'] as List<dynamic>? ?? [];
        final basicMap = {
          for (final e in basic.cast<Map<String, dynamic>>())
            e['key'] as String: e['value'],
        };
        return BasicAuth(
          username: (basicMap['username'] as String?) ?? '',
          password: (basicMap['password'] as String?) ?? '',
        );
      case 'apikey':
        final apikey = authMap['apikey'] as List<dynamic>? ?? [];
        final keyMap = {
          for (final e in apikey.cast<Map<String, dynamic>>())
            e['key'] as String: e['value'],
        };
        return ApiKeyAuth(
          key: (keyMap['key'] as String?) ?? '',
          value: (keyMap['value'] as String?) ?? '',
          addTo: (keyMap['in'] as String?) == 'query'
              ? ApiKeyAddTo.query
              : ApiKeyAddTo.header,
        );
      default:
        return const NoAuth();
    }
  }

  /// Scans a raw Postman collection JSON string and returns every unique
  /// `{{variable}}` name referenced anywhere (URLs, headers, bodies, auth).
  /// Dynamic built-in vars that start with `$` are excluded.
  static List<String> extractVariableNames(String jsonString) {
    final pattern = RegExp(r'\{\{([^}]+)\}\}');
    return pattern
        .allMatches(jsonString)
        .map((m) => m.group(1)!.trim())
        .where((v) => v.isNotEmpty && !v.startsWith(r'$'))
        .toSet()
        .toList()
      ..sort();
  }

  /// Parses a Postman environment export JSON string into an [Environment].
  /// Supports both v2.0 (`values` array) and v2.1 formats.
  static Environment importEnvironment(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final name = (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Imported Environment';
      final values = json['values'] as List<dynamic>? ?? [];
      final now = DateTime.now();

      final variables = values
          .cast<Map<String, dynamic>>()
          .where((v) => ((v['key'] as String?) ?? '').isNotEmpty)
          .map((v) {
            final isSecret = (v['type'] as String?) == 'secret';
            return EnvironmentVariable(
              uid: _uuid.v4(),
              key: (v['key'] as String).trim(),
              value: (v['value'] as String?) ?? '',
              isEnabled: v['enabled'] as bool? ?? true,
              isSecret: isSecret,
            );
          })
          .toList();

      return Environment(
        uid: _uuid.v4(),
        name: name,
        variables: variables,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw ImportException('Invalid Postman environment: $e');
    }
  }
}
