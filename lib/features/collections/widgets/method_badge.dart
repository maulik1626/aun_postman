import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';

class MethodBadge extends StatelessWidget {
  const MethodBadge({super.key, required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'JetBrainsMono',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
