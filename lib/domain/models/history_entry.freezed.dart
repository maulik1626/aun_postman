// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HistoryEntry _$HistoryEntryFromJson(Map<String, dynamic> json) {
  return _HistoryEntry.fromJson(json);
}

/// @nodoc
mixin _$HistoryEntry {
  String get uid => throw _privateConstructorUsedError;
  HttpRequest get request => throw _privateConstructorUsedError;
  HttpResponse get response => throw _privateConstructorUsedError;
  DateTime get executedAt => throw _privateConstructorUsedError;

  /// Active environment variable map at send time (for faithful replay from history).
  Map<String, String> get variableSnapshot =>
      throw _privateConstructorUsedError;

  /// Serializes this HistoryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HistoryEntryCopyWith<HistoryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HistoryEntryCopyWith<$Res> {
  factory $HistoryEntryCopyWith(
    HistoryEntry value,
    $Res Function(HistoryEntry) then,
  ) = _$HistoryEntryCopyWithImpl<$Res, HistoryEntry>;
  @useResult
  $Res call({
    String uid,
    HttpRequest request,
    HttpResponse response,
    DateTime executedAt,
    Map<String, String> variableSnapshot,
  });

  $HttpRequestCopyWith<$Res> get request;
  $HttpResponseCopyWith<$Res> get response;
}

/// @nodoc
class _$HistoryEntryCopyWithImpl<$Res, $Val extends HistoryEntry>
    implements $HistoryEntryCopyWith<$Res> {
  _$HistoryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? request = null,
    Object? response = null,
    Object? executedAt = null,
    Object? variableSnapshot = null,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            request: null == request
                ? _value.request
                : request // ignore: cast_nullable_to_non_nullable
                      as HttpRequest,
            response: null == response
                ? _value.response
                : response // ignore: cast_nullable_to_non_nullable
                      as HttpResponse,
            executedAt: null == executedAt
                ? _value.executedAt
                : executedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            variableSnapshot: null == variableSnapshot
                ? _value.variableSnapshot
                : variableSnapshot // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
          )
          as $Val,
    );
  }

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HttpRequestCopyWith<$Res> get request {
    return $HttpRequestCopyWith<$Res>(_value.request, (value) {
      return _then(_value.copyWith(request: value) as $Val);
    });
  }

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HttpResponseCopyWith<$Res> get response {
    return $HttpResponseCopyWith<$Res>(_value.response, (value) {
      return _then(_value.copyWith(response: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HistoryEntryImplCopyWith<$Res>
    implements $HistoryEntryCopyWith<$Res> {
  factory _$$HistoryEntryImplCopyWith(
    _$HistoryEntryImpl value,
    $Res Function(_$HistoryEntryImpl) then,
  ) = __$$HistoryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    HttpRequest request,
    HttpResponse response,
    DateTime executedAt,
    Map<String, String> variableSnapshot,
  });

  @override
  $HttpRequestCopyWith<$Res> get request;
  @override
  $HttpResponseCopyWith<$Res> get response;
}

/// @nodoc
class __$$HistoryEntryImplCopyWithImpl<$Res>
    extends _$HistoryEntryCopyWithImpl<$Res, _$HistoryEntryImpl>
    implements _$$HistoryEntryImplCopyWith<$Res> {
  __$$HistoryEntryImplCopyWithImpl(
    _$HistoryEntryImpl _value,
    $Res Function(_$HistoryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? request = null,
    Object? response = null,
    Object? executedAt = null,
    Object? variableSnapshot = null,
  }) {
    return _then(
      _$HistoryEntryImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        request: null == request
            ? _value.request
            : request // ignore: cast_nullable_to_non_nullable
                  as HttpRequest,
        response: null == response
            ? _value.response
            : response // ignore: cast_nullable_to_non_nullable
                  as HttpResponse,
        executedAt: null == executedAt
            ? _value.executedAt
            : executedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        variableSnapshot: null == variableSnapshot
            ? _value._variableSnapshot
            : variableSnapshot // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HistoryEntryImpl implements _HistoryEntry {
  const _$HistoryEntryImpl({
    required this.uid,
    required this.request,
    required this.response,
    required this.executedAt,
    final Map<String, String> variableSnapshot = const {},
  }) : _variableSnapshot = variableSnapshot;

  factory _$HistoryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$HistoryEntryImplFromJson(json);

  @override
  final String uid;
  @override
  final HttpRequest request;
  @override
  final HttpResponse response;
  @override
  final DateTime executedAt;

  /// Active environment variable map at send time (for faithful replay from history).
  final Map<String, String> _variableSnapshot;

  /// Active environment variable map at send time (for faithful replay from history).
  @override
  @JsonKey()
  Map<String, String> get variableSnapshot {
    if (_variableSnapshot is EqualUnmodifiableMapView) return _variableSnapshot;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_variableSnapshot);
  }

  @override
  String toString() {
    return 'HistoryEntry(uid: $uid, request: $request, response: $response, executedAt: $executedAt, variableSnapshot: $variableSnapshot)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryEntryImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.request, request) || other.request == request) &&
            (identical(other.response, response) ||
                other.response == response) &&
            (identical(other.executedAt, executedAt) ||
                other.executedAt == executedAt) &&
            const DeepCollectionEquality().equals(
              other._variableSnapshot,
              _variableSnapshot,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uid,
    request,
    response,
    executedAt,
    const DeepCollectionEquality().hash(_variableSnapshot),
  );

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoryEntryImplCopyWith<_$HistoryEntryImpl> get copyWith =>
      __$$HistoryEntryImplCopyWithImpl<_$HistoryEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HistoryEntryImplToJson(this);
  }
}

abstract class _HistoryEntry implements HistoryEntry {
  const factory _HistoryEntry({
    required final String uid,
    required final HttpRequest request,
    required final HttpResponse response,
    required final DateTime executedAt,
    final Map<String, String> variableSnapshot,
  }) = _$HistoryEntryImpl;

  factory _HistoryEntry.fromJson(Map<String, dynamic> json) =
      _$HistoryEntryImpl.fromJson;

  @override
  String get uid;
  @override
  HttpRequest get request;
  @override
  HttpResponse get response;
  @override
  DateTime get executedAt;

  /// Active environment variable map at send time (for faithful replay from history).
  @override
  Map<String, String> get variableSnapshot;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoryEntryImplCopyWith<_$HistoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
