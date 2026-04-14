import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/utils/assertion_runner.dart';
import 'package:aun_reqstudio/domain/models/test_assertion.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/request_builder/providers/test_results_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestsTab extends ConsumerWidget {
  const TestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assertions = ref
        .watch(requestBuilderProvider.select((s) => s.assertions));
    final results = ref.watch(testResultsProvider);

    return Column(
      children: [
        // Results summary bar (shows after execution)
        if (results != null) _ResultsSummary(results: results),

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
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: () => _showAddSheet(context, ref, assertions),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.add_circled,
                      size: 16,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context)),

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
                      color: CupertinoTheme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      CupertinoIcons.checkmark_shield,
                      size: 40,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Assertions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add assertions to verify responses',
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context),
                    ),
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
              separatorBuilder: (_, __) => Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 16),
                color: CupertinoColors.separator.resolveFrom(context),
              ),
              itemBuilder: (context, i) {
                final a = assertions[i];
                final result = results?.where((r) => r.assertion.id == a.id).firstOrNull;
                return _AssertionRow(
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
      BuildContext context, WidgetRef ref, List<TestAssertion> current) {
    AssertionTarget target = AssertionTarget.statusCode;
    AssertionOp op = AssertionOp.equals;
    final expectedCtrl = TextEditingController();
    final propertyCtrl = TextEditingController();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGroupedBackground
                  .resolveFrom(ctx),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin:
                        const EdgeInsets.only(top: 8, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color:
                            CupertinoColors.separator.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Text('Add Assertion',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 32,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
                Container(
                    height: 0.5,
                    color:
                        CupertinoColors.separator.resolveFrom(ctx)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target picker
                      _SheetLabel(ctx, 'Check'),
                      const SizedBox(height: 6),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        color: CupertinoColors.tertiarySystemFill
                            .resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          _pickTarget(ctx, target, (t) {
                            setS(() {
                              target = t;
                              op = _defaultOp(t);
                            });
                          });
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(target.label,
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: CupertinoColors.label
                                          .resolveFrom(ctx))),
                            ),
                            Icon(CupertinoIcons.chevron_down,
                                size: 14,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(ctx)),
                          ],
                        ),
                      ),

                      // Property field (header name)
                      if (target == AssertionTarget.headerExists ||
                          target == AssertionTarget.headerEquals) ...[
                        const SizedBox(height: 12),
                        _SheetLabel(ctx, 'Header Name'),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: propertyCtrl,
                          placeholder: 'e.g. Content-Type',
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CupertinoColors
                                .tertiarySystemBackground
                                .resolveFrom(ctx),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],

                      // Operator picker
                      if (target != AssertionTarget.headerExists) ...[
                        const SizedBox(height: 12),
                        _SheetLabel(ctx, 'Operator'),
                        const SizedBox(height: 6),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          color: CupertinoColors.tertiarySystemFill
                              .resolveFrom(ctx),
                          borderRadius: BorderRadius.circular(10),
                          onPressed: () {
                            _pickOp(ctx, target, op, (o) {
                              setS(() => op = o);
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(op.label,
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: CupertinoColors.label
                                            .resolveFrom(ctx))),
                              ),
                              Icon(CupertinoIcons.chevron_down,
                                  size: 14,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(ctx)),
                            ],
                          ),
                        ),
                      ],

                      // Expected value
                      if (target != AssertionTarget.headerExists) ...[
                        const SizedBox(height: 12),
                        _SheetLabel(ctx, 'Expected Value'),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: expectedCtrl,
                          placeholder:
                              target == AssertionTarget.statusCode
                                  ? '200'
                                  : target ==
                                          AssertionTarget.responseTime
                                      ? '500'
                                      : 'value',
                          keyboardType: (target ==
                                      AssertionTarget.statusCode ||
                                  target == AssertionTarget.responseTime)
                              ? TextInputType.number
                              : TextInputType.text,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CupertinoColors
                                .tertiarySystemBackground
                                .resolveFrom(ctx),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      AppGradientButton(
                        fullWidth: true,
                        onPressed: () {
                          final property = propertyCtrl.text.trim();
                          final needsProperty =
                              target == AssertionTarget.headerExists ||
                                  target == AssertionTarget.headerEquals;
                          if (needsProperty && property.isEmpty) {
                            showCupertinoDialog<void>(
                              context: ctx,
                              builder: (dialogContext) => CupertinoAlertDialog(
                                title: const Text('Header name required'),
                                content: const Text(
                                    'Enter the header name to check.'),
                                actions: [
                                  CupertinoDialogAction(
                                    isDefaultAction: true,
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
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
                            showCupertinoDialog<void>(
                              context: ctx,
                              builder: (dialogContext) => CupertinoAlertDialog(
                                title: const Text('Expected value required'),
                                content: const Text(
                                  'Enter the value to assert against (e.g. status code, '
                                  'response time in ms, body text, or header value).',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    isDefaultAction: true,
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
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
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.add, size: 18),
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
          );
        });
      },
    );
  }

  AssertionOp _defaultOp(AssertionTarget target) {
    return switch (target) {
      AssertionTarget.statusCode => AssertionOp.equals,
      AssertionTarget.responseTime => AssertionOp.lessThan,
      AssertionTarget.bodyContains => AssertionOp.contains,
      AssertionTarget.headerExists => AssertionOp.equals,
      AssertionTarget.headerEquals => AssertionOp.equals,
    };
  }

  List<AssertionOp> _opsFor(AssertionTarget target) {
    return switch (target) {
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
  }

  void _pickTarget(BuildContext ctx, AssertionTarget current,
      void Function(AssertionTarget) onPick) {
    showCupertinoModalPopup<void>(
      context: ctx,
      builder: (c) => CupertinoActionSheet(
        title: const Text('Check'),
        actions: AssertionTarget.values
            .map((t) => CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(c);
                    onPick(t);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.label),
                      if (t == current) ...[
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.checkmark, size: 16),
                      ],
                    ],
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _pickOp(BuildContext ctx, AssertionTarget target,
      AssertionOp current, void Function(AssertionOp) onPick) {
    final ops = _opsFor(target);
    showCupertinoModalPopup<void>(
      context: ctx,
      builder: (c) => CupertinoActionSheet(
        title: const Text('Operator'),
        actions: ops
            .map((o) => CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(c);
                    onPick(o);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(o.label),
                      if (o == current) ...[
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.checkmark, size: 16),
                      ],
                    ],
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _SheetLabel(BuildContext ctx, String label) => Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
        ),
      );
}

// ── _ResultsSummary ───────────────────────────────────────────────────────────

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.results});
  final List<TestResult> results;

  @override
  Widget build(BuildContext context) {
    final passed = results.where((r) => r.passed).length;
    final total = results.length;
    final allPassed = passed == total;
    final color =
        allPassed ? CupertinoColors.systemGreen : CupertinoColors.systemRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            allPassed
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$passed / $total passed',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── _AssertionRow ─────────────────────────────────────────────────────────────

class _AssertionRow extends StatelessWidget {
  const _AssertionRow({
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
    if (passed == true) resultColor = CupertinoColors.systemGreen;
    if (passed == false) resultColor = CupertinoColors.systemRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CupertinoCheckbox(
            value: assertion.isEnabled,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    color: assertion.isEnabled
                        ? CupertinoColors.label.resolveFrom(context)
                        : CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    result!.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: resultColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (resultColor != null)
            Icon(
              result!.passed
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.xmark_circle_fill,
              color: resultColor,
              size: 18,
            ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: onDelete,
            child: const Icon(CupertinoIcons.trash,
                size: 16, color: CupertinoColors.destructiveRed),
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
