import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Primary CTA button with the brand gradient (#FFBD59 → #DB952C).
/// Drop-in replacement for [CupertinoButton.filled].
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    final isDisabled = onPressed == null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      borderRadius: radius,
      onPressed: onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            borderRadius: radius,
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Satoshi',
            ),
            child: IconTheme.merge(
              data: const IconThemeData(color: CupertinoColors.white, size: 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
