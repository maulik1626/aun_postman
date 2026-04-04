// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_builder_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RequestBuilderState {
  HttpMethod get method => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  List<RequestParam> get params => throw _privateConstructorUsedError;
  List<RequestHeader> get headers => throw _privateConstructorUsedError;
  RequestBody get body => throw _privateConstructorUsedError;
  AuthConfig get auth => throw _privateConstructorUsedError;
  String? get loadedRequestUid => throw _privateConstructorUsedError;
  String? get collectionUid => throw _privateConstructorUsedError;
  String? get folderUid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isDirty => throw _privateConstructorUsedError;
  List<TestAssertion> get assertions => throw _privateConstructorUsedError;

  /// Create a copy of RequestBuilderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RequestBuilderStateCopyWith<RequestBuilderState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RequestBuilderStateCopyWith<$Res> {
  factory $RequestBuilderStateCopyWith(
    RequestBuilderState value,
    $Res Function(RequestBuilderState) then,
  ) = _$RequestBuilderStateCopyWithImpl<$Res, RequestBuilderState>;
  @useResult
  $Res call({
    HttpMethod method,
    String url,
    List<RequestParam> params,
    List<RequestHeader> headers,
    RequestBody body,
    AuthConfig auth,
    String? loadedRequestUid,
    String? collectionUid,
    String? folderUid,
    String name,
    bool isDirty,
    List<TestAssertion> assertions,
  });

  $RequestBodyCopyWith<$Res> get body;
  $AuthConfigCopyWith<$Res> get auth;
}

/// @nodoc
class _$RequestBuilderStateCopyWithImpl<$Res, $Val extends RequestBuilderState>
    implements $RequestBuilderStateCopyWith<$Res> {
  _$RequestBuilderStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RequestBuilderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? method = null,
    Object? url = null,
    Object? params = null,
    Object? headers = null,
    Object? body = null,
    Object? auth = null,
    Object? loadedRequestUid = freezed,
    Object? collectionUid = freezed,
    Object? folderUid = freezed,
    Object? name = null,
    Object? isDirty = null,
    Object? assertions = null,
  }) {
    return _then(
      _value.copyWith(
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
            loadedRequestUid: freezed == loadedRequestUid
                ? _value.loadedRequestUid
                : loadedRequestUid // ignore: cast_nullable_to_non_nullable
                      as String?,
            collectionUid: freezed == collectionUid
                ? _value.collectionUid
                : collectionUid // ignore: cast_nullable_to_non_nullable
                      as String?,
            folderUid: freezed == folderUid
                ? _value.folderUid
                : folderUid // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            isDirty: null == isDirty
                ? _value.isDirty
                : isDirty // ignore: cast_nullable_to_non_nullable
                      as bool,
            assertions: null == assertions
                ? _value.assertions
                : assertions // ignore: cast_nullable_to_non_nullable
                      as List<TestAssertion>,
          )
          as $Val,
    );
  }

  /// Create a copy of RequestBuilderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RequestBodyCopyWith<$Res> get body {
    return $RequestBodyCopyWith<$Res>(_value.body, (value) {
      return _then(_value.copyWith(body: value) as $Val);
    });
  }

  /// Create a copy of RequestBuilderState
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
abstract class _$$RequestBuilderStateImplCopyWith<$Res>
    implements $RequestBuilderStateCopyWith<$Res> {
  factory _$$RequestBuilderStateImplCopyWith(
    _$RequestBuilderStateImpl value,
    $Res Function(_$RequestBuilderStateImpl) then,
  ) = __$$RequestBuilderStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    HttpMethod method,
    String url,
    List<RequestParam> params,
    List<RequestHeader> headers,
    RequestBody body,
    AuthConfig auth,
    String? loadedRequestUid,
    String? collectionUid,
    String? folderUid,
    String name,
    bool isDirty,
    List<TestAssertion> assertions,
  });

  @override
  $RequestBodyCopyWith<$Res> get body;
  @override
  $AuthConfigCopyWith<$Res> get auth;
}

/// @nodoc
class __$$RequestBuilderStateImplCopyWithImpl<$Res>
    extends _$RequestBuilderStateCopyWithImpl<$Res, _$RequestBuilderStateImpl>
    implements _$$RequestBuilderStateImplCopyWith<$Res> {
  __$$RequestBuilderStateImplCopyWithImpl(
    _$RequestBuilderStateImpl _value,
    $Res Function(_$RequestBuilderStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestBuilderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? method = null,
    Object? url = null,
    Object? params = null,
    Object? headers = null,
    Object? body = null,
    Object? auth = null,
    Object? loadedRequestUid = freezed,
    Object? collectionUid = freezed,
    Object? folderUid = freezed,
    Object? name = null,
    Object? isDirty = null,
    Object? assertions = null,
  }) {
    return _then(
      _$RequestBuilderStateImpl(
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
        loadedRequestUid: freezed == loadedRequestUid
            ? _value.loadedRequestUid
            : loadedRequestUid // ignore: cast_nullable_to_non_nullable
                  as String?,
        collectionUid: freezed == collectionUid
            ? _value.collectionUid
            : collectionUid // ignore: cast_nullable_to_non_nullable
                  as String?,
        folderUid: freezed == folderUid
            ? _value.folderUid
            : folderUid // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        isDirty: null == isDirty
            ? _value.isDirty
            : isDirty // ignore: cast_nullable_to_non_nullable
                  as bool,
        assertions: null == assertions
            ? _value._assertions
            : assertions // ignore: cast_nullable_to_non_nullable
                  as List<TestAssertion>,
      ),
    );
  }
}

/// @nodoc

class _$RequestBuilderStateImpl implements _RequestBuilderState {
  const _$RequestBuilderStateImpl({
    this.method = HttpMethod.get,
    this.url = '',
    final List<RequestParam> params = const [],
    final List<RequestHeader> headers = const [],
    this.body = const NoBody(),
    this.auth = const NoAuth(),
    this.loadedRequestUid,
    this.collectionUid,
    this.folderUid,
    this.name = 'New Request',
    this.isDirty = false,
    final List<TestAssertion> assertions = const [],
  }) : _params = params,
       _headers = headers,
       _assertions = assertions;

  @override
  @JsonKey()
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
  @JsonKey()
  final RequestBody body;
  @override
  @JsonKey()
  final AuthConfig auth;
  @override
  final String? loadedRequestUid;
  @override
  final String? collectionUid;
  @override
  final String? folderUid;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final bool isDirty;
  final List<TestAssertion> _assertions;
  @override
  @JsonKey()
  List<TestAssertion> get assertions {
    if (_assertions is EqualUnmodifiableListView) return _assertions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assertions);
  }

  @override
  String toString() {
    return 'RequestBuilderState(method: $method, url: $url, params: $params, headers: $headers, body: $body, auth: $auth, loadedRequestUid: $loadedRequestUid, collectionUid: $collectionUid, folderUid: $folderUid, name: $name, isDirty: $isDirty, assertions: $assertions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequestBuilderStateImpl &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality().equals(other._params, _params) &&
            const DeepCollectionEquality().equals(other._headers, _headers) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.auth, auth) || other.auth == auth) &&
            (identical(other.loadedRequestUid, loadedRequestUid) ||
                other.loadedRequestUid == loadedRequestUid) &&
            (identical(other.collectionUid, collectionUid) ||
                other.collectionUid == collectionUid) &&
            (identical(other.folderUid, folderUid) ||
                other.folderUid == folderUid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isDirty, isDirty) || other.isDirty == isDirty) &&
            const DeepCollectionEquality().equals(
              other._assertions,
              _assertions,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    method,
    url,
    const DeepCollectionEquality().hash(_params),
    const DeepCollectionEquality().hash(_headers),
    body,
    auth,
    loadedRequestUid,
    collectionUid,
    folderUid,
    name,
    isDirty,
    const DeepCollectionEquality().hash(_assertions),
  );

  /// Create a copy of RequestBuilderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RequestBuilderStateImplCopyWith<_$RequestBuilderStateImpl> get copyWith =>
      __$$RequestBuilderStateImplCopyWithImpl<_$RequestBuilderStateImpl>(
        this,
        _$identity,
      );
}

abstract class _RequestBuilderState implements RequestBuilderState {
  const factory _RequestBuilderState({
    final HttpMethod method,
    final String url,
    final List<RequestParam> params,
    final List<RequestHeader> headers,
    final RequestBody body,
    final AuthConfig auth,
    final String? loadedRequestUid,
    final String? collectionUid,
    final String? folderUid,
    final String name,
    final bool isDirty,
    final List<TestAssertion> assertions,
  }) = _$RequestBuilderStateImpl;

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
  String? get loadedRequestUid;
  @override
  String? get collectionUid;
  @override
  String? get folderUid;
  @override
  String get name;
  @override
  bool get isDirty;
  @override
  List<TestAssertion> get assertions;

  /// Create a copy of RequestBuilderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RequestBuilderStateImplCopyWith<_$RequestBuilderStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
