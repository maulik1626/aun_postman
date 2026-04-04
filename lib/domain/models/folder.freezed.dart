// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Folder _$FolderFromJson(Map<String, dynamic> json) {
  return _Folder.fromJson(json);
}

/// @nodoc
mixin _$Folder {
  String get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get collectionUid => throw _privateConstructorUsedError;
  String? get parentFolderUid => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  List<HttpRequest> get requests => throw _privateConstructorUsedError;
  List<Folder> get subFolders => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Folder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FolderCopyWith<Folder> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FolderCopyWith<$Res> {
  factory $FolderCopyWith(Folder value, $Res Function(Folder) then) =
      _$FolderCopyWithImpl<$Res, Folder>;
  @useResult
  $Res call({
    String uid,
    String name,
    String collectionUid,
    String? parentFolderUid,
    int sortOrder,
    List<HttpRequest> requests,
    List<Folder> subFolders,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$FolderCopyWithImpl<$Res, $Val extends Folder>
    implements $FolderCopyWith<$Res> {
  _$FolderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? collectionUid = null,
    Object? parentFolderUid = freezed,
    Object? sortOrder = null,
    Object? requests = null,
    Object? subFolders = null,
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
            collectionUid: null == collectionUid
                ? _value.collectionUid
                : collectionUid // ignore: cast_nullable_to_non_nullable
                      as String,
            parentFolderUid: freezed == parentFolderUid
                ? _value.parentFolderUid
                : parentFolderUid // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            requests: null == requests
                ? _value.requests
                : requests // ignore: cast_nullable_to_non_nullable
                      as List<HttpRequest>,
            subFolders: null == subFolders
                ? _value.subFolders
                : subFolders // ignore: cast_nullable_to_non_nullable
                      as List<Folder>,
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
}

/// @nodoc
abstract class _$$FolderImplCopyWith<$Res> implements $FolderCopyWith<$Res> {
  factory _$$FolderImplCopyWith(
    _$FolderImpl value,
    $Res Function(_$FolderImpl) then,
  ) = __$$FolderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String name,
    String collectionUid,
    String? parentFolderUid,
    int sortOrder,
    List<HttpRequest> requests,
    List<Folder> subFolders,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$FolderImplCopyWithImpl<$Res>
    extends _$FolderCopyWithImpl<$Res, _$FolderImpl>
    implements _$$FolderImplCopyWith<$Res> {
  __$$FolderImplCopyWithImpl(
    _$FolderImpl _value,
    $Res Function(_$FolderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? collectionUid = null,
    Object? parentFolderUid = freezed,
    Object? sortOrder = null,
    Object? requests = null,
    Object? subFolders = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$FolderImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        collectionUid: null == collectionUid
            ? _value.collectionUid
            : collectionUid // ignore: cast_nullable_to_non_nullable
                  as String,
        parentFolderUid: freezed == parentFolderUid
            ? _value.parentFolderUid
            : parentFolderUid // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        requests: null == requests
            ? _value._requests
            : requests // ignore: cast_nullable_to_non_nullable
                  as List<HttpRequest>,
        subFolders: null == subFolders
            ? _value._subFolders
            : subFolders // ignore: cast_nullable_to_non_nullable
                  as List<Folder>,
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
class _$FolderImpl implements _Folder {
  const _$FolderImpl({
    required this.uid,
    required this.name,
    required this.collectionUid,
    this.parentFolderUid,
    this.sortOrder = 0,
    final List<HttpRequest> requests = const [],
    final List<Folder> subFolders = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : _requests = requests,
       _subFolders = subFolders;

  factory _$FolderImpl.fromJson(Map<String, dynamic> json) =>
      _$$FolderImplFromJson(json);

  @override
  final String uid;
  @override
  final String name;
  @override
  final String collectionUid;
  @override
  final String? parentFolderUid;
  @override
  @JsonKey()
  final int sortOrder;
  final List<HttpRequest> _requests;
  @override
  @JsonKey()
  List<HttpRequest> get requests {
    if (_requests is EqualUnmodifiableListView) return _requests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requests);
  }

  final List<Folder> _subFolders;
  @override
  @JsonKey()
  List<Folder> get subFolders {
    if (_subFolders is EqualUnmodifiableListView) return _subFolders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subFolders);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Folder(uid: $uid, name: $name, collectionUid: $collectionUid, parentFolderUid: $parentFolderUid, sortOrder: $sortOrder, requests: $requests, subFolders: $subFolders, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FolderImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.collectionUid, collectionUid) ||
                other.collectionUid == collectionUid) &&
            (identical(other.parentFolderUid, parentFolderUid) ||
                other.parentFolderUid == parentFolderUid) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            const DeepCollectionEquality().equals(other._requests, _requests) &&
            const DeepCollectionEquality().equals(
              other._subFolders,
              _subFolders,
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
    collectionUid,
    parentFolderUid,
    sortOrder,
    const DeepCollectionEquality().hash(_requests),
    const DeepCollectionEquality().hash(_subFolders),
    createdAt,
    updatedAt,
  );

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FolderImplCopyWith<_$FolderImpl> get copyWith =>
      __$$FolderImplCopyWithImpl<_$FolderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FolderImplToJson(this);
  }
}

abstract class _Folder implements Folder {
  const factory _Folder({
    required final String uid,
    required final String name,
    required final String collectionUid,
    final String? parentFolderUid,
    final int sortOrder,
    final List<HttpRequest> requests,
    final List<Folder> subFolders,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$FolderImpl;

  factory _Folder.fromJson(Map<String, dynamic> json) = _$FolderImpl.fromJson;

  @override
  String get uid;
  @override
  String get name;
  @override
  String get collectionUid;
  @override
  String? get parentFolderUid;
  @override
  int get sortOrder;
  @override
  List<HttpRequest> get requests;
  @override
  List<Folder> get subFolders;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FolderImplCopyWith<_$FolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
