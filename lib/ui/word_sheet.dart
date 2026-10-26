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
    final c = context.vc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(S.wordSheetTitle, style: TextStyle(fontSize: 13, color: c.secondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: c.amberBg, borderRadius: BorderRadius.circular(10)),
            child: Text(word.word, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.amberInk)),
          ),
          const SizedBox(height: 14),
          Text(S.wordSheetBody, style: TextStyle(color: c.secondary)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.soft, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(word.gloss, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: c.heading)),
                const SizedBox(height: 4),
                Text(S.wordSheetSource, style: TextStyle(fontSize: 12, color: c.secondary)),
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
