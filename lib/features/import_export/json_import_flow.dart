import 'dart:convert';

import 'package:aun_reqstudio/core/errors/app_exception.dart';
import 'package:aun_reqstudio/core/utils/app_backup.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_importer.dart';
import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class JsonImportOutcome {
  const JsonImportOutcome({
    required this.statusMessage,
    this.lastImportedEnvUid,
  });

  final String statusMessage;
  final String? lastImportedEnvUid;
}

class ImportExportJsonImporter {
  ImportExportJsonImporter._();

  static const _uuid = Uuid();

  static Future<JsonImportOutcome> importCollectionFromContent({
    required WidgetRef ref,
    required String content,
  }) async {
    final collection = CollectionV21Importer.import(content);
    await ref.read(collectionsProvider.notifier).importCollection(collection);

    final variableNames = CollectionV21Importer.extractVariableNames(content);
    String? createdEnvUid;
    if (variableNames.isNotEmpty) {
      final environment = _buildEnvironmentFromVarNames(
        '${collection.name} Variables',
        variableNames,
      );
      createdEnvUid = environment.uid;
      await ref
          .read(environmentsProvider.notifier)
          .importEnvironment(environment);
    }

    return JsonImportOutcome(
      statusMessage: createdEnvUid != null
          ? 'Imported "${collection.name}" and created an environment with ${variableNames.length} variables'
          : 'Imported "${collection.name}" successfully',
      lastImportedEnvUid: createdEnvUid,
    );
  }

  static Future<JsonImportOutcome> importEnvironmentFromContent({
    required WidgetRef ref,
    required String content,
  }) async {
    final environment = CollectionV21Importer.importEnvironment(content);
    await ref.read(environmentsProvider.notifier).importEnvironment(environment);
    return JsonImportOutcome(
      statusMessage:
          'Imported environment "${environment.name}" with ${environment.variables.length} variables',
      lastImportedEnvUid: environment.uid,
    );
  }

  static Future<JsonImportOutcome> importSharedJsonFromContent({
    required WidgetRef ref,
    required String content,
    required String fileName,
  }) async {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw ImportException(
        'We could not import "$fileName". The shared file must be a JSON object.',
      );
    }

    if (_looksLikeReqStudioBackup(decoded)) {
      throw ImportException(
        '“$fileName” looks like a ReqStudio backup. For safety, shared files can import collections and environments only. Use "Restore from backup" inside Import / Export if you want to replace local data.',
      );
    }

    try {
      return await importCollectionFromContent(ref: ref, content: content);
    } on ImportException {
      // Fall through to environment import.
    }

    try {
      return await importEnvironmentFromContent(ref: ref, content: content);
    } on ImportException {
      throw ImportException(
        'We could not import "$fileName". Supported shared files are Postman collection v2.1 JSON and Postman environment JSON.',
      );
    }
  }

  static String errorMessageFor(Object error) {
    if (error is AppException) return error.message;
    return error.toString();
  }

  static bool _looksLikeReqStudioBackup(Map<String, dynamic> json) {
    final format = json['format'];
    return format == AppBackup.format || format == AppBackup.legacyFormat;
  }

  static Environment _buildEnvironmentFromVarNames(
    String name,
    List<String> variableNames,
  ) {
    final now = DateTime.now();
    return Environment(
      uid: _uuid.v4(),
      name: name,
      variables: variableNames
          .map(
            (key) => EnvironmentVariable(
              uid: _uuid.v4(),
              key: key,
              value: '',
            ),
          )
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
  }
}
