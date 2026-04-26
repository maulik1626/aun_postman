import 'dart:async';

import 'package:aun_reqstudio/app/router/app_navigator.dart';
import 'package:flutter/material.dart';

enum WebToastType { info, success, error }

class WebToast {
  WebToast._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String message,
    WebToastType type = WebToastType.info,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlayState =
        Overlay.maybeOf(context) ?? appRootNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => _WebToastHost(
        message: message,
        type: type,
        duration: duration,
        onClosed: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
    overlayState.insert(_entry!);
  }
}

class _WebToastHost extends StatefulWidget {
  const _WebToastHost({
    required this.message,
    required this.type,
    required this.duration,
    required this.onClosed,
  });

  final String message;
  final WebToastType type;
  final Duration duration;
  final VoidCallback onClosed;

  @override
  State<_WebToastHost> createState() => _WebToastHostState();
}

class _WebToastHostState extends State<_WebToastHost>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _slideController;
  late final Animation<Offset> _slide;
  Timer? _autoCloseTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
    _autoCloseTimer = Timer(widget.duration, _close);
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _progressController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _autoCloseTimer?.cancel();
    if (mounted) {
      await _slideController.reverse();
    }
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = switch (widget.type) {
      WebToastType.info => scheme.primary,
      WebToastType.success => const Color(0xFF35C46B),
      WebToastType.error => scheme.error,
    };

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, right: 14),
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tone.withValues(alpha: 0.55)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                return CircularProgressIndicator(
                                  value: 1 - _progressController.value,
                                  strokeWidth: 2.4,
                                  backgroundColor: tone.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(tone),
                                );
                              },
                            ),
                          ),
                          InkWell(
                            onTap: _close,
                            customBorder: const CircleBorder(),
                            child: Icon(Icons.close, size: 14, color: tone),
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
    );
  }
}
