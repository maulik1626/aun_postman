import 'package:aun_reqstudio/features/response_viewer/core/jobs/pretty_format_job.dart';
import 'package:aun_reqstudio/features/response_viewer/core/jobs/search_index_job.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';
import 'package:flutter/foundation.dart';

class ResponseProcessingController extends ChangeNotifier {
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

  Future<PrettyFormatResult> computePretty({
    required String raw,
    required bool unwrapJson,
  }) async {
    setPrettyState(ResponsePrettyState.loading);
    try {
      final result = await compute(
        runPrettyFormatJob,
        (raw: raw, unwrapJson: unwrapJson),
      );
      setPrettyState(ResponsePrettyState.ready);
      return result;
    } catch (_) {
      setPrettyState(ResponsePrettyState.error);
      rethrow;
    }
  }

  Future<List<SearchMatch>> computeSearchMatches({
    required String text,
    required String query,
  }) async {
    final requestToken = ++_searchToken;
    setSearchState(ResponseSearchState.indexing);
    final result = await compute(runSearchIndexJob, (text: text, query: query));
    if (requestToken != _searchToken) return const [];
    setSearchState(ResponseSearchState.ready);
    return result;
  }
}
