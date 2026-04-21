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
}
