import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_body.freezed.dart';
part 'request_body.g.dart';

@freezed
sealed class RequestBody with _$RequestBody {
  const factory RequestBody.none() = NoBody;

  const factory RequestBody.rawJson({
    @Default('') String content,
  }) = RawJsonBody;

  const factory RequestBody.rawXml({
    @Default('') String content,
  }) = RawXmlBody;

  const factory RequestBody.rawText({
    @Default('') String content,
  }) = RawTextBody;

  const factory RequestBody.rawHtml({
    @Default('') String content,
  }) = RawHtmlBody;

  const factory RequestBody.formData({
    @Default([]) List<FormDataField> fields,
  }) = FormDataBody;

  const factory RequestBody.urlEncoded({
    @Default([]) List<KeyValuePair> fields,
  }) = UrlEncodedBody;

  const factory RequestBody.binary({
    required String filePath,
    String? mimeType,
  }) = BinaryBody;

  factory RequestBody.fromJson(Map<String, dynamic> json) =>
      _$RequestBodyFromJson(json);
}
