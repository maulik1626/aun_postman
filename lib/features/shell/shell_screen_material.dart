import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/web/drop_json_import/json_drop_import_listener.dart';
import 'package:aun_reqstudio/features/import_export/json_import_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Material adaptive shell for Android.
///
/// Breakpoints (Material window classes):
///   Compact  < 600dp  → [NavigationBar] at bottom
///   Medium   600–839dp → [NavigationRail] on left
///   Expanded ≥ 840dp  → Extended [NavigationRail] on left (with labels)
class ShellScreenMaterial extends ConsumerStatefulWidget {
  const ShellScreenMaterial({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<ShellScreenMaterial> createState() =>
      _ShellScreenMaterialState();
}

class _ShellScreenMaterialState extends ConsumerState<ShellScreenMaterial> {
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
    (icon: Icons.tune_outlined, selectedIcon: Icons.tune, label: 'Envs'),
    (
      icon: Icons.compare_arrows_outlined,
      selectedIcon: Icons.compare_arrows,
      label: 'WebSocket',
    ),
  ];

  StatefulNavigationShell get _shell => widget.shell;

  void _onTap(int index) {
    _shell.goBranch(index, initialLocation: index == _shell.currentIndex);
  }

  void _openImportExport() {
    if (!mounted) return;
    context.go(AppRoutes.importExport);
  }

  Future<void> _handleDroppedJson(String content, String fileName) async {
    try {
      final outcome =
          await ImportExportJsonImporter.importSharedJsonFromContent(
            ref: ref,
            content: content,
            fileName: fileName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(outcome.statusMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ImportExportJsonImporter.errorMessageFor(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final shellContent = isCompact
        ? _CompactShell(
            shell: _shell,
            destinations: _destinations,
            onTap: _onTap,
          )
        : _RailShell(
            shell: _shell,
            destinations: _destinations,
            onTap: _onTap,
            extended: width >= 840,
            showImportExportSection: AppPlatform.usesWebCustomUi,
            onImportExportTap: _openImportExport,
          );

    if (!AppPlatform.usesWebCustomUi) {
      return shellContent;
    }

    return JsonDropImportListener(
      child: shellContent,
      onJsonDropped: _handleDroppedJson,
      onDropError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      },
    );
  }
}

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

class _RailShell extends StatelessWidget {
  const _RailShell({
    required this.shell,
    required this.destinations,
    required this.onTap,
    required this.extended,
    required this.showImportExportSection,
    required this.onImportExportTap,
  });

  final StatefulNavigationShell shell;
  final List<({IconData icon, IconData selectedIcon, String label})>
  destinations;
  final void Function(int) onTap;
  final bool extended;
  final bool showImportExportSection;
  final VoidCallback onImportExportTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: onTap,
            extended: extended,
            leading: showImportExportSection
                ? _ImportExportRailSection(
                    extended: extended,
                    onTap: onImportExportTap,
                  )
                : null,
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

class _ImportExportRailSection extends StatelessWidget {
  const _ImportExportRailSection({required this.extended, required this.onTap});

  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconButton = IconButton(
      onPressed: onTap,
      tooltip: 'Import / Export',
      icon: const Icon(Icons.import_export_outlined),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (extended)
            SizedBox(
              width: 168,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.import_export_outlined, size: 18),
                label: const Text('Import / Export'),
              ),
            )
          else
            iconButton,
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
