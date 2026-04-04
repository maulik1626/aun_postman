// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'http_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HttpResponse _$HttpResponseFromJson(Map<String, dynamic> json) {
  return _HttpResponse.fromJson(json);
}

/// @nodoc
mixin _$HttpResponse {
  int get statusCode => throw _privateConstructorUsedError;
  String get statusMessage => throw _privateConstructorUsedError;
  Map<String, String> get headers => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  List<ResponseCookie> get cookies => throw _privateConstructorUsedError;
  DateTime get receivedAt => throw _privateConstructorUsedError;

  /// Serializes this HttpResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HttpResponseCopyWith<HttpResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HttpResponseCopyWith<$Res> {
  factory $HttpResponseCopyWith(
    HttpResponse value,
    $Res Function(HttpResponse) then,
  ) = _$HttpResponseCopyWithImpl<$Res, HttpResponse>;
  @useResult
  $Res call({
    int statusCode,
    String statusMessage,
    Map<String, String> headers,
    String body,
    int durationMs,
    int sizeBytes,
    List<ResponseCookie> cookies,
    DateTime receivedAt,
  });
}

/// @nodoc
class _$HttpResponseCopyWithImpl<$Res, $Val extends HttpResponse>
    implements $HttpResponseCopyWith<$Res> {
  _$HttpResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statusCode = null,
    Object? statusMessage = null,
    Object? headers = null,
    Object? body = null,
    Object? durationMs = null,
    Object? sizeBytes = null,
    Object? cookies = null,
    Object? receivedAt = null,
  }) {
    return _then(
      _value.copyWith(
            statusCode: null == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int,
            statusMessage: null == statusMessage
                ? _value.statusMessage
                : statusMessage // ignore: cast_nullable_to_non_nullable
                      as String,
            headers: null == headers
                ? _value.headers
                : headers // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            durationMs: null == durationMs
                ? _value.durationMs
                : durationMs // ignore: cast_nullable_to_non_nullable
                      as int,
            sizeBytes: null == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            cookies: null == cookies
                ? _value.cookies
                : cookies // ignore: cast_nullable_to_non_nullable
                      as List<ResponseCookie>,
            receivedAt: null == receivedAt
                ? _value.receivedAt
                : receivedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HttpResponseImplCopyWith<$Res>
    implements $HttpResponseCopyWith<$Res> {
  factory _$$HttpResponseImplCopyWith(
    _$HttpResponseImpl value,
    $Res Function(_$HttpResponseImpl) then,
  ) = __$$HttpResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int statusCode,
    String statusMessage,
    Map<String, String> headers,
    String body,
    int durationMs,
    int sizeBytes,
    List<ResponseCookie> cookies,
    DateTime receivedAt,
  });
}

/// @nodoc
class __$$HttpResponseImplCopyWithImpl<$Res>
    extends _$HttpResponseCopyWithImpl<$Res, _$HttpResponseImpl>
    implements _$$HttpResponseImplCopyWith<$Res> {
  __$$HttpResponseImplCopyWithImpl(
    _$HttpResponseImpl _value,
    $Res Function(_$HttpResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statusCode = null,
    Object? statusMessage = null,
    Object? headers = null,
    Object? body = null,
    Object? durationMs = null,
    Object? sizeBytes = null,
    Object? cookies = null,
    Object? receivedAt = null,
  }) {
    return _then(
      _$HttpResponseImpl(
        statusCode: null == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int,
        statusMessage: null == statusMessage
            ? _value.statusMessage
            : statusMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        headers: null == headers
            ? _value._headers
            : headers // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        durationMs: null == durationMs
            ? _value.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        sizeBytes: null == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        cookies: null == cookies
            ? _value._cookies
            : cookies // ignore: cast_nullable_to_non_nullable
                  as List<ResponseCookie>,
        receivedAt: null == receivedAt
            ? _value.receivedAt
            : receivedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HttpResponseImpl implements _HttpResponse {
  const _$HttpResponseImpl({
    required this.statusCode,
    required this.statusMessage,
    final Map<String, String> headers = const {},
    this.body = '',
    required this.durationMs,
    required this.sizeBytes,
    final List<ResponseCookie> cookies = const [],
    required this.receivedAt,
  }) : _headers = headers,
       _cookies = cookies;

  factory _$HttpResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HttpResponseImplFromJson(json);

  @override
  final int statusCode;
  @override
  final String statusMessage;
  final Map<String, String> _headers;
  @override
  @JsonKey()
  Map<String, String> get headers {
    if (_headers is EqualUnmodifiableMapView) return _headers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_headers);
  }

  @override
  @JsonKey()
  final String body;
  @override
  final int durationMs;
  @override
  final int sizeBytes;
  final List<ResponseCookie> _cookies;
  @override
  @JsonKey()
  List<ResponseCookie> get cookies {
    if (_cookies is EqualUnmodifiableListView) return _cookies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cookies);
  }

  @override
  final DateTime receivedAt;

  @override
  String toString() {
    return 'HttpResponse(statusCode: $statusCode, statusMessage: $statusMessage, headers: $headers, body: $body, durationMs: $durationMs, sizeBytes: $sizeBytes, cookies: $cookies, receivedAt: $receivedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HttpResponseImpl &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            (identical(other.statusMessage, statusMessage) ||
                other.statusMessage == statusMessage) &&
            const DeepCollectionEquality().equals(other._headers, _headers) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            const DeepCollectionEquality().equals(other._cookies, _cookies) &&
            (identical(other.receivedAt, receivedAt) ||
                other.receivedAt == receivedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    statusCode,
    statusMessage,
    const DeepCollectionEquality().hash(_headers),
    body,
    durationMs,
    sizeBytes,
    const DeepCollectionEquality().hash(_cookies),
    receivedAt,
  );

  /// Create a copy of HttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HttpResponseImplCopyWith<_$HttpResponseImpl> get copyWith =>
      __$$HttpResponseImplCopyWithImpl<_$HttpResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HttpResponseImplToJson(this);
  }
}

abstract class _HttpResponse implements HttpResponse {
  const factory _HttpResponse({
    required final int statusCode,
    required final String statusMessage,
    final Map<String, String> headers,
    final String body,
    required final int durationMs,
    required final int sizeBytes,
    final List<ResponseCookie> cookies,
    required final DateTime receivedAt,
  }) = _$HttpResponseImpl;

  factory _HttpResponse.fromJson(Map<String, dynamic> json) =
      _$HttpResponseImpl.fromJson;

  @override
  int get statusCode;
  @override
  String get statusMessage;
  @override
  Map<String, String> get headers;
  @override
  String get body;
  @override
  int get durationMs;
  @override
  int get sizeBytes;
  @override
  List<ResponseCookie> get cookies;
  @override
  DateTime get receivedAt;

  /// Create a copy of HttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HttpResponseImplCopyWith<_$HttpResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
