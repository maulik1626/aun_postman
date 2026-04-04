import 'package:aun_postman/domain/enums/http_method.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'http_request.freezed.dart';
part 'http_request.g.dart';

@freezed
class HttpRequest with _$HttpRequest {
  const factory HttpRequest({
    required String uid,
    required String name,
    required HttpMethod method,
    @Default('') String url,
    @Default([]) List<RequestParam> params,
    @Default([]) List<RequestHeader> headers,
    required RequestBody body,
    required AuthConfig auth,
    String? collectionUid,
    String? folderUid,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _HttpRequest;

  factory HttpRequest.fromJson(Map<String, dynamic> json) =>
      _$HttpRequestFromJson(json);
}
