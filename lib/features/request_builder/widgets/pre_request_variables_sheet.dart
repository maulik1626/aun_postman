import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/pre_request_variables_outcome.dart';
import 'package:flutter/cupertino.dart';

/// Shows the pre-request variables editor as a Cupertino modal sheet.
/// Layout matches [KeyValueEditor] bulk-edit sheet (handle, title, field, hint, Apply, Cancel).
/// [null] means cancel or dismiss.
Future<PreRequestVariablesOutcome?> showPreRequestVariablesSheetCupertino(
  BuildContext context, {
  required String initialLines,
}) async {
  final controller = TextEditingController(text: initialLines);
  final result = await showCupertinoModalPopup<PreRequestVariablesOutcome?>(
    context: context,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(ctx),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        bottom:
            MediaQuery.of(ctx).viewInsets.bottom +
            MediaQuery.of(ctx).padding.bottom +
            16,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(ctx).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.separator.resolveFrom(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Pre-request variables',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () {
                        Navigator.pop(ctx, PreRequestVariablesCleared());
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.destructiveRed.resolveFrom(
                            ctx,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoTextField(
                  controller: controller,
                  maxLines: 12,
                  minLines: 8,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 14,
                  ),
                  padding: const EdgeInsets.all(16),
                  placeholder: 'baseUrl=https://api.example.com',
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemBackground.resolveFrom(
                      ctx,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Applied on Send after the environment (or history snapshot). '
                  'One line per row. Separators: tab, ":" or "=".',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(
                        ctx,
                        PreRequestVariablesApplied(controller.text),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.ctaGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onPressed: () => Navigator.pop(ctx, null),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            ctx,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (!context.mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    return result;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
  return result;
}
