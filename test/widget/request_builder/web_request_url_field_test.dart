import 'package:aun_reqstudio/app/web/web_chrome_layout.dart';
import 'package:aun_reqstudio/features/request_builder/web/web_request_url_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'URL field caret sits at rendered text end for templated URL with clear',
    (tester) async {
      final controller = TextEditingController(
        text: '{{staging}}/authentication/send_otp/',
      );
      final focus = FocusNode();
      addTearDown(() {
        controller.dispose();
        focus.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange,
              brightness: Brightness.dark,
            ),
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 520,
                height: kWebChromeSingleLineFieldHeight,
                child: WebRequestUrlField(
                  controller: controller,
                  focusNode: focus,
                  onChanged: (_) {},
                  definedEnvKeys: const {'staging'},
                  borderColor: Colors.grey,
                  focusedBorderColor: Colors.blue,
                  fillColor: const Color(0xFF1E1E1E),
                  embeddedInComposite: true,
                  showClearButton: true,
                  onClear: () {},
                ),
              ),
            ),
          ),
        ),
      );

      focus.requestFocus();
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      await tester.pumpAndSettle();

      final editableFinder = find.descendant(
        of: find.byType(WebRequestUrlField),
        matching: find.byType(EditableText),
      );
      final state = tester.state<EditableTextState>(editableFinder);
      final re = state.renderEditable;
      final text = controller.text;

      final textBoxes = re.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      );
      expect(textBoxes, isNotEmpty);

      final renderedTextEnd = textBoxes.last.right;
      final caretAtTextEnd = re
          .getLocalRectForCaret(TextPosition(offset: text.length))
          .left;
      expect(
        (caretAtTextEnd - renderedTextEnd).abs(),
        lessThan(2.5),
        reason: 'caret should not leave fake trailing spaces after URL text',
      );

      for (var i = 0; i < text.length; i++) {
        final ch = text[i];
        final selectedChar = re.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + 1),
        );
        if (selectedChar.isEmpty) continue;
        final renderedAdvance =
            selectedChar.last.right - selectedChar.first.left;
        final caretAdvance =
            re.getLocalRectForCaret(TextPosition(offset: i + 1)).left -
            re.getLocalRectForCaret(TextPosition(offset: i)).left;
        expect(
          (caretAdvance - renderedAdvance).abs(),
          lessThan(2.5),
          reason: 'caret advance at offset $i ("$ch")',
        );
      }
    },
  );
}
