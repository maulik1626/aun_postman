import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

@freezed
class Folder with _$Folder {
  const factory Folder({
    required String uid,
    required String name,
    required String collectionUid,
    String? parentFolderUid,
    @Default(0) int sortOrder,
    @Default([]) List<HttpRequest> requests,
    @Default([]) List<Folder> subFolders,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) =>
      _$FolderFromJson(json);
}
