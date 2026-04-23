import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/pre_request_variables_outcome.dart';
import 'package:flutter/material.dart';

/// Material bottom sheet for pre-request variables; mirrors bulk-edit layout in
/// [KeyValueEditorMaterial].
Future<PreRequestVariablesOutcome?> showPreRequestVariablesSheetMaterial(
  BuildContext context, {
  required String initialLines,
}) async {
  final controller = TextEditingController(text: initialLines);
  final result = await showModalBottomSheet<PreRequestVariablesOutcome?>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        top: false,
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx, PreRequestVariablesCleared());
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Theme.of(ctx).colorScheme.error,
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: controller,
                    maxLines: 12,
                    minLines: 8,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'baseUrl=https://api.example.com',
                      labelText: 'Entries',
                      helperText:
                          'Applied on Send after the environment (or history snapshot). '
                          'One line per row. Use tab, ":" or "=" separators.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppGradientButton.material(
                        fullWidth: true,
                        onPressed: () => Navigator.pop(
                          ctx,
                          PreRequestVariablesApplied(controller.text),
                        ),
                        child: const Text('Apply'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
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
