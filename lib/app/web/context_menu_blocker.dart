import 'package:flutter/widgets.dart';

import 'context_menu_blocker_stub.dart'
    if (dart.library.html) 'context_menu_blocker_web.dart' as impl;

class ContextMenuBlocker extends StatelessWidget {
  const ContextMenuBlocker({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return impl.ContextMenuBlockerImpl(child: child);
  }
}
