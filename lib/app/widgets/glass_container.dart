import 'dart:ui';

import 'package:flutter/cupertino.dart';

/// iOS 26 Liquid Glass effect container.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.opacity = 0.72,
    this.blurSigma = 24,
    this.border = true,
  });

  final Widget child;
  final double borderRadius;
  final double opacity;
  final double blurSigma;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.black.withOpacity(opacity * 0.6)
                : CupertinoColors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border
                ? Border.all(
                    color: isDark
                        ? CupertinoColors.white.withOpacity(0.12)
                        : CupertinoColors.white.withOpacity(0.6),
                    width: 0.5,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Full-width glass bar — used for nav bars and tab bars.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.blurSigma = 30,
  });

  final Widget child;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.82)
                : CupertinoColors.white.withOpacity(0.82),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? CupertinoColors.white.withOpacity(0.08)
                    : CupertinoColors.black.withOpacity(0.08),
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
