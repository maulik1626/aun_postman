import 'package:aun_postman/core/utils/assertion_runner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final testResultsProvider =
    StateProvider<List<TestResult>?>((ref) => null);
