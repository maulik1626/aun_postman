import 'package:aun_reqstudio/domain/enums/http_method.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:aun_reqstudio/domain/models/request_body.dart';
import 'package:aun_reqstudio/domain/models/test_assertion.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';

/// JSON for persisting [RequestBuilderState] (local drafts only).
class RequestBuilderDraftCodec {
  RequestBuilderDraftCodec._();

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return {};
    return Map<String, String>.from(
      raw.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  static Map<String, dynamic> encode(RequestBuilderState s) {
    return {
      'method': s.method.name,
      'url': s.url,
      'params': s.params.map((e) => e.toJson()).toList(),
      'headers': s.headers.map((e) => e.toJson()).toList(),
      'body': s.body.toJson(),
      'auth': s.auth.toJson(),
      'loadedRequestUid': s.loadedRequestUid,
      'collectionUid': s.collectionUid,
      'folderUid': s.folderUid,
      'name': s.name,
      'isRequestNameUserLocked': s.isRequestNameUserLocked,
      'isDirty': s.isDirty,
      'assertions': s.assertions.map((e) => e.toJson()).toList(),
      'historyVariableSnapshot': s.historyVariableSnapshot,
      'preRequestVariables': s.preRequestVariables,
    };
  }

  static RequestBuilderState decode(Map<String, dynamic> m) {
    final params = (m['params'] as List<dynamic>? ?? [])
        .map((e) => RequestParam.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final headers = (m['headers'] as List<dynamic>? ?? [])
        .map((e) => RequestHeader.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final assertions = (m['assertions'] as List<dynamic>? ?? [])
        .map((e) => TestAssertion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final hist = m['historyVariableSnapshot'];
    final pre = m['preRequestVariables'];

    return RequestBuilderState(
      method: HttpMethod.values.firstWhere(
        (e) => e.name == (m['method'] as String? ?? 'get'),
        orElse: () => HttpMethod.get,
      ),
      url: m['url'] as String? ?? '',
      params: params,
      headers: headers,
      body: RequestBody.fromJson(
        Map<String, dynamic>.from(
          m['body'] as Map? ?? const {'runtimeType': 'none'},
        ),
      ),
      auth: AuthConfig.fromJson(
        Map<String, dynamic>.from(
          m['auth'] as Map? ?? const {'runtimeType': 'none'},
        ),
      ),
      loadedRequestUid: m['loadedRequestUid'] as String?,
      collectionUid: m['collectionUid'] as String?,
      folderUid: m['folderUid'] as String?,
      name: m['name'] as String? ?? 'New Request',
      isRequestNameUserLocked: m['isRequestNameUserLocked'] as bool? ?? false,
      isDirty: m['isDirty'] as bool? ?? false,
      assertions: assertions,
      historyVariableSnapshot: _stringMap(hist),
      preRequestVariables: _stringMap(pre),
    );
  }
}
