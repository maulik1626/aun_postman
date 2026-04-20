import 'package:aun_reqstudio/core/utils/assertion_runner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final testResultsProvider =
    StateProvider<List<TestResult>?>((ref) => null);
