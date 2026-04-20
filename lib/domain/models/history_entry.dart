import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

@freezed
class HistoryEntry with _$HistoryEntry {
  const factory HistoryEntry({
    required String uid,
    required HttpRequest request,
    required HttpResponse response,
    required DateTime executedAt,
    /// Active environment variable map at send time (for faithful replay from history).
    @Default({}) Map<String, String> variableSnapshot,
  }) = _HistoryEntry;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$HistoryEntryFromJson(json);
}
