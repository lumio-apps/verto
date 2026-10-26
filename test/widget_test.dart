import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verto/core/engine.dart';
import 'package:verto/strings.dart';
import 'package:verto/theme.dart';
import 'package:verto/ui/big_text_screen.dart';
import 'package:verto/ui/logo.dart';
import 'package:verto/ui/word_sheet.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('word sheet works in $brightness theme', (tester) async {
      var added = 0;
      var kept = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(
            body: WordSheetBody(
              word: const MissingWord(word: 'nearest', gloss: 'निकटतम'),
              onAdd: () => added++,
              onKeep: () => kept++,
            ),
          ),
        ),
      );
      expect(find.text('nearest'), findsOneWidget);
      expect(find.text('निकटतम'), findsOneWidget);

      await tester.tap(find.text(S.addToTranslation));
      await tester.tap(find.text(S.keepAsIs));
      expect(added, 1);
      expect(kept, 1);
    });
  }

  testWidgets('big text screen shows the text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: const BigTextScreen(text: 'Namaste', rtl: false),
      ),
    );
    expect(find.text('Namaste'), findsOneWidget);
  });

  testWidgets('logo paints without errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: VertoLogo(size: 80)))));
    expect(find.byType(VertoLogo), findsOneWidget);
  });
}
