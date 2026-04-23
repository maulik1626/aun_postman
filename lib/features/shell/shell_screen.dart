import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    // CupertinoTabBar height is 50pt (kMinInteractiveDimensionCupertino + 6).
    // Since we overlay it via Stack, child screens don't know about it.
    // Extend MediaQuery.padding.bottom so every CustomScrollView inside
    // automatically adds the correct bottom inset — same as CupertinoTabScaffold does.
    const tabBarHeight = 50.0;
    final mq = MediaQuery.of(context);
    // Reserve space for the floating tab bar by inflating padding.bottom.
    // When the IME is open, the scaffold body is already laid out above the
    // keyboard; SafeArea reads padding (not viewInsets) — keeping the full
    // inflated bottom while the keyboard is tall would leave a dead band above
    // the keyboard. When viewInsets.bottom is above [tabBarHeight], the tab bar
    // is covered, so use only the home-indicator inset. As the keyboard
    // dismisses and viewInsets shrinks below the tab bar height, blend the
    // synthetic tab-bar reserve back in so content never slides behind the
    // floating tab bar for a frame.
    final keyboardOverTabBar =
        (mq.viewInsets.bottom / tabBarHeight).clamp(0.0, 1.0);
    final bottomForContent =
        mq.padding.bottom + tabBarHeight * (1.0 - keyboardOverTabBar);
    final adjustedMq = mq.copyWith(
      padding: mq.padding.copyWith(bottom: bottomForContent),
    );

    return Stack(
      children: [
        // Content fills the full screen — padding.bottom now accounts for
        // the floating tab bar so nothing is obscured.
        Positioned.fill(
          child: MediaQuery(data: adjustedMq, child: shell),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CupertinoTabBar(
            currentIndex: shell.currentIndex,
            onTap: (index) {
              shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              );
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.folder, size: 20),
                activeIcon: Icon(CupertinoIcons.folder_fill, size: 20),
                label: 'Collections',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.clock, size: 20),
                activeIcon: Icon(CupertinoIcons.clock_fill, size: 20),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.list_bullet, size: 20),
                label: 'Envs',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.arrow_right_arrow_left, size: 20),
                label: 'WebSocket',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
