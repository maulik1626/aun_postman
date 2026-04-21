import 'dart:ui';

import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreenMaterial extends ConsumerWidget {
  const AuthScreenMaterial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final blurSigma = screenHeight < 760 ? 21.0 : 26.0;
    final panelPadding = screenHeight < 760
        ? const EdgeInsets.fromLTRB(18, 22, 18, 18)
        : const EdgeInsets.fromLTRB(22, 26, 22, 22);
    final isBlocked = authState.isBusy || authState.hasFatalSetupError;
    final isGoogleLoading = authState.activeAction == AuthAction.google;
    const bottomBarColor = Color(0xFF17110B);
    const cardRadius = BorderRadius.only(
      topLeft: Radius.elliptical(38, 32),
      topRight: Radius.elliptical(42, 34),
      bottomLeft: Radius.elliptical(30, 26),
      bottomRight: Radius.elliptical(34, 28),
    );
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: bottomBarColor,
      systemNavigationBarDividerColor: bottomBarColor,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: bottomBarColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/auth_hero.png', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB8000000),
                    Color(0x8C120D08),
                    Color(0x26120D08),
                  ],
                  stops: [0.1, 0.58, 1.0],
                ),
              ),
            ),
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 280,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: const RadialGradient(
                      center: Alignment(0, 0.85),
                      radius: 1.05,
                      colors: [
                        Color(0x4DFFE1B0),
                        Color(0x18FFF8EA),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/AUN Logo.png',
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ReqStudio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Build, test, and inspect APIs with calm, focused speed.',
                    style: TextStyle(
                      color: Color(0xFFE7D7C4),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Requests, auth, collections, and response debugging in one place.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xCCF4E9DC),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                bottom: true,
                minimum: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    minWidth: screenSize.width - 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            borderRadius: cardRadius,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x38110C08),
                                blurRadius: 42,
                                spreadRadius: 1,
                                offset: Offset(0, 22),
                              ),
                              BoxShadow(
                                color: Color(0x33FFFDF8),
                                blurRadius: 16,
                                spreadRadius: -1,
                                offset: Offset(0, -3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: cardRadius,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: blurSigma,
                                sigmaY: blurSigma,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0x8AF8F1E8),
                                  border: Border.all(
                                    color: const Color(0xC7FFF9F2),
                                    width: 1.1,
                                  ),
                                  borderRadius: cardRadius,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xCCFFFDF8),
                                      Color(0xA8FAF1E7),
                                      Color(0x7DEBDAC7),
                                    ],
                                    stops: [0.0, 0.52, 1.0],
                                  ),
                                ),
                                child: Padding(
                                  padding: panelPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Welcome back',
                                        style: TextStyle(
                                          color: Color(0xFF1A130D),
                                          fontSize: 25,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Sign in to pick up your API workspace and continue shipping.',
                                        style: TextStyle(
                                          color: Color(0xD22A2118),
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        child: authState.errorMessage == null
                                            ? const SizedBox.shrink()
                                            : _MaterialAuthErrorCard(
                                                message:
                                                    authState.errorMessage!,
                                                onDismiss: () =>
                                                    controller.clearError(),
                                              ),
                                      ),
                                      if (authState.errorMessage != null)
                                        const SizedBox(height: 14),
                                      _MaterialAuthButton(
                                        label: isGoogleLoading
                                            ? 'Signing in...'
                                            : 'Continue with Google',
                                        onPressed: () =>
                                            controller.signInWithGoogle(),
                                        backgroundColor: const Color(
                                          0xEFFFFFFF,
                                        ),
                                        foregroundColor: Colors.black,
                                        iconAsset: 'assets/icons/google.png',
                                        iconColor: const Color(0xFF2A2A2A),
                                        isLoading: isGoogleLoading,
                                        isLocked: isBlocked && !isGoogleLoading,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Secure sign-in for the tools you use every day.',
                                        style: TextStyle(
                                          color: Color(0xC42C2118),
                                          fontSize: 12,
                                          height: 1.4,
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
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          'An AUN Creations product',
                          style: TextStyle(
                            color: Color(0xB5F4E9DC),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialAuthErrorCard extends StatelessWidget {
  const _MaterialAuthErrorCard({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0x73D97C52);
    const surfaceColor = Color(0x4CF6D8C8);
    const iconColor = Color(0xFFA94C27);
    const titleColor = Color(0xFF6E2F16);
    const bodyColor = Color(0xCC5B3727);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12A03F16),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0x66FFF7F1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0x66E9B196)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.error_outline_rounded,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sign-in issue',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: bodyColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0x99603A2A),
                size: 18,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialAuthButton extends StatelessWidget {
  const _MaterialAuthButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconAsset,
    required this.iconColor,
    required this.isLoading,
    required this.isLocked,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String iconAsset;
  final Color iconColor;
  final bool isLoading;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = isLoading
        ? backgroundColor.withValues(alpha: 0.94)
        : backgroundColor;
    final effectiveForeground = isLoading
        ? foregroundColor
        : isLocked
        ? foregroundColor.withValues(alpha: 0.8)
        : foregroundColor;
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('spinner'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: foregroundColor,
                  ),
                )
              : Image.asset(
                  key: const ValueKey('icon'),
                  iconAsset,
                  height: 20,
                  width: 20,
                  color: iconColor,
                ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x22FFFFFF), Color(0x00FFFFFF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Opacity(
        opacity: isLocked ? 0.72 : 1,
        child: AbsorbPointer(
          absorbing: isLoading || isLocked,
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                elevation: 0,
                disabledBackgroundColor: effectiveBackground,
                disabledForegroundColor: effectiveForeground,
                backgroundColor: effectiveBackground,
                foregroundColor: effectiveForeground,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
