// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FolderImpl _$$FolderImplFromJson(Map<String, dynamic> json) => _$FolderImpl(
  uid: json['uid'] as String,
  name: json['name'] as String,
  collectionUid: json['collectionUid'] as String,
  parentFolderUid: json['parentFolderUid'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  requests:
      (json['requests'] as List<dynamic>?)
          ?.map((e) => HttpRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  subFolders:
      (json['subFolders'] as List<dynamic>?)
          ?.map((e) => Folder.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$FolderImplToJson(_$FolderImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'collectionUid': instance.collectionUid,
      'parentFolderUid': instance.parentFolderUid,
      'sortOrder': instance.sortOrder,
      'requests': instance.requests,
      'subFolders': instance.subFolders,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
