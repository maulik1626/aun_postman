import 'package:aun_postman/domain/models/http_response.dart';
import 'package:aun_postman/domain/models/test_assertion.dart';

class TestResult {
  const TestResult({
    required this.assertion,
    required this.passed,
    required this.actual,
    required this.message,
  });

  final TestAssertion assertion;
  final bool passed;
  final String actual;
  final String message;
}

class AssertionRunner {
  List<TestResult> run(HttpResponse response, List<TestAssertion> assertions) {
    return assertions
        .where((a) => a.isEnabled)
        .map((a) => _evaluate(response, a))
        .toList();
  }

  TestResult _evaluate(HttpResponse response, TestAssertion a) {
    switch (a.target) {
      case AssertionTarget.statusCode:
        final actual = response.statusCode;
        final expected = int.tryParse(a.expected.trim());
        if (expected == null) {
          return TestResult(
            assertion: a,
            passed: false,
            actual: '$actual',
            message: 'Expected value "${a.expected}" is not a number',
          );
        }
        final passed = _compareInt(actual, a.op, expected);
        return TestResult(
          assertion: a,
          passed: passed,
          actual: '$actual',
          message: 'Status $actual ${a.op.label} ${a.expected}',
        );

      case AssertionTarget.responseTime:
        final actual = response.durationMs;
        final expected = int.tryParse(a.expected.trim());
        if (expected == null) {
          return TestResult(
            assertion: a,
            passed: false,
            actual: '${actual}ms',
            message: 'Expected value "${a.expected}" is not a number',
          );
        }
        final passed = _compareInt(actual, a.op, expected);
        return TestResult(
          assertion: a,
          passed: passed,
          actual: '${actual}ms',
          message: '${actual}ms ${a.op.label} ${a.expected}ms',
        );

      case AssertionTarget.bodyContains:
        final body = response.body;
        final contains = body.contains(a.expected);
        final passed =
            a.op == AssertionOp.contains ? contains : !contains;
        return TestResult(
          assertion: a,
          passed: passed,
          actual: contains ? 'found' : 'not found',
          message: 'Body ${a.op.label} "${a.expected}"',
        );

      case AssertionTarget.headerExists:
        final headerName = a.property.toLowerCase();
        final exists = response.headers.keys
            .any((k) => k.toLowerCase() == headerName);
        return TestResult(
          assertion: a,
          passed: exists,
          actual: exists ? 'exists' : 'missing',
          message: 'Header "${a.property}" ${exists ? "exists" : "not found"}',
        );

      case AssertionTarget.headerEquals:
        final headerName = a.property.toLowerCase();
        final headerValue = response.headers.entries
            .where((e) => e.key.toLowerCase() == headerName)
            .map((e) => e.value)
            .firstOrNull;
        if (headerValue == null) {
          return TestResult(
            assertion: a,
            passed: false,
            actual: 'missing',
            message: 'Header "${a.property}" not found',
          );
        }
        final passed = a.op == AssertionOp.equals
            ? headerValue == a.expected
            : headerValue != a.expected;
        return TestResult(
          assertion: a,
          passed: passed,
          actual: headerValue,
          message: '"$headerValue" ${a.op.label} "${a.expected}"',
        );
    }
  }

  bool _compareInt(int actual, AssertionOp op, int expected) {
    return switch (op) {
      AssertionOp.equals => actual == expected,
      AssertionOp.notEquals => actual != expected,
      AssertionOp.lessThan => actual < expected,
      AssertionOp.lessOrEqual => actual <= expected,
      AssertionOp.greaterThan => actual > expected,
      AssertionOp.greaterOrEqual => actual >= expected,
      _ => false,
    };
  }
}
