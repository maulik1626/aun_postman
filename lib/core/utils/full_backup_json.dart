import 'package:aun_reqstudio/core/utils/app_backup.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/active_environment_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/infrastructure/ws_saved_compose_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the same JSON payload as **Export all data** on Import/Export.
Future<String> buildFullBackupJson(WidgetRef ref) async {
  final collections = ref.read(collectionsProvider);
  final environments = ref.read(environmentsProvider);
  final history = ref.read(historyProvider);
  final wsSaved = ref.read(wsSavedComposeRepositoryProvider).getAll();
  final activeUid = ref.read(activeEnvironmentProvider)?.uid;

  return AppBackup.buildJson(
    collections: collections,
    environments: environments,
    history: history,
    wsSavedCompose: wsSaved,
    activeEnvironmentUid: activeUid,
  );
}
