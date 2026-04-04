import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: shell),
        CupertinoTabBar(
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
      ],
    );
  }
}
