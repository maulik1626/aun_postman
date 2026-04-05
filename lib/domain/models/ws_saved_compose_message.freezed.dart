// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ws_saved_compose_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WsSavedComposeMessage _$WsSavedComposeMessageFromJson(
  Map<String, dynamic> json,
) {
  return _WsSavedComposeMessage.fromJson(json);
}

/// @nodoc
mixin _$WsSavedComposeMessage {
  String get uid => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  WsComposerFormat get format => throw _privateConstructorUsedError;
  DateTime get savedAt => throw _privateConstructorUsedError;

  /// Serializes this WsSavedComposeMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WsSavedComposeMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WsSavedComposeMessageCopyWith<WsSavedComposeMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WsSavedComposeMessageCopyWith<$Res> {
  factory $WsSavedComposeMessageCopyWith(
    WsSavedComposeMessage value,
    $Res Function(WsSavedComposeMessage) then,
  ) = _$WsSavedComposeMessageCopyWithImpl<$Res, WsSavedComposeMessage>;
  @useResult
  $Res call({
    String uid,
    String body,
    WsComposerFormat format,
    DateTime savedAt,
  });
}

/// @nodoc
class _$WsSavedComposeMessageCopyWithImpl<
  $Res,
  $Val extends WsSavedComposeMessage
>
    implements $WsSavedComposeMessageCopyWith<$Res> {
  _$WsSavedComposeMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WsSavedComposeMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? body = null,
    Object? format = null,
    Object? savedAt = null,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            format: null == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as WsComposerFormat,
            savedAt: null == savedAt
                ? _value.savedAt
                : savedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WsSavedComposeMessageImplCopyWith<$Res>
    implements $WsSavedComposeMessageCopyWith<$Res> {
  factory _$$WsSavedComposeMessageImplCopyWith(
    _$WsSavedComposeMessageImpl value,
    $Res Function(_$WsSavedComposeMessageImpl) then,
  ) = __$$WsSavedComposeMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String body,
    WsComposerFormat format,
    DateTime savedAt,
  });
}

/// @nodoc
class __$$WsSavedComposeMessageImplCopyWithImpl<$Res>
    extends
        _$WsSavedComposeMessageCopyWithImpl<$Res, _$WsSavedComposeMessageImpl>
    implements _$$WsSavedComposeMessageImplCopyWith<$Res> {
  __$$WsSavedComposeMessageImplCopyWithImpl(
    _$WsSavedComposeMessageImpl _value,
    $Res Function(_$WsSavedComposeMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WsSavedComposeMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? body = null,
    Object? format = null,
    Object? savedAt = null,
  }) {
    return _then(
      _$WsSavedComposeMessageImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        format: null == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as WsComposerFormat,
        savedAt: null == savedAt
            ? _value.savedAt
            : savedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WsSavedComposeMessageImpl implements _WsSavedComposeMessage {
  const _$WsSavedComposeMessageImpl({
    required this.uid,
    required this.body,
    this.format = WsComposerFormat.text,
    required this.savedAt,
  });

  factory _$WsSavedComposeMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$WsSavedComposeMessageImplFromJson(json);

  @override
  final String uid;
  @override
  final String body;
  @override
  @JsonKey()
  final WsComposerFormat format;
  @override
  final DateTime savedAt;

  @override
  String toString() {
    return 'WsSavedComposeMessage(uid: $uid, body: $body, format: $format, savedAt: $savedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WsSavedComposeMessageImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.savedAt, savedAt) || other.savedAt == savedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uid, body, format, savedAt);

  /// Create a copy of WsSavedComposeMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WsSavedComposeMessageImplCopyWith<_$WsSavedComposeMessageImpl>
  get copyWith =>
      __$$WsSavedComposeMessageImplCopyWithImpl<_$WsSavedComposeMessageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WsSavedComposeMessageImplToJson(this);
  }
}

abstract class _WsSavedComposeMessage implements WsSavedComposeMessage {
  const factory _WsSavedComposeMessage({
    required final String uid,
    required final String body,
    final WsComposerFormat format,
    required final DateTime savedAt,
  }) = _$WsSavedComposeMessageImpl;

  factory _WsSavedComposeMessage.fromJson(Map<String, dynamic> json) =
      _$WsSavedComposeMessageImpl.fromJson;

  @override
  String get uid;
  @override
  String get body;
  @override
  WsComposerFormat get format;
  @override
  DateTime get savedAt;

  /// Create a copy of WsSavedComposeMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WsSavedComposeMessageImplCopyWith<_$WsSavedComposeMessageImpl>
  get copyWith => throw _privateConstructorUsedError;
}
