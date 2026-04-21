import 'dart:ui';

import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final blurSigma = screenHeight < 760 ? 21.0 : 26.0;
    final panelPadding = screenHeight < 760
        ? const EdgeInsets.fromLTRB(18, 22, 18, 20)
        : const EdgeInsets.fromLTRB(22, 24, 22, 24);
    final isBlocked = authState.isBusy || authState.hasFatalSetupError;
    final isGoogleLoading = authState.activeAction == AuthAction.google;
    final isAppleLoading = authState.activeAction == AuthAction.apple;

    return CupertinoPageScaffold(
      child: Stack(
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
                stops: [0.08, 0.58, 1.0],
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
            top: MediaQuery.of(context).padding.top + 32,
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
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Build, test, and inspect APIs with calm, focused speed.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: CupertinoColors.extraLightBackgroundGray,
                    height: 1.4,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.elliptical(38, 32),
                      topRight: Radius.elliptical(42, 34),
                      bottomLeft: Radius.elliptical(30, 26),
                      bottomRight: Radius.elliptical(34, 28),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: blurSigma,
                        sigmaY: blurSigma,
                      ),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0x8AF8F1E8),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x38110C08),
                              blurRadius: 42,
                              spreadRadius: 1,
                              offset: Offset(0, 22),
                            ),
                            BoxShadow(
                              color: Color(0x6EFFFDF8),
                              blurRadius: 22,
                              spreadRadius: -2,
                              offset: Offset(0, -6),
                            ),
                          ],
                          gradient: LinearGradient(
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
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.elliptical(38, 32),
                              topRight: Radius.elliptical(42, 34),
                              bottomLeft: Radius.elliptical(30, 26),
                              bottomRight: Radius.elliptical(34, 28),
                            ),
                            border: Border.all(
                              color: const Color(0xC7FFF9F2),
                              width: 1.1,
                            ),
                          ),
                          child: Padding(
                            padding: panelPadding,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    color: Color(0xFF1A130D),
                                    fontSize: 24,
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
                                const SizedBox(height: 16),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: authState.errorMessage == null
                                      ? const SizedBox.shrink()
                                      : _CupertinoAuthErrorCard(
                                          message: authState.errorMessage!,
                                          onDismiss: () =>
                                              controller.clearError(),
                                        ),
                                ),
                                if (authState.errorMessage != null)
                                  const SizedBox(height: 14),
                                _CupertinoAuthButton(
                                  label: isGoogleLoading
                                      ? 'Signing in...'
                                      : 'Continue with Google',
                                  onPressed: () =>
                                      controller.signInWithGoogle(),
                                  backgroundColor: const Color(0xEFFFFFFF),
                                  textColor: CupertinoColors.black,
                                  isLoading: isGoogleLoading,
                                  isLocked: isBlocked && !isGoogleLoading,
                                  leading: Image.asset(
                                    'assets/icons/google.png',
                                    height: 20,
                                    width: 20,
                                    color: const Color(0xFF2A2A2A),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _CupertinoAuthButton(
                                  label: isAppleLoading
                                      ? 'Signing in...'
                                      : 'Continue with Apple',
                                  onPressed: () => controller.signInWithApple(),
                                  backgroundColor: const Color(0xE61A1A1A),
                                  textColor: CupertinoColors.white,
                                  isLoading: isAppleLoading,
                                  isLocked: isBlocked && !isAppleLoading,
                                  leading: Image.asset(
                                    'assets/icons/apple-logo.png',
                                    height: 18,
                                    width: 18,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 26),
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
        ],
      ),
    );
  }
}

class _CupertinoAuthErrorCard extends StatelessWidget {
  const _CupertinoAuthErrorCard({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0x73D97C52);
    final surfaceColor = const Color(0x4CF6D8C8);
    final iconColor = const Color(0xFFA94C27);
    final titleColor = const Color(0xFF6E2F16);
    final bodyColor = const Color(0xCC5B3727);

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
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
              child: Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: iconColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
              onPressed: onDismiss,
              child: const Icon(
                CupertinoIcons.xmark,
                color: Color(0x99603A2A),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CupertinoAuthButton extends StatelessWidget {
  const _CupertinoAuthButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.isLoading,
    required this.isLocked,
    required this.leading,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;
  final bool isLocked;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = isLoading
        ? backgroundColor.withValues(alpha: 0.94)
        : backgroundColor;
    final effectiveTextColor = isLoading
        ? textColor
        : isLocked
        ? textColor.withValues(alpha: 0.76)
        : textColor;
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
                  child: CupertinoActivityIndicator(
                    color: textColor,
                    radius: 9,
                  ),
                )
              : KeyedSubtree(key: const ValueKey('icon'), child: leading),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: effectiveTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x22FFFFFF), Color(0x05FFFFFF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Opacity(
        opacity: isLocked ? 0.7 : 1,
        child: AbsorbPointer(
          absorbing: isLoading || isLocked,
          child: SizedBox(
            height: 54,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: effectiveBackground,
              borderRadius: BorderRadius.circular(16),
              onPressed: onPressed,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
