import 'package:flutter/widgets.dart';

class ContextMenuBlockerImpl extends StatelessWidget {
  const ContextMenuBlockerImpl({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
