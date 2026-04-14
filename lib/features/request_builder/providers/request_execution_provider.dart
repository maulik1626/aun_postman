import 'package:aun_reqstudio/core/utils/assertion_runner.dart';
import 'package:aun_reqstudio/core/utils/oauth2_token_client.dart';
import 'package:aun_reqstudio/core/utils/request_name_from_url.dart';
import 'package:aun_reqstudio/core/utils/auth_merge.dart';
import 'package:aun_reqstudio/core/utils/variable_interpolator.dart';
import 'package:aun_reqstudio/data/http/dio_client.dart';
import 'package:aun_reqstudio/domain/models/auth_config.dart';
import 'package:aun_reqstudio/domain/models/history_entry.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:aun_reqstudio/features/environments/providers/active_environment_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/request_builder/providers/test_results_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:aun_reqstudio/infrastructure/collection_repository.dart';
import 'package:aun_reqstudio/infrastructure/history_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'request_execution_provider.g.dart';

@riverpod
class RequestExecution extends _$RequestExecution {
  static const _uuid = Uuid();
  CancelToken? _cancelToken;
  static final _interpolator = VariableInterpolator();

  /// Last successfully executed request (interpolated + merged auth), for HAR export.
  HttpRequest? _lastSentRequest;
  DateTime? _lastStartedAt;

  HttpRequest? get lastSentRequest => _lastSentRequest;
  DateTime? get lastStartedAt => _lastStartedAt;

  @override
  AsyncValue<HttpResponse?> build() => const AsyncData(null);

  Future<void> execute() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    _lastSentRequest = null;
    _lastStartedAt = null;

    final activeEnv = ref.read(activeEnvironmentProvider);
    final builderState = ref.read(requestBuilderProvider);
    final rawRequest = ref.read(requestBuilderProvider.notifier).toRequest();
    final vars = buildInterpolationVariableMap(
      builder: builderState,
      env: activeEnv,
    );
    final interpolated =
        _interpolator.interpolateRequestWithVariables(rawRequest, vars);
    final cUid = interpolated.collectionUid;
    final collection = (cUid != null && cUid.isNotEmpty)
        ? ref.read(collectionRepositoryProvider).getByUid(cUid)
        : null;
    final request = interpolated.copyWith(
      auth: mergeRequestAndCollectionAuth(
        interpolated.auth,
        collection?.auth ?? const NoAuth(),
      ),
    );

    if (request.url.isEmpty) {
      state = AsyncError('URL cannot be empty', StackTrace.current);
      return;
    }

    state = const AsyncLoading();

    try {
      var sendRequest = request;
      if (request.auth case final OAuth2Auth oa) {
        if (OAuth2TokenClient.shouldFetch(oa)) {
          final next = await OAuth2TokenClient.fetchAndMerge(oa);
          ref.read(requestBuilderProvider.notifier).setAuth(next);
          sendRequest = request.copyWith(auth: next);
        }
      }

      final settings = ref.read(appSettingsProvider);
      final defaultHdrs = _interpolator.interpolateHeadersWithVariables(
        settings.defaultHeaders,
        vars,
      );
      final startedAt = DateTime.now();
      final response = await DioClient.execute(
        sendRequest,
        cancelToken: _cancelToken,
        timeoutSeconds: settings.timeoutSeconds,
        followRedirects: settings.followRedirects,
        verifySsl: settings.verifySsl,
        httpProxy: settings.httpProxy,
        defaultHeaders: defaultHdrs,
      );
      state = AsyncData(response);
      _lastSentRequest = sendRequest;
      _lastStartedAt = startedAt;

      // Run test assertions
      final assertions = ref.read(requestBuilderProvider).assertions;
      if (assertions.isNotEmpty) {
        final results = AssertionRunner().run(response, assertions);
        ref.read(testResultsProvider.notifier).state = results;
      } else {
        ref.read(testResultsProvider.notifier).state = null;
      }

      // Persist to history (avoid generic "New Request" when we can title from URL)
      var requestForHistory = rawRequest;
      final trimmedName = rawRequest.name.trim();
      if ((trimmedName.isEmpty || trimmedName == 'New Request') &&
          rawRequest.url.trim().isNotEmpty) {
        requestForHistory = rawRequest.copyWith(
          name: suggestRequestNameFromUrl(rawRequest.url),
        );
      }

      final entry = HistoryEntry(
        uid: _uuid.v4(),
        request: requestForHistory,
        response: response,
        executedAt: DateTime.now(),
        variableSnapshot: Map<String, String>.from(vars),
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
