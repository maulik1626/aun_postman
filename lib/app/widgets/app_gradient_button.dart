import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Primary CTA button with the brand gradient (#FFBD59 → #DB952C).
/// Drop-in replacement for [CupertinoButton.filled].
///
/// Use [AppGradientButton.secondary] for muted secondary actions next to a primary.
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding,
    this.borderRadius,
    this.fullWidth = false,
  }) : _secondary = false;

  /// Muted secondary CTA ([CupertinoColors.tertiarySystemFill], label-colored
  /// icon/text). Default padding and corner radius match [AppGradientButton] so
  /// paired primary + secondary align to the same height.
  const AppGradientButton.secondary({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding,
    this.borderRadius,
    this.fullWidth = false,
  }) : _secondary = true;

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// When true, the button expands to the parent width (e.g. stacked CTAs).
  final bool fullWidth;
  final bool _secondary;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    final isDisabled = onPressed == null;

    if (_secondary) {
      final btn = CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        borderRadius: radius,
        onPressed: onPressed,
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            width: fullWidth ? double.infinity : null,
            alignment: fullWidth ? Alignment.center : null,
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: radius,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Satoshi',
              ),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: CupertinoColors.label.resolveFrom(context),
                  size: 18,
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
      return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
    }

    final btn = CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      borderRadius: radius,
      onPressed: onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: fullWidth ? double.infinity : null,
          alignment: fullWidth ? Alignment.center : null,
          padding:
              padding ??
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
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
