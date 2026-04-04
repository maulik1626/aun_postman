import 'package:uuid/uuid.dart';

enum AssertionTarget {
  statusCode('Status Code'),
  responseTime('Response Time (ms)'),
  bodyContains('Body Contains'),
  headerExists('Header Exists'),
  headerEquals('Header Equals');

  const AssertionTarget(this.label);
  final String label;
}

enum AssertionOp {
  equals('=='),
  notEquals('!='),
  lessThan('<'),
  lessOrEqual('<='),
  greaterThan('>'),
  greaterOrEqual('>='),
  contains('contains'),
  notContains('not contains');

  const AssertionOp(this.label);
  final String label;
}

class TestAssertion {
  TestAssertion({
    String? id,
    required this.target,
    required this.op,
    this.property = '',
    required this.expected,
    this.isEnabled = true,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final AssertionTarget target;
  final AssertionOp op;
  final String property; // e.g., header name
  final String expected;
  final bool isEnabled;

  TestAssertion copyWith({
    AssertionTarget? target,
    AssertionOp? op,
    String? property,
    String? expected,
    bool? isEnabled,
  }) =>
      TestAssertion(
        id: id,
        target: target ?? this.target,
        op: op ?? this.op,
        property: property ?? this.property,
        expected: expected ?? this.expected,
        isEnabled: isEnabled ?? this.isEnabled,
      );
}
