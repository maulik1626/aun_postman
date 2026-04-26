import 'dart:ui';

import 'package:flutter/material.dart';

class AuthBootstrapScreenWeb extends StatefulWidget {
  const AuthBootstrapScreenWeb({super.key});

  @override
  State<AuthBootstrapScreenWeb> createState() => _AuthBootstrapScreenWebState();
}

class _AuthBootstrapScreenWebState extends State<AuthBootstrapScreenWeb> {
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
    final size = MediaQuery.sizeOf(context);
    final isMobileWidth = size.width < 600;
    final isCompact = size.width < 900;
    final heroAsset = isMobileWidth
        ? 'assets/images/auth_hero.png'
        : 'assets/images/auth_hero_web.png';
    final cardWidth = isCompact ? (size.width - 32).clamp(320.0, 640.0) : 520.0;
    final horizontalPadding = isCompact ? 16.0 : 28.0;

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
                            _BootstrapBrandHeader(isCompact: isCompact),
                            const SizedBox(height: 16),
                            const Text(
                              'Restoring your secure workspace.',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontFamily: 'Satoshi',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15120D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We are verifying your session before loading requests, history, and environments.',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontFamily: 'Satoshi',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xCC2F261E),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: const [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Color(0xFFDB952C),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Preparing auth state...',
                                    style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      color: Color(0xB32F261E),
                                    ),
                                  ),
                                ),
                              ],
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

class _BootstrapBrandHeader extends StatelessWidget {
  const _BootstrapBrandHeader({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/AUN Logo.png', height: 30),
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
      ],
    );
  }
}
