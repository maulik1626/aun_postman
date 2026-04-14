import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Material adaptive shell for Android.
///
/// Breakpoints (Material window classes):
///   Compact  < 600dp  → [NavigationBar] at bottom
///   Medium   600–839dp → [NavigationRail] on left
///   Expanded ≥ 840dp  → Extended [NavigationRail] on left (with labels)
class ShellScreenMaterial extends StatelessWidget {
  const ShellScreenMaterial({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _destinations = [
    (
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: 'Collections',
    ),
    (
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      label: 'History',
    ),
    (
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      label: 'Envs',
    ),
    (
      icon: Icons.compare_arrows_outlined,
      selectedIcon: Icons.compare_arrows,
      label: 'WebSocket',
    ),
  ];

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    if (isCompact) {
      return _CompactShell(
        shell: shell,
        destinations: _destinations,
        onTap: _onTap,
      );
    }

    final isExpanded = width >= 840;
    return _RailShell(
      shell: shell,
      destinations: _destinations,
      onTap: _onTap,
      extended: isExpanded,
    );
  }
}

// ── Compact: NavigationBar at bottom ─────────────────────────────────────────

class _CompactShell extends StatelessWidget {
  const _CompactShell({
    required this.shell,
    required this.destinations,
    required this.onTap,
  });

  final StatefulNavigationShell shell;
  final List<({IconData icon, IconData selectedIcon, String label})>
      destinations;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: onTap,
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Medium / Expanded: NavigationRail on left ─────────────────────────────────

class _RailShell extends StatelessWidget {
  const _RailShell({
    required this.shell,
    required this.destinations,
    required this.onTap,
    required this.extended,
  });

  final StatefulNavigationShell shell;
  final List<({IconData icon, IconData selectedIcon, String label})>
      destinations;
  final void Function(int) onTap;

  /// When [extended] is true the rail shows icon + label side-by-side
  /// (expanded window class). When false, icons only (medium class).
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: onTap,
            extended: extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 0.5),
          Expanded(child: shell),
        ],
      ),
    );
  }
}
