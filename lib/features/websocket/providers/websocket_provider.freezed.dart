// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'websocket_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$WebSocketState {
  WsConnectionStatus get status => throw _privateConstructorUsedError;
  List<WebSocketMessage> get messages => throw _privateConstructorUsedError;
  String get connectedUrl => throw _privateConstructorUsedError;
  List<({String key, String value})> get headers =>
      throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of WebSocketState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebSocketStateCopyWith<WebSocketState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebSocketStateCopyWith<$Res> {
  factory $WebSocketStateCopyWith(
    WebSocketState value,
    $Res Function(WebSocketState) then,
  ) = _$WebSocketStateCopyWithImpl<$Res, WebSocketState>;
  @useResult
  $Res call({
    WsConnectionStatus status,
    List<WebSocketMessage> messages,
    String connectedUrl,
    List<({String key, String value})> headers,
    String? error,
  });
}

/// @nodoc
class _$WebSocketStateCopyWithImpl<$Res, $Val extends WebSocketState>
    implements $WebSocketStateCopyWith<$Res> {
  _$WebSocketStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebSocketState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? messages = null,
    Object? connectedUrl = null,
    Object? headers = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as WsConnectionStatus,
            messages: null == messages
                ? _value.messages
                : messages // ignore: cast_nullable_to_non_nullable
                      as List<WebSocketMessage>,
            connectedUrl: null == connectedUrl
                ? _value.connectedUrl
                : connectedUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            headers: null == headers
                ? _value.headers
                : headers // ignore: cast_nullable_to_non_nullable
                      as List<({String key, String value})>,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WebSocketStateImplCopyWith<$Res>
    implements $WebSocketStateCopyWith<$Res> {
  factory _$$WebSocketStateImplCopyWith(
    _$WebSocketStateImpl value,
    $Res Function(_$WebSocketStateImpl) then,
  ) = __$$WebSocketStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    WsConnectionStatus status,
    List<WebSocketMessage> messages,
    String connectedUrl,
    List<({String key, String value})> headers,
    String? error,
  });
}

/// @nodoc
class __$$WebSocketStateImplCopyWithImpl<$Res>
    extends _$WebSocketStateCopyWithImpl<$Res, _$WebSocketStateImpl>
    implements _$$WebSocketStateImplCopyWith<$Res> {
  __$$WebSocketStateImplCopyWithImpl(
    _$WebSocketStateImpl _value,
    $Res Function(_$WebSocketStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WebSocketState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? messages = null,
    Object? connectedUrl = null,
    Object? headers = null,
    Object? error = freezed,
  }) {
    return _then(
      _$WebSocketStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as WsConnectionStatus,
        messages: null == messages
            ? _value._messages
            : messages // ignore: cast_nullable_to_non_nullable
                  as List<WebSocketMessage>,
        connectedUrl: null == connectedUrl
            ? _value.connectedUrl
            : connectedUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        headers: null == headers
            ? _value._headers
            : headers // ignore: cast_nullable_to_non_nullable
                  as List<({String key, String value})>,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$WebSocketStateImpl implements _WebSocketState {
  const _$WebSocketStateImpl({
    this.status = WsConnectionStatus.disconnected,
    final List<WebSocketMessage> messages = const [],
    this.connectedUrl = '',
    final List<({String key, String value})> headers = const [],
    this.error,
  }) : _messages = messages,
       _headers = headers;

  @override
  @JsonKey()
  final WsConnectionStatus status;
  final List<WebSocketMessage> _messages;
  @override
  @JsonKey()
  List<WebSocketMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  @JsonKey()
  final String connectedUrl;
  final List<({String key, String value})> _headers;
  @override
  @JsonKey()
  List<({String key, String value})> get headers {
    if (_headers is EqualUnmodifiableListView) return _headers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_headers);
  }

  @override
  final String? error;

  @override
  String toString() {
    return 'WebSocketState(status: $status, messages: $messages, connectedUrl: $connectedUrl, headers: $headers, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebSocketStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.connectedUrl, connectedUrl) ||
                other.connectedUrl == connectedUrl) &&
            const DeepCollectionEquality().equals(other._headers, _headers) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    const DeepCollectionEquality().hash(_messages),
    connectedUrl,
    const DeepCollectionEquality().hash(_headers),
    error,
  );

  /// Create a copy of WebSocketState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebSocketStateImplCopyWith<_$WebSocketStateImpl> get copyWith =>
      __$$WebSocketStateImplCopyWithImpl<_$WebSocketStateImpl>(
        this,
        _$identity,
      );
}

abstract class _WebSocketState implements WebSocketState {
  const factory _WebSocketState({
    final WsConnectionStatus status,
    final List<WebSocketMessage> messages,
    final String connectedUrl,
    final List<({String key, String value})> headers,
    final String? error,
  }) = _$WebSocketStateImpl;

  @override
  WsConnectionStatus get status;
  @override
  List<WebSocketMessage> get messages;
  @override
  String get connectedUrl;
  @override
  List<({String key, String value})> get headers;
  @override
  String? get error;

  /// Create a copy of WebSocketState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebSocketStateImplCopyWith<_$WebSocketStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
