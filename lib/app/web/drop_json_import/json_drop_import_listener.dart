import 'package:flutter/widgets.dart';

import 'json_drop_import_listener_stub.dart'
    if (dart.library.html) 'json_drop_import_listener_web.dart'
    as impl;

class JsonDropImportListener extends StatelessWidget {
  const JsonDropImportListener({
    super.key,
    required this.child,
    required this.onJsonDropped,
    this.onDropError,
  });

  final Widget child;
  final Future<void> Function(String content, String fileName) onJsonDropped;
  final void Function(String message)? onDropError;

  @override
  Widget build(BuildContext context) {
    return impl.JsonDropImportListenerImpl(
      child: child,
      onJsonDropped: onJsonDropped,
      onDropError: onDropError,
    );
  }
}
