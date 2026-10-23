import 'package:flutter/material.dart';

import '../core/engine.dart';
import '../strings.dart';
import '../theme.dart';

/// Bottom sheet shown when the user taps a word that may be missing.
Future<void> showWordSheet(
  BuildContext context, {
  required MissingWord word,
  required VoidCallback onAdd,
  required VoidCallback onKeep,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => WordSheetBody(
      word: word,
      onAdd: () {
        Navigator.of(ctx).pop();
        onAdd();
      },
      onKeep: () {
        Navigator.of(ctx).pop();
        onKeep();
      },
    ),
  );
}

class WordSheetBody extends StatelessWidget {
  const WordSheetBody({super.key, required this.word, required this.onAdd, required this.onKeep});

  final MissingWord word;
  final VoidCallback onAdd;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(S.wordSheetTitle, style: TextStyle(fontSize: 13, color: kSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: kAmberBg, borderRadius: BorderRadius.circular(10)),
            child: Text(word.word, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kAmberInk)),
          ),
          const SizedBox(height: 14),
          const Text(S.wordSheetBody, style: TextStyle(color: kSecondary)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kSoft, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(word.gloss, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kDeep)),
                const SizedBox(height: 4),
                const Text(S.wordSheetSource, style: TextStyle(fontSize: 12, color: kSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(child: FilledButton(onPressed: onAdd, child: const Text(S.addToTranslation))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton(onPressed: onKeep, child: const Text(S.keepAsIs))),
            ],
          ),
        ],
      ),
    );
  }
}
