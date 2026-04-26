import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/widgets.dart';

class ContextMenuBlockerImpl extends StatefulWidget {
  const ContextMenuBlockerImpl({super.key, required this.child});

  final Widget child;

  @override
  State<ContextMenuBlockerImpl> createState() => _ContextMenuBlockerImplState();
}

class _ContextMenuBlockerImplState extends State<ContextMenuBlockerImpl> {
  final GlobalKey _regionKey = GlobalKey();
  StreamSubscription<html.MouseEvent>? _contextMenuSubscription;

  @override
  void initState() {
    super.initState();
    _contextMenuSubscription = html.window.onContextMenu.listen(
      _handleContextMenuEvent,
    );
  }

  @override
  void dispose() {
    _contextMenuSubscription?.cancel();
    super.dispose();
  }

  void _handleContextMenuEvent(html.MouseEvent event) {
    final context = _regionKey.currentContext;
    if (context == null) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final bounds = topLeft & renderObject.size;
    final pointer = Offset(event.client.x.toDouble(), event.client.y.toDouble());
    if (bounds.contains(pointer)) {
      event.preventDefault();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _regionKey, child: widget.child);
  }
}
