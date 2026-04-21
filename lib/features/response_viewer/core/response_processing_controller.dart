import 'package:aun_reqstudio/features/response_viewer/core/jobs/pretty_format_job.dart';
import 'package:aun_reqstudio/features/response_viewer/core/jobs/search_index_job.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_telemetry.dart';
import 'package:flutter/foundation.dart';

class ResponseProcessingController extends ChangeNotifier {
  ResponseProcessingController({ResponseViewerTelemetry? telemetry})
    : _telemetry = telemetry ?? const NoopResponseViewerTelemetry();

  final ResponseViewerTelemetry _telemetry;
  ResponsePrettyState prettyState = ResponsePrettyState.idle;
  ResponseSearchState searchState = ResponseSearchState.idle;

  void setPrettyState(ResponsePrettyState value) {
    if (prettyState == value) return;
    prettyState = value;
    notifyListeners();
  }

  void setSearchState(ResponseSearchState value) {
    if (searchState == value) return;
    searchState = value;
    notifyListeners();
  }

  int _searchToken = 0;
  int _prettyToken = 0;

  void invalidateSearch({
    ResponseSearchState nextState = ResponseSearchState.idle,
  }) {
    _searchToken++;
    setSearchState(nextState);
  }

  Future<PrettyFormatResult> computePretty({
    required String raw,
    required bool unwrapJson,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestToken = ++_prettyToken;
    setPrettyState(ResponsePrettyState.loading);
    try {
      final result = await compute(runPrettyFormatJob, (
        raw: raw,
        unwrapJson: unwrapJson,
      ));
      if (requestToken != _prettyToken) {
        return (text: raw, language: 'plaintext');
      }
      setPrettyState(ResponsePrettyState.ready);
      _telemetry.record(
        ResponseViewerTelemetryEvent(
          name: 'pretty_ready',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {'raw_length': raw.length, 'unwrap': unwrapJson},
        ),
      );
      return result;
    } catch (_) {
      setPrettyState(ResponsePrettyState.error);
      _telemetry.record(
        ResponseViewerTelemetryEvent(
          name: 'pretty_error',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {'raw_length': raw.length},
        ),
      );
      rethrow;
    }
  }

  Future<List<SearchMatch>> computeSearchMatches({
    required String text,
    required String query,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestToken = ++_searchToken;
    setSearchState(ResponseSearchState.indexing);
    final result = await compute(runSearchIndexJob, (text: text, query: query));
    if (requestToken != _searchToken) return const [];
    setSearchState(ResponseSearchState.ready);
    _telemetry.record(
      ResponseViewerTelemetryEvent(
        name: 'search_ready',
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {
          'text_length': text.length,
          'query_length': query.length,
          'matches': result.length,
        },
      ),
    );
    return result;
  }
}
