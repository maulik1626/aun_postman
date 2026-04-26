import 'dart:ui';

import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreenWeb extends ConsumerStatefulWidget {
  const AuthScreenWeb({super.key});

  @override
  ConsumerState<AuthScreenWeb> createState() => _AuthScreenWebState();
}

class _AuthScreenWebState extends ConsumerState<AuthScreenWeb> {
  bool _didPrecacheLogo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheLogo) return;
    _didPrecacheLogo = true;
    precacheImage(const AssetImage('assets/images/AUN Logo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final isMobileWidth = size.width < 600;
    final isCompact = size.width < 900;
    final heroAsset = isMobileWidth
        ? 'assets/images/auth_hero.png'
        : 'assets/images/auth_hero_web.png';
    final cardWidth = isCompact ? (size.width - 32).clamp(320.0, 640.0) : 520.0;
    final horizontalPadding = isCompact ? 16.0 : 28.0;

    final isBlocked = authState.isBusy || authState.hasFatalSetupError;
    final isGoogleLoading = authState.activeAction == AuthAction.google;

    const headingStyle = TextStyle(
      decoration: TextDecoration.none,
      fontFamily: 'Satoshi',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Color(0xFF121212),
      height: 1.2,
    );
    const bodyStyle = TextStyle(
      decoration: TextDecoration.none,
      fontFamily: 'Satoshi',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xCC2B2B2B),
      height: 1.35,
    );

    return ColoredBox(
      color: const Color(0xFF130F0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(heroAsset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD1000000),
                  Color(0xA31A120A),
                  Color(0xE8130F0A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Center(
            child: SafeArea(
              minimum: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xC7F7F2EB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xA8FFF9EE)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 32,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: cardWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isCompact ? 22 : 26,
                          horizontalPadding,
                          isCompact ? 20 : 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BrandHeader(isCompact: isCompact),
                            const SizedBox(height: 22),
                            const Text('Welcome back', style: headingStyle),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to access your API workspace and continue where you left off.',
                              style: bodyStyle,
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: authState.errorMessage == null
                                  ? const SizedBox.shrink()
                                  : _WebAuthErrorCard(
                                      message: authState.errorMessage!,
                                      onDismiss: controller.clearError,
                                    ),
                            ),
                            if (authState.errorMessage != null)
                              const SizedBox(height: 14),
                            _WebAuthButton(
                              label: isGoogleLoading
                                  ? 'Signing in...'
                                  : 'Continue with Google',
                              iconAsset: 'assets/icons/google.png',
                              iconColor: const Color(0xFF262626),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF161616),
                              isLoading: isGoogleLoading,
                              isLocked: isBlocked && !isGoogleLoading,
                              onPressed: controller.signInWithGoogle,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Secure sign-in for the tools you use every day.',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontFamily: 'Satoshi',
                                fontSize: 12,
                                color: Color(0xC22E261F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Text(
              'An AUN Creations product',
              style: TextStyle(
                decoration: TextDecoration.none,
                fontFamily: 'Satoshi',
                color: Color(0xBDEFE0CC),
                fontSize: 12,
                letterSpacing: 0.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/AUN Logo.png',
              height: 30,
              // color: const Color(0xFF17120D),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'ReqStudio',
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontFamily: 'Satoshi',
                  fontSize: isCompact ? 34 : 36,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17120D),
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Build, test, and inspect APIs with calm, focused speed.',
          style: TextStyle(
            decoration: TextDecoration.none,
            fontFamily: 'Satoshi',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xD92F2319),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Requests, auth, collections, and response debugging in one place.',
          style: TextStyle(
            decoration: TextDecoration.none,
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xB332271D),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _WebAuthErrorCard extends StatelessWidget {
  const _WebAuthErrorCard({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9DE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD48D61)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: Color(0xFFA64923),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: Color(0xFF6A2F1A),
                  height: 1.35,
                ),
              ),
            ),
            _WebIconControl(
              tooltip: 'Dismiss',
              icon: Icons.close_rounded,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _WebAuthButton extends StatelessWidget {
  const _WebAuthButton({
    required this.label,
    required this.iconAsset,
    required this.iconColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isLoading,
    required this.isLocked,
    required this.onPressed,
  });

  final String label;
  final String iconAsset;
  final Color iconColor;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final bool isLocked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || isLocked;
    final effectiveBackground = disabled
        ? backgroundColor.withValues(alpha: 0.72)
        : backgroundColor;
    final effectiveForeground = disabled
        ? foregroundColor.withValues(alpha: 0.82)
        : foregroundColor;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: _WebHoverPressable(
        onPressed: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        builder: (context, hovered, pressed) {
          final borderColor = hovered
              ? const Color(0xB0DB952C)
              : const Color(0x2B161616);
          final shadowOpacity = pressed ? 0.12 : 0.18;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            height: 52,
            decoration: BoxDecoration(
              color: effectiveBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowOpacity),
                  blurRadius: pressed ? 8 : 14,
                  offset: Offset(0, pressed ? 3 : 6),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: isLoading
                          ? SizedBox(
                              key: const ValueKey('progress'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: effectiveForeground,
                              ),
                            )
                          : Image.asset(
                              key: const ValueKey('icon'),
                              iconAsset,
                              height: 18,
                              width: 18,
                              color: iconColor,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontFamily: 'Satoshi',
                          color: effectiveForeground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WebIconControl extends StatelessWidget {
  const _WebIconControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _WebHoverPressable(
      tooltip: tooltip,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(999),
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: hovered ? const Color(0x21A64923) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xB3562A16)),
        );
      },
    );
  }
}

class _WebHoverPressable extends StatefulWidget {
  const _WebHoverPressable({
    required this.builder,
    required this.borderRadius,
    required this.onPressed,
    this.tooltip,
  });

  final Widget Function(BuildContext context, bool hovered, bool pressed)
  builder;
  final BorderRadius borderRadius;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  State<_WebHoverPressable> createState() => _WebHoverPressableState();
}

class _WebHoverPressableState extends State<_WebHoverPressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onPressed == null
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget.onPressed == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: widget.builder(context, _hovered, _pressed),
    );

    final hoverable = MouseRegion(
      cursor: widget.onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: child,
    );

    final clipped = ClipRRect(
      borderRadius: widget.borderRadius,
      child: hoverable,
    );

    if (widget.tooltip == null || widget.tooltip!.isEmpty) {
      return clipped;
    }
    return Tooltip(message: widget.tooltip!, child: clipped);
  }
}
