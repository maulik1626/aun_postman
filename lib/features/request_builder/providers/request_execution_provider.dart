import 'package:aun_postman/core/utils/assertion_runner.dart';
import 'package:aun_postman/core/utils/variable_interpolator.dart';
import 'package:aun_postman/data/http/dio_client.dart';
import 'package:aun_postman/domain/models/history_entry.dart';
import 'package:aun_postman/domain/models/http_response.dart';
import 'package:aun_postman/features/environments/providers/active_environment_provider.dart';
import 'package:aun_postman/features/history/providers/history_provider.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_postman/features/request_builder/providers/test_results_provider.dart';
import 'package:aun_postman/features/settings/providers/app_settings_provider.dart';
import 'package:aun_postman/infrastructure/history_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'request_execution_provider.g.dart';

@riverpod
class RequestExecution extends _$RequestExecution {
  static const _uuid = Uuid();
  CancelToken? _cancelToken;
  static final _interpolator = VariableInterpolator();

  @override
  AsyncValue<HttpResponse?> build() => const AsyncData(null);

  Future<void> execute() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final activeEnv = ref.read(activeEnvironmentProvider);
    final rawRequest = ref.read(requestBuilderProvider.notifier).toRequest();
    final request = _interpolator.interpolateRequest(rawRequest, activeEnv);

    if (request.url.isEmpty) {
      state = AsyncError('URL cannot be empty', StackTrace.current);
      return;
    }

    state = const AsyncLoading();

    try {
      final settings = ref.read(appSettingsProvider);
      final response = await DioClient.execute(
        request,
        cancelToken: _cancelToken,
        timeoutSeconds: settings.timeoutSeconds,
        followRedirects: settings.followRedirects,
      );
      state = AsyncData(response);

      // Run test assertions
      final assertions = ref.read(requestBuilderProvider).assertions;
      if (assertions.isNotEmpty) {
        final results = AssertionRunner().run(response, assertions);
        ref.read(testResultsProvider.notifier).state = results;
      } else {
        ref.read(testResultsProvider.notifier).state = null;
      }

      // Persist to history
      final entry = HistoryEntry(
        uid: _uuid.v4(),
        request: rawRequest,
        response: response,
        executedAt: DateTime.now(),
      );
      await ref.read(historyRepositoryProvider).save(entry);
      ref.invalidate(historyProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void cancel() {
    _cancelToken?.cancel('Cancelled by user');
    _cancelToken = null;
    state = const AsyncData(null);
  }
}
