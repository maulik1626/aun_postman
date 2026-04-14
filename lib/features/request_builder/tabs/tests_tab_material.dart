import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/utils/assertion_runner.dart';
import 'package:aun_reqstudio/domain/models/test_assertion.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/request_builder/providers/test_results_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestsTabMaterial extends ConsumerWidget {
  const TestsTabMaterial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assertions =
        ref.watch(requestBuilderProvider.select((s) => s.assertions));
    final results = ref.watch(testResultsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return Column(
      children: [
        if (results != null) _ResultsSummaryMaterial(results: results),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'ASSERTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: secondary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddSheet(context, ref, assertions),
                icon: Icon(Icons.add_circle_outline, size: 16, color: primary),
                label: Text(
                  'Add',
                  style: TextStyle(fontSize: 14, color: primary),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).dividerColor,
        ),

        if (assertions.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.seedColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      size: 40,
                      color: AppColors.seedColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Assertions',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add assertions to verify responses',
                    style: TextStyle(fontSize: 15, color: secondary),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              primary: false,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: assertions.length,
              separatorBuilder: (_, __) => Divider(
                height: 0.5,
                indent: 16,
                color: Theme.of(context).dividerColor,
              ),
              itemBuilder: (context, i) {
                final a = assertions[i];
                final result = results
                    ?.where((r) => r.assertion.id == a.id)
                    .firstOrNull;
                return _AssertionRowMaterial(
                  assertion: a,
                  result: result,
                  onToggle: () {
                    final updated = [...assertions];
                    updated[i] = a.copyWith(isEnabled: !a.isEnabled);
                    ref
                        .read(requestBuilderProvider.notifier)
                        .setAssertions(updated);
                  },
                  onDelete: () {
                    final updated = [...assertions]..removeAt(i);
                    ref
                        .read(requestBuilderProvider.notifier)
                        .setAssertions(updated);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    List<TestAssertion> current,
  ) {
    AssertionTarget target = AssertionTarget.statusCode;
    AssertionOp op = AssertionOp.equals;
    final expectedCtrl = TextEditingController();
    final propertyCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          final secondary = Theme.of(ctx)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.55);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Text(
                          'Add Assertion',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(ctx).dividerColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Target picker
                        _sheetLabelMaterial(secondary, 'Check'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<AssertionTarget>(
                          initialValue: target,
                          decoration: const InputDecoration(),
                          items: [
                            for (final t in AssertionTarget.values)
                              DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ),
                          ],
                          onChanged: (t) {
                            if (t == null) return;
                            setS(() {
                              target = t;
                              op = _defaultOp(t);
                            });
                          },
                        ),

                        // Property field (header name)
                        if (target == AssertionTarget.headerExists ||
                            target == AssertionTarget.headerEquals) ...[
                          const SizedBox(height: 12),
                          _sheetLabelMaterial(secondary, 'Header Name'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: propertyCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Content-Type',
                            ),
                          ),
                        ],

                        // Operator picker
                        if (target != AssertionTarget.headerExists) ...[
                          const SizedBox(height: 12),
                          _sheetLabelMaterial(secondary, 'Operator'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<AssertionOp>(
                            initialValue: op,
                            decoration: const InputDecoration(),
                            items: [
                              for (final o in _opsFor(target))
                                DropdownMenuItem(
                                  value: o,
                                  child: Text(o.label),
                                ),
                            ],
                            onChanged: (o) {
                              if (o == null) return;
                              setS(() => op = o);
                            },
                          ),
                        ],

                        // Expected value
                        if (target != AssertionTarget.headerExists) ...[
                          const SizedBox(height: 12),
                          _sheetLabelMaterial(secondary, 'Expected Value'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: expectedCtrl,
                            decoration: InputDecoration(
                              hintText: target == AssertionTarget.statusCode
                                  ? '200'
                                  : target == AssertionTarget.responseTime
                                      ? '500'
                                      : 'value',
                            ),
                            keyboardType:
                                (target == AssertionTarget.statusCode ||
                                        target ==
                                            AssertionTarget.responseTime)
                                    ? TextInputType.number
                                    : TextInputType.text,
                          ),
                        ],

                        const SizedBox(height: 20),
                        AppGradientButton.material(
                          fullWidth: true,
                          onPressed: () {
                            final property = propertyCtrl.text.trim();
                            final needsProperty =
                                target == AssertionTarget.headerExists ||
                                    target == AssertionTarget.headerEquals;
                            if (needsProperty && property.isEmpty) {
                              showDialog<void>(
                                context: ctx,
                                builder: (d) => AlertDialog(
                                  title:
                                      const Text('Header name required'),
                                  content: const Text(
                                      'Enter the header name to check.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(d),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            final needsExpected =
                                target != AssertionTarget.headerExists;
                            final expected = expectedCtrl.text.trim();
                            if (needsExpected && expected.isEmpty) {
                              showDialog<void>(
                                context: ctx,
                                builder: (d) => AlertDialog(
                                  title: const Text(
                                      'Expected value required'),
                                  content: const Text(
                                    'Enter the value to assert against.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(d),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            final assertion = TestAssertion(
                              target: target,
                              op: op,
                              property: property,
                              expected: expected,
                            );
                            ref
                                .read(requestBuilderProvider.notifier)
                                .setAssertions([...current, assertion]);
                            Navigator.pop(ctx);
                            expectedCtrl.dispose();
                            propertyCtrl.dispose();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 6),
                              Text('Add Assertion'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    ).then((_) {
      // Dispose controllers if modal dismissed without tapping Add.
      expectedCtrl.dispose();
      propertyCtrl.dispose();
    });
  }

  AssertionOp _defaultOp(AssertionTarget target) => switch (target) {
        AssertionTarget.statusCode => AssertionOp.equals,
        AssertionTarget.responseTime => AssertionOp.lessThan,
        AssertionTarget.bodyContains => AssertionOp.contains,
        AssertionTarget.headerExists => AssertionOp.equals,
        AssertionTarget.headerEquals => AssertionOp.equals,
      };

  List<AssertionOp> _opsFor(AssertionTarget target) => switch (target) {
        AssertionTarget.statusCode => [
            AssertionOp.equals,
            AssertionOp.notEquals,
            AssertionOp.lessThan,
            AssertionOp.lessOrEqual,
            AssertionOp.greaterThan,
            AssertionOp.greaterOrEqual,
          ],
        AssertionTarget.responseTime => [
            AssertionOp.lessThan,
            AssertionOp.lessOrEqual,
            AssertionOp.greaterThan,
            AssertionOp.greaterOrEqual,
          ],
        AssertionTarget.bodyContains => [
            AssertionOp.contains,
            AssertionOp.notContains,
          ],
        AssertionTarget.headerExists => [],
        AssertionTarget.headerEquals => [
            AssertionOp.equals,
            AssertionOp.notEquals,
          ],
      };

  static Widget _sheetLabelMaterial(Color secondary, String label) =>
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
      );
}

// ── _ResultsSummaryMaterial ───────────────────────────────────────────────────

class _ResultsSummaryMaterial extends StatelessWidget {
  const _ResultsSummaryMaterial({required this.results});
  final List<TestResult> results;

  @override
  Widget build(BuildContext context) {
    final passed = results.where((r) => r.passed).length;
    final total = results.length;
    final allPassed = passed == total;
    final color = allPassed ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            allPassed ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$passed / $total passed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _AssertionRowMaterial ─────────────────────────────────────────────────────

class _AssertionRowMaterial extends StatelessWidget {
  const _AssertionRowMaterial({
    required this.assertion,
    required this.result,
    required this.onToggle,
    required this.onDelete,
  });

  final TestAssertion assertion;
  final TestResult? result;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final passed = result?.passed;
    Color? resultColor;
    if (passed == true) resultColor = Colors.green;
    if (passed == false) resultColor = Colors.red;

    final textColor = assertion.isEnabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Checkbox(
            value: assertion.isEnabled,
            activeColor: AppColors.seedColor,
            onChanged: (_) => onToggle(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildLabel(),
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
                if (result != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    result!.message,
                    style: TextStyle(fontSize: 12, color: resultColor),
                  ),
                ],
              ],
            ),
          ),
          if (resultColor != null)
            Icon(
              result!.passed ? Icons.check_circle : Icons.cancel,
              color: resultColor,
              size: 18,
            ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _buildLabel() {
    final target = assertion.target.label;
    if (assertion.target == AssertionTarget.headerExists) {
      return '$target: ${assertion.property}';
    }
    if (assertion.target == AssertionTarget.headerEquals) {
      return '${assertion.property} ${assertion.op.label} ${assertion.expected}';
    }
    return '$target ${assertion.op.label} ${assertion.expected}';
  }
}
