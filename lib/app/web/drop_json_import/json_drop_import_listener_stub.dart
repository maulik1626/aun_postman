import 'package:flutter/widgets.dart';

class JsonDropImportListenerImpl extends StatelessWidget {
  const JsonDropImportListenerImpl({
    super.key,
    required this.child,
    required this.onJsonDropped,
    this.onDropError,
  });

  final Widget child;
  final Future<void> Function(String content, String fileName) onJsonDropped;
  final void Function(String message)? onDropError;

  @override
  Widget build(BuildContext context) => child;
}
