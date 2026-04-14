import 'package:aun_reqstudio/domain/models/folder.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:flutter/cupertino.dart';

/// Payload while dragging an item in the collection tree (detail screen).
sealed class CollectionTreeDragData {
  const CollectionTreeDragData({required this.collectionUid});
  final String collectionUid;
}

final class CollectionTreeDragRequest extends CollectionTreeDragData {
  const CollectionTreeDragRequest({
    required super.collectionUid,
    required this.request,
    this.fromFolderUid,
  });

  final HttpRequest request;
  final String? fromFolderUid;
}

final class CollectionTreeDragFolder extends CollectionTreeDragData {
  const CollectionTreeDragFolder({
    required super.collectionUid,
    required this.folder,
    this.parentFolderUid,
  });

  final Folder folder;
  final String? parentFolderUid;
}

/// Non-null while a tree item is being dragged — used to show drop overlays.
class CollectionTreeDnDScope extends InheritedWidget {
  const CollectionTreeDnDScope({
    super.key,
    required this.dragging,
    required super.child,
  });

  final CollectionTreeDragData? dragging;

  static CollectionTreeDragData? maybeDraggingOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CollectionTreeDnDScope>()
        ?.dragging;
  }

  @override
  bool updateShouldNotify(CollectionTreeDnDScope oldWidget) {
    return dragging != oldWidget.dragging;
  }
}
