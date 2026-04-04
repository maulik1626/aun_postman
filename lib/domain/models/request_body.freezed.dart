// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RequestBody _$RequestBodyFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'none':
      return NoBody.fromJson(json);
    case 'rawJson':
      return RawJsonBody.fromJson(json);
    case 'rawXml':
      return RawXmlBody.fromJson(json);
    case 'rawText':
      return RawTextBody.fromJson(json);
    case 'rawHtml':
      return RawHtmlBody.fromJson(json);
    case 'formData':
      return FormDataBody.fromJson(json);
    case 'urlEncoded':
      return UrlEncodedBody.fromJson(json);
    case 'binary':
      return BinaryBody.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'RequestBody',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$RequestBody {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this RequestBody to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RequestBodyCopyWith<$Res> {
  factory $RequestBodyCopyWith(
    RequestBody value,
    $Res Function(RequestBody) then,
  ) = _$RequestBodyCopyWithImpl<$Res, RequestBody>;
}

/// @nodoc
class _$RequestBodyCopyWithImpl<$Res, $Val extends RequestBody>
    implements $RequestBodyCopyWith<$Res> {
  _$RequestBodyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NoBodyImplCopyWith<$Res> {
  factory _$$NoBodyImplCopyWith(
    _$NoBodyImpl value,
    $Res Function(_$NoBodyImpl) then,
  ) = __$$NoBodyImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NoBodyImplCopyWithImpl<$Res>
    extends _$RequestBodyCopyWithImpl<$Res, _$NoBodyImpl>
    implements _$$NoBodyImplCopyWith<$Res> {
  __$$NoBodyImplCopyWithImpl(
    _$NoBodyImpl _value,
    $Res Function(_$NoBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$NoBodyImpl implements NoBody {
  const _$NoBodyImpl({final String? $type}) : $type = $type ?? 'none';

  factory _$NoBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoBodyImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RequestBody.none()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NoBodyImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) {
    return none();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) {
    return none?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) {
    return none(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) {
    return none?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$NoBodyImplToJson(this);
  }
}

abstract class NoBody implements RequestBody {
  const factory NoBody() = _$NoBodyImpl;

  factory NoBody.fromJson(Map<String, dynamic> json) = _$NoBodyImpl.fromJson;
}

/// @nodoc
abstract class _$$RawJsonBodyImplCopyWith<$Res> {
  factory _$$RawJsonBodyImplCopyWith(
    _$RawJsonBodyImpl value,
    $Res Function(_$RawJsonBodyImpl) then,
  ) = __$$RawJsonBodyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$RawJsonBodyImplCopyWithImpl<$Res>
    extends _$RequestBodyCopyWithImpl<$Res, _$RawJsonBodyImpl>
    implements _$$RawJsonBodyImplCopyWith<$Res> {
  __$$RawJsonBodyImplCopyWithImpl(
    _$RawJsonBodyImpl _value,
    $Res Function(_$RawJsonBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? content = null}) {
    return _then(
      _$RawJsonBodyImpl(
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RawJsonBodyImpl implements RawJsonBody {
  const _$RawJsonBodyImpl({this.content = '', final String? $type})
    : $type = $type ?? 'rawJson';

  factory _$RawJsonBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$RawJsonBodyImplFromJson(json);

  @override
  @JsonKey()
  final String content;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RequestBody.rawJson(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RawJsonBodyImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RawJsonBodyImplCopyWith<_$RawJsonBodyImpl> get copyWith =>
      __$$RawJsonBodyImplCopyWithImpl<_$RawJsonBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) {
    return rawJson(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) {
    return rawJson?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) {
    if (rawJson != null) {
      return rawJson(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) {
    return rawJson(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) {
    return rawJson?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) {
    if (rawJson != null) {
      return rawJson(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RawJsonBodyImplToJson(this);
  }
}

abstract class RawJsonBody implements RequestBody {
  const factory RawJsonBody({final String content}) = _$RawJsonBodyImpl;

  factory RawJsonBody.fromJson(Map<String, dynamic> json) =
      _$RawJsonBodyImpl.fromJson;

  String get content;

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RawJsonBodyImplCopyWith<_$RawJsonBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RawXmlBodyImplCopyWith<$Res> {
  factory _$$RawXmlBodyImplCopyWith(
    _$RawXmlBodyImpl value,
    $Res Function(_$RawXmlBodyImpl) then,
  ) = __$$RawXmlBodyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$RawXmlBodyImplCopyWithImpl<$Res>
    extends _$RequestBodyCopyWithImpl<$Res, _$RawXmlBodyImpl>
    implements _$$RawXmlBodyImplCopyWith<$Res> {
  __$$RawXmlBodyImplCopyWithImpl(
    _$RawXmlBodyImpl _value,
    $Res Function(_$RawXmlBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? content = null}) {
    return _then(
      _$RawXmlBodyImpl(
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RawXmlBodyImpl implements RawXmlBody {
  const _$RawXmlBodyImpl({this.content = '', final String? $type})
    : $type = $type ?? 'rawXml';

  factory _$RawXmlBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$RawXmlBodyImplFromJson(json);

  @override
  @JsonKey()
  final String content;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RequestBody.rawXml(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RawXmlBodyImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RawXmlBodyImplCopyWith<_$RawXmlBodyImpl> get copyWith =>
      __$$RawXmlBodyImplCopyWithImpl<_$RawXmlBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) {
    return rawXml(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) {
    return rawXml?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) {
    if (rawXml != null) {
      return rawXml(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) {
    return rawXml(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) {
    return rawXml?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) {
    if (rawXml != null) {
      return rawXml(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RawXmlBodyImplToJson(this);
  }
}

abstract class RawXmlBody implements RequestBody {
  const factory RawXmlBody({final String content}) = _$RawXmlBodyImpl;

  factory RawXmlBody.fromJson(Map<String, dynamic> json) =
      _$RawXmlBodyImpl.fromJson;

  String get content;

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RawXmlBodyImplCopyWith<_$RawXmlBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RawTextBodyImplCopyWith<$Res> {
  factory _$$RawTextBodyImplCopyWith(
    _$RawTextBodyImpl value,
    $Res Function(_$RawTextBodyImpl) then,
  ) = __$$RawTextBodyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$RawTextBodyImplCopyWithImpl<$Res>
    extends _$RequestBodyCopyWithImpl<$Res, _$RawTextBodyImpl>
    implements _$$RawTextBodyImplCopyWith<$Res> {
  __$$RawTextBodyImplCopyWithImpl(
    _$RawTextBodyImpl _value,
    $Res Function(_$RawTextBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? content = null}) {
    return _then(
      _$RawTextBodyImpl(
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RawTextBodyImpl implements RawTextBody {
  const _$RawTextBodyImpl({this.content = '', final String? $type})
    : $type = $type ?? 'rawText';

  factory _$RawTextBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$RawTextBodyImplFromJson(json);

  @override
  @JsonKey()
  final String content;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RequestBody.rawText(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RawTextBodyImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RawTextBodyImplCopyWith<_$RawTextBodyImpl> get copyWith =>
      __$$RawTextBodyImplCopyWithImpl<_$RawTextBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) {
    return rawText(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) {
    return rawText?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) {
    if (rawText != null) {
      return rawText(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) {
    return rawText(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) {
    return rawText?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) {
    if (rawText != null) {
      return rawText(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RawTextBodyImplToJson(this);
  }
}

abstract class RawTextBody implements RequestBody {
  const factory RawTextBody({final String content}) = _$RawTextBodyImpl;

  factory RawTextBody.fromJson(Map<String, dynamic> json) =
      _$RawTextBodyImpl.fromJson;

  String get content;

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RawTextBodyImplCopyWith<_$RawTextBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RawHtmlBodyImplCopyWith<$Res> {
  factory _$$RawHtmlBodyImplCopyWith(
    _$RawHtmlBodyImpl value,
    $Res Function(_$RawHtmlBodyImpl) then,
  ) = __$$RawHtmlBodyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$RawHtmlBodyImplCopyWithImpl<$Res>
    extends _$RequestBodyCopyWithImpl<$Res, _$RawHtmlBodyImpl>
    implements _$$RawHtmlBodyImplCopyWith<$Res> {
  __$$RawHtmlBodyImplCopyWithImpl(
    _$RawHtmlBodyImpl _value,
    $Res Function(_$RawHtmlBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? content = null}) {
    return _then(
      _$RawHtmlBodyImpl(
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RawHtmlBodyImpl implements RawHtmlBody {
  const _$RawHtmlBodyImpl({this.content = '', final String? $type})
    : $type = $type ?? 'rawHtml';

  factory _$RawHtmlBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$RawHtmlBodyImplFromJson(json);

  @override
  @JsonKey()
  final String content;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RequestBody.rawHtml(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RawHtmlBodyImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RawHtmlBodyImplCopyWith<_$RawHtmlBodyImpl> get copyWith =>
      __$$RawHtmlBodyImplCopyWithImpl<_$RawHtmlBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) {
    return rawHtml(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) {
    return rawHtml?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) {
    if (rawHtml != null) {
      return rawHtml(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) {
    return rawHtml(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) {
    return rawHtml?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) {
    if (rawHtml != null) {
      return rawHtml(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RawHtmlBodyImplToJson(this);
  }
}

abstract class RawHtmlBody implements RequestBody {
  const factory RawHtmlBody({final String content}) = _$RawHtmlBodyImpl;

  factory RawHtmlBody.fromJson(Map<String, dynamic> json) =
      _$RawHtmlBodyImpl.fromJson;

  String get content;

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RawHtmlBodyImplCopyWith<_$RawHtmlBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FormDataBodyImplCopyWith<$Res> {
  factory _$$FormDataBodyImplCopyWith(
    _$FormDataBodyImpl value,
    $Res Function(_$FormDataBodyImpl) then,
  ) = __$$FormDataBodyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<FormDataField> fields});
}

/// @nodoc
class __$$FormDataBodyImplCopyWithImpl<$Res>
    extends _$RequestBodyCopyWithImpl<$Res, _$FormDataBodyImpl>
    implements _$$FormDataBodyImplCopyWith<$Res> {
  __$$FormDataBodyImplCopyWithImpl(
    _$FormDataBodyImpl _value,
    $Res Function(_$FormDataBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? fields = null}) {
    return _then(
      _$FormDataBodyImpl(
        fields: null == fields
            ? _value._fields
            : fields // ignore: cast_nullable_to_non_nullable
                  as List<FormDataField>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FormDataBodyImpl implements FormDataBody {
  const _$FormDataBodyImpl({
    final List<FormDataField> fields = const [],
    final String? $type,
  }) : _fields = fields,
       $type = $type ?? 'formData';

  factory _$FormDataBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$FormDataBodyImplFromJson(json);

  final List<FormDataField> _fields;
  @override
  @JsonKey()
  List<FormDataField> get fields {
    if (_fields is EqualUnmodifiableListView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fields);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RequestBody.formData(fields: $fields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FormDataBodyImpl &&
            const DeepCollectionEquality().equals(other._fields, _fields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_fields));

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FormDataBodyImplCopyWith<_$FormDataBodyImpl> get copyWith =>
      __$$FormDataBodyImplCopyWithImpl<_$FormDataBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) {
    return formData(fields);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) {
    return formData?.call(fields);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) {
    if (formData != null) {
      return formData(fields);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) {
    return formData(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) {
    return formData?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) {
    if (formData != null) {
      return formData(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$FormDataBodyImplToJson(this);
  }
}

abstract class FormDataBody implements RequestBody {
  const factory FormDataBody({final List<FormDataField> fields}) =
      _$FormDataBodyImpl;

  factory FormDataBody.fromJson(Map<String, dynamic> json) =
      _$FormDataBodyImpl.fromJson;

  List<FormDataField> get fields;

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FormDataBodyImplCopyWith<_$FormDataBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UrlEncodedBodyImplCopyWith<$Res> {
  factory _$$UrlEncodedBodyImplCopyWith(
    _$UrlEncodedBodyImpl value,
    $Res Function(_$UrlEncodedBodyImpl) then,
  ) = __$$UrlEncodedBodyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<KeyValuePair> fields});
}

/// @nodoc
class __$$UrlEncodedBodyImplCopyWithImpl<$Res>
    extends _$RequestBodyCopyWithImpl<$Res, _$UrlEncodedBodyImpl>
    implements _$$UrlEncodedBodyImplCopyWith<$Res> {
  __$$UrlEncodedBodyImplCopyWithImpl(
    _$UrlEncodedBodyImpl _value,
    $Res Function(_$UrlEncodedBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? fields = null}) {
    return _then(
      _$UrlEncodedBodyImpl(
        fields: null == fields
            ? _value._fields
            : fields // ignore: cast_nullable_to_non_nullable
                  as List<KeyValuePair>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UrlEncodedBodyImpl implements UrlEncodedBody {
  const _$UrlEncodedBodyImpl({
    final List<KeyValuePair> fields = const [],
    final String? $type,
  }) : _fields = fields,
       $type = $type ?? 'urlEncoded';

  factory _$UrlEncodedBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$UrlEncodedBodyImplFromJson(json);

  final List<KeyValuePair> _fields;
  @override
  @JsonKey()
  List<KeyValuePair> get fields {
    if (_fields is EqualUnmodifiableListView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fields);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RequestBody.urlEncoded(fields: $fields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UrlEncodedBodyImpl &&
            const DeepCollectionEquality().equals(other._fields, _fields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_fields));

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UrlEncodedBodyImplCopyWith<_$UrlEncodedBodyImpl> get copyWith =>
      __$$UrlEncodedBodyImplCopyWithImpl<_$UrlEncodedBodyImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) {
    return urlEncoded(fields);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) {
    return urlEncoded?.call(fields);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) {
    if (urlEncoded != null) {
      return urlEncoded(fields);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) {
    return urlEncoded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) {
    return urlEncoded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) {
    if (urlEncoded != null) {
      return urlEncoded(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$UrlEncodedBodyImplToJson(this);
  }
}

abstract class UrlEncodedBody implements RequestBody {
  const factory UrlEncodedBody({final List<KeyValuePair> fields}) =
      _$UrlEncodedBodyImpl;

  factory UrlEncodedBody.fromJson(Map<String, dynamic> json) =
      _$UrlEncodedBodyImpl.fromJson;

  List<KeyValuePair> get fields;

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UrlEncodedBodyImplCopyWith<_$UrlEncodedBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BinaryBodyImplCopyWith<$Res> {
  factory _$$BinaryBodyImplCopyWith(
    _$BinaryBodyImpl value,
    $Res Function(_$BinaryBodyImpl) then,
  ) = __$$BinaryBodyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filePath, String? mimeType});
}

/// @nodoc
class __$$BinaryBodyImplCopyWithImpl<$Res>
    extends _$RequestBodyCopyWithImpl<$Res, _$BinaryBodyImpl>
    implements _$$BinaryBodyImplCopyWith<$Res> {
  __$$BinaryBodyImplCopyWithImpl(
    _$BinaryBodyImpl _value,
    $Res Function(_$BinaryBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filePath = null, Object? mimeType = freezed}) {
    return _then(
      _$BinaryBodyImpl(
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
        mimeType: freezed == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BinaryBodyImpl implements BinaryBody {
  const _$BinaryBodyImpl({
    required this.filePath,
    this.mimeType,
    final String? $type,
  }) : $type = $type ?? 'binary';

  factory _$BinaryBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$BinaryBodyImplFromJson(json);

  @override
  final String filePath;
  @override
  final String? mimeType;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RequestBody.binary(filePath: $filePath, mimeType: $mimeType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BinaryBodyImpl &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, filePath, mimeType);

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BinaryBodyImplCopyWith<_$BinaryBodyImpl> get copyWith =>
      __$$BinaryBodyImplCopyWithImpl<_$BinaryBodyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String content) rawJson,
    required TResult Function(String content) rawXml,
    required TResult Function(String content) rawText,
    required TResult Function(String content) rawHtml,
    required TResult Function(List<FormDataField> fields) formData,
    required TResult Function(List<KeyValuePair> fields) urlEncoded,
    required TResult Function(String filePath, String? mimeType) binary,
  }) {
    return binary(filePath, mimeType);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(String content)? rawJson,
    TResult? Function(String content)? rawXml,
    TResult? Function(String content)? rawText,
    TResult? Function(String content)? rawHtml,
    TResult? Function(List<FormDataField> fields)? formData,
    TResult? Function(List<KeyValuePair> fields)? urlEncoded,
    TResult? Function(String filePath, String? mimeType)? binary,
  }) {
    return binary?.call(filePath, mimeType);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String content)? rawJson,
    TResult Function(String content)? rawXml,
    TResult Function(String content)? rawText,
    TResult Function(String content)? rawHtml,
    TResult Function(List<FormDataField> fields)? formData,
    TResult Function(List<KeyValuePair> fields)? urlEncoded,
    TResult Function(String filePath, String? mimeType)? binary,
    required TResult orElse(),
  }) {
    if (binary != null) {
      return binary(filePath, mimeType);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoBody value) none,
    required TResult Function(RawJsonBody value) rawJson,
    required TResult Function(RawXmlBody value) rawXml,
    required TResult Function(RawTextBody value) rawText,
    required TResult Function(RawHtmlBody value) rawHtml,
    required TResult Function(FormDataBody value) formData,
    required TResult Function(UrlEncodedBody value) urlEncoded,
    required TResult Function(BinaryBody value) binary,
  }) {
    return binary(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoBody value)? none,
    TResult? Function(RawJsonBody value)? rawJson,
    TResult? Function(RawXmlBody value)? rawXml,
    TResult? Function(RawTextBody value)? rawText,
    TResult? Function(RawHtmlBody value)? rawHtml,
    TResult? Function(FormDataBody value)? formData,
    TResult? Function(UrlEncodedBody value)? urlEncoded,
    TResult? Function(BinaryBody value)? binary,
  }) {
    return binary?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoBody value)? none,
    TResult Function(RawJsonBody value)? rawJson,
    TResult Function(RawXmlBody value)? rawXml,
    TResult Function(RawTextBody value)? rawText,
    TResult Function(RawHtmlBody value)? rawHtml,
    TResult Function(FormDataBody value)? formData,
    TResult Function(UrlEncodedBody value)? urlEncoded,
    TResult Function(BinaryBody value)? binary,
    required TResult orElse(),
  }) {
    if (binary != null) {
      return binary(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$BinaryBodyImplToJson(this);
  }
}

abstract class BinaryBody implements RequestBody {
  const factory BinaryBody({
    required final String filePath,
    final String? mimeType,
  }) = _$BinaryBodyImpl;

  factory BinaryBody.fromJson(Map<String, dynamic> json) =
      _$BinaryBodyImpl.fromJson;

  String get filePath;
  String? get mimeType;

  /// Create a copy of RequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BinaryBodyImplCopyWith<_$BinaryBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
