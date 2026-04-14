import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Primary CTA button with the brand gradient (#FFBD59 → #DB952C).
/// Drop-in replacement for [CupertinoButton.filled] on iOS.
///
/// Use [AppGradientButton.secondary] for muted secondary actions next to a
/// primary on iOS, and [AppGradientButton.material] /
/// [AppGradientButton.materialSecondary] on Android.
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding,
    this.borderRadius,
    this.fullWidth = false,
  }) : _variant = _Variant.primary;

  /// Muted secondary CTA (iOS). Matches the height of [AppGradientButton].
  const AppGradientButton.secondary({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding,
    this.borderRadius,
    this.fullWidth = false,
  }) : _variant = _Variant.secondary;

  /// Primary gradient CTA for Material (Android).
  /// Uses [InkWell] + gradient [Container] so the brand look is identical
  /// but ripple feedback is Material-native.
  const AppGradientButton.material({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding,
    this.borderRadius,
    this.fullWidth = false,
  }) : _variant = _Variant.materialPrimary;

  /// Muted secondary CTA for Material (Android).
  const AppGradientButton.materialSecondary({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding,
    this.borderRadius,
    this.fullWidth = false,
  }) : _variant = _Variant.materialSecondary;

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool fullWidth;
  final _Variant _variant;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    final isDisabled = onPressed == null;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    switch (_variant) {
      // ── iOS secondary ──────────────────────────────────────────────────────
      case _Variant.secondary:
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
              padding: effectivePadding,
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

      // ── Material primary ───────────────────────────────────────────────────
      case _Variant.materialPrimary:
        final btn = Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: isDisabled ? null : onPressed,
            child: Opacity(
              opacity: isDisabled ? 0.72 : 1.0,
              child: Container(
                width: fullWidth ? double.infinity : null,
                alignment: fullWidth ? Alignment.center : null,
                padding: effectivePadding,
                decoration: BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  borderRadius: radius,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Satoshi',
                  ),
                  child: IconTheme.merge(
                    data:
                        const IconThemeData(color: Colors.white, size: 18),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
        return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;

      // ── Material secondary ─────────────────────────────────────────────────
      case _Variant.materialSecondary:
        final surfaceColor =
            Theme.of(context).colorScheme.surfaceContainerHighest;
        final labelColor = Theme.of(context).colorScheme.onSurface;
        final btn = Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: isDisabled ? null : onPressed,
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: Container(
                width: fullWidth ? double.infinity : null,
                alignment: fullWidth ? Alignment.center : null,
                padding: effectivePadding,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: radius,
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Satoshi',
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: labelColor, size: 18),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
        return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;

      // ── iOS primary (default) ──────────────────────────────────────────────
      case _Variant.primary:
        final btn = CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          borderRadius: radius,
          onPressed: onPressed,
          child: Opacity(
            // Softer than 0.5 so the brand gradient stays recognizable when disabled.
            opacity: isDisabled ? 0.72 : 1.0,
            child: Container(
              width: fullWidth ? double.infinity : null,
              alignment: fullWidth ? Alignment.center : null,
              padding: effectivePadding,
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
                  data: const IconThemeData(
                      color: CupertinoColors.white, size: 18),
                  child: child,
                ),
              ),
            ),
          ),
        );
        return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
    }
  }
}

enum _Variant { primary, secondary, materialPrimary, materialSecondary }
