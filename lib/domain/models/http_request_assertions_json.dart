import 'package:aun_reqstudio/domain/models/test_assertion.dart';

List<TestAssertion> assertionsFromJson(Object? json) {
  if (json is! List) return [];
  return json
      .whereType<Map>()
      .map((e) => TestAssertion.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<Map<String, dynamic>> assertionsToJson(List<TestAssertion> list) =>
    list.map((e) => e.toJson()).toList();
