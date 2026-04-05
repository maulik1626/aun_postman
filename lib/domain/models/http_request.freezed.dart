// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'http_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HttpRequest _$HttpRequestFromJson(Map<String, dynamic> json) {
  return _HttpRequest.fromJson(json);
}

/// @nodoc
mixin _$HttpRequest {
  String get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  HttpMethod get method => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  List<RequestParam> get params => throw _privateConstructorUsedError;
  List<RequestHeader> get headers => throw _privateConstructorUsedError;
  RequestBody get body => throw _privateConstructorUsedError;
  AuthConfig get auth => throw _privateConstructorUsedError;
  String? get collectionUid => throw _privateConstructorUsedError;
  String? get folderUid => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(fromJson: assertionsFromJson, toJson: assertionsToJson)
  List<TestAssertion> get assertions => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this HttpRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HttpRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HttpRequestCopyWith<HttpRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HttpRequestCopyWith<$Res> {
  factory $HttpRequestCopyWith(
    HttpRequest value,
    $Res Function(HttpRequest) then,
  ) = _$HttpRequestCopyWithImpl<$Res, HttpRequest>;
  @useResult
  $Res call({
    String uid,
    String name,
    HttpMethod method,
    String url,
    List<RequestParam> params,
    List<RequestHeader> headers,
    RequestBody body,
    AuthConfig auth,
    String? collectionUid,
    String? folderUid,
    int sortOrder,
    @JsonKey(fromJson: assertionsFromJson, toJson: assertionsToJson)
    List<TestAssertion> assertions,
    DateTime createdAt,
    DateTime updatedAt,
  });

  $RequestBodyCopyWith<$Res> get body;
  $AuthConfigCopyWith<$Res> get auth;
}

/// @nodoc
class _$HttpRequestCopyWithImpl<$Res, $Val extends HttpRequest>
    implements $HttpRequestCopyWith<$Res> {
  _$HttpRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HttpRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? method = null,
    Object? url = null,
    Object? params = null,
    Object? headers = null,
    Object? body = null,
    Object? auth = null,
    Object? collectionUid = freezed,
    Object? folderUid = freezed,
    Object? sortOrder = null,
    Object? assertions = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as HttpMethod,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            params: null == params
                ? _value.params
                : params // ignore: cast_nullable_to_non_nullable
                      as List<RequestParam>,
            headers: null == headers
                ? _value.headers
                : headers // ignore: cast_nullable_to_non_nullable
                      as List<RequestHeader>,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as RequestBody,
            auth: null == auth
                ? _value.auth
                : auth // ignore: cast_nullable_to_non_nullable
                      as AuthConfig,
            collectionUid: freezed == collectionUid
                ? _value.collectionUid
                : collectionUid // ignore: cast_nullable_to_non_nullable
                      as String?,
            folderUid: freezed == folderUid
                ? _value.folderUid
                : folderUid // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            assertions: null == assertions
                ? _value.assertions
                : assertions // ignore: cast_nullable_to_non_nullable
                      as List<TestAssertion>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of HttpRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RequestBodyCopyWith<$Res> get body {
    return $RequestBodyCopyWith<$Res>(_value.body, (value) {
      return _then(_value.copyWith(body: value) as $Val);
    });
  }

  /// Create a copy of HttpRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthConfigCopyWith<$Res> get auth {
    return $AuthConfigCopyWith<$Res>(_value.auth, (value) {
      return _then(_value.copyWith(auth: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HttpRequestImplCopyWith<$Res>
    implements $HttpRequestCopyWith<$Res> {
  factory _$$HttpRequestImplCopyWith(
    _$HttpRequestImpl value,
    $Res Function(_$HttpRequestImpl) then,
  ) = __$$HttpRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String name,
    HttpMethod method,
    String url,
    List<RequestParam> params,
    List<RequestHeader> headers,
    RequestBody body,
    AuthConfig auth,
    String? collectionUid,
    String? folderUid,
    int sortOrder,
    @JsonKey(fromJson: assertionsFromJson, toJson: assertionsToJson)
    List<TestAssertion> assertions,
    DateTime createdAt,
    DateTime updatedAt,
  });

  @override
  $RequestBodyCopyWith<$Res> get body;
  @override
  $AuthConfigCopyWith<$Res> get auth;
}

/// @nodoc
class __$$HttpRequestImplCopyWithImpl<$Res>
    extends _$HttpRequestCopyWithImpl<$Res, _$HttpRequestImpl>
    implements _$$HttpRequestImplCopyWith<$Res> {
  __$$HttpRequestImplCopyWithImpl(
    _$HttpRequestImpl _value,
    $Res Function(_$HttpRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HttpRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? method = null,
    Object? url = null,
    Object? params = null,
    Object? headers = null,
    Object? body = null,
    Object? auth = null,
    Object? collectionUid = freezed,
    Object? folderUid = freezed,
    Object? sortOrder = null,
    Object? assertions = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$HttpRequestImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as HttpMethod,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        params: null == params
            ? _value._params
            : params // ignore: cast_nullable_to_non_nullable
                  as List<RequestParam>,
        headers: null == headers
            ? _value._headers
            : headers // ignore: cast_nullable_to_non_nullable
                  as List<RequestHeader>,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as RequestBody,
        auth: null == auth
            ? _value.auth
            : auth // ignore: cast_nullable_to_non_nullable
                  as AuthConfig,
        collectionUid: freezed == collectionUid
            ? _value.collectionUid
            : collectionUid // ignore: cast_nullable_to_non_nullable
                  as String?,
        folderUid: freezed == folderUid
            ? _value.folderUid
            : folderUid // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        assertions: null == assertions
            ? _value._assertions
            : assertions // ignore: cast_nullable_to_non_nullable
                  as List<TestAssertion>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HttpRequestImpl implements _HttpRequest {
  const _$HttpRequestImpl({
    required this.uid,
    required this.name,
    required this.method,
    this.url = '',
    final List<RequestParam> params = const [],
    final List<RequestHeader> headers = const [],
    required this.body,
    required this.auth,
    this.collectionUid,
    this.folderUid,
    this.sortOrder = 0,
    @JsonKey(fromJson: assertionsFromJson, toJson: assertionsToJson)
    final List<TestAssertion> assertions = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : _params = params,
       _headers = headers,
       _assertions = assertions;

  factory _$HttpRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$HttpRequestImplFromJson(json);

  @override
  final String uid;
  @override
  final String name;
  @override
  final HttpMethod method;
  @override
  @JsonKey()
  final String url;
  final List<RequestParam> _params;
  @override
  @JsonKey()
  List<RequestParam> get params {
    if (_params is EqualUnmodifiableListView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_params);
  }

  final List<RequestHeader> _headers;
  @override
  @JsonKey()
  List<RequestHeader> get headers {
    if (_headers is EqualUnmodifiableListView) return _headers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_headers);
  }

  @override
  final RequestBody body;
  @override
  final AuthConfig auth;
  @override
  final String? collectionUid;
  @override
  final String? folderUid;
  @override
  @JsonKey()
  final int sortOrder;
  final List<TestAssertion> _assertions;
  @override
  @JsonKey(fromJson: assertionsFromJson, toJson: assertionsToJson)
  List<TestAssertion> get assertions {
    if (_assertions is EqualUnmodifiableListView) return _assertions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assertions);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'HttpRequest(uid: $uid, name: $name, method: $method, url: $url, params: $params, headers: $headers, body: $body, auth: $auth, collectionUid: $collectionUid, folderUid: $folderUid, sortOrder: $sortOrder, assertions: $assertions, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HttpRequestImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality().equals(other._params, _params) &&
            const DeepCollectionEquality().equals(other._headers, _headers) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.auth, auth) || other.auth == auth) &&
            (identical(other.collectionUid, collectionUid) ||
                other.collectionUid == collectionUid) &&
            (identical(other.folderUid, folderUid) ||
                other.folderUid == folderUid) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            const DeepCollectionEquality().equals(
              other._assertions,
              _assertions,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uid,
    name,
    method,
    url,
    const DeepCollectionEquality().hash(_params),
    const DeepCollectionEquality().hash(_headers),
    body,
    auth,
    collectionUid,
    folderUid,
    sortOrder,
    const DeepCollectionEquality().hash(_assertions),
    createdAt,
    updatedAt,
  );

  /// Create a copy of HttpRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HttpRequestImplCopyWith<_$HttpRequestImpl> get copyWith =>
      __$$HttpRequestImplCopyWithImpl<_$HttpRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HttpRequestImplToJson(this);
  }
}

abstract class _HttpRequest implements HttpRequest {
  const factory _HttpRequest({
    required final String uid,
    required final String name,
    required final HttpMethod method,
    final String url,
    final List<RequestParam> params,
    final List<RequestHeader> headers,
    required final RequestBody body,
    required final AuthConfig auth,
    final String? collectionUid,
    final String? folderUid,
    final int sortOrder,
    @JsonKey(fromJson: assertionsFromJson, toJson: assertionsToJson)
    final List<TestAssertion> assertions,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$HttpRequestImpl;

  factory _HttpRequest.fromJson(Map<String, dynamic> json) =
      _$HttpRequestImpl.fromJson;

  @override
  String get uid;
  @override
  String get name;
  @override
  HttpMethod get method;
  @override
  String get url;
  @override
  List<RequestParam> get params;
  @override
  List<RequestHeader> get headers;
  @override
  RequestBody get body;
  @override
  AuthConfig get auth;
  @override
  String? get collectionUid;
  @override
  String? get folderUid;
  @override
  int get sortOrder;
  @override
  @JsonKey(fromJson: assertionsFromJson, toJson: assertionsToJson)
  List<TestAssertion> get assertions;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of HttpRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HttpRequestImplCopyWith<_$HttpRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
