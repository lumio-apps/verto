import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/engine.dart';
import '../core/languages.dart';
import '../core/translation_controller.dart';
import '../services.dart';
import '../strings.dart';
import '../theme.dart';
import 'logo.dart';
import 'word_sheet.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key, required this.onOpenLanguages});

  final VoidCallback onOpenLanguages;

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _text = TextEditingController();
  TranslationController? _tc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tc == null) {
      final tc = AppScope.of(context).translation;
      _tc = tc;
      _text.text = tc.input;
      tc.addListener(_syncText);
    }
  }

  void _syncText() {
    final tc = _tc!;
    if (_text.text != tc.input) {
      _text.value = TextEditingValue(
        text: tc.input,
        selection: TextSelection.collapsed(offset: tc.input.length),
      );
    }
  }

  @override
  void dispose() {
    _tc?.removeListener(_syncText);
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final tc = services.translation;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[tc, services.engine, services.packs]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            const _Header(),
            const SizedBox(height: 14),
            if (!tc.hasLanguage)
              _NoLanguageCard(onTap: widget.onOpenLanguages)
            else ...<Widget>[
              _LanguageBar(tc: tc, onMore: widget.onOpenLanguages),
              const SizedBox(height: 12),
              _InputCard(tc: tc, controller: _text),
              const SizedBox(height: 12),
              _OutputCard(tc: tc, engine: services.engine),
              if (tc.missing.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MissingWords(tc: tc),
              ],
              if (tc.history.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                _Recent(tc: tc),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        VertoLogo(size: 34),
        SizedBox(width: 10),
        Text(S.appName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kDeep)),
        SizedBox(width: 10),
        Text(S.tagline, style: TextStyle(fontSize: 12, color: kSecondary)),
      ],
    );
  }
}

class _NoLanguageCard extends StatelessWidget {
  const _NoLanguageCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(S.noLanguageTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(S.noLanguageBody, style: TextStyle(color: kSecondary, height: 1.4)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: const Text(S.openLanguages)),
        ],
      ),
    );
  }
}

class _LanguageBar extends StatelessWidget {
  const _LanguageBar({required this.tc, required this.onMore});

  final TranslationController tc;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    Widget chip(Language l, {required bool pickable}) => Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: pickable ? () => _pick(context) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        l.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    if (pickable) const Icon(Icons.expand_more_rounded, size: 20, color: kSecondary),
                  ],
                ),
              ),
            ),
          ),
        );

    final left = tc.from;
    final right = tc.to;
    return Row(
      children: <Widget>[
        chip(left, pickable: left.code != 'en'),
        IconButton(
          tooltip: S.swap,
          onPressed: tc.swap,
          icon: const Icon(Icons.swap_horiz_rounded, color: kPrimary),
        ),
        chip(right, pickable: right.code != 'en'),
      ],
    );
  }

  void _pick(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(S.pickLanguage, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final l in tc.installedLanguages)
              ListTile(
                title: Text(l.name),
                subtitle: Text(l.native),
                trailing: l.code == tc.foreign ? const Icon(Icons.check_rounded, color: kPrimary) : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  tc.setForeign(l.code);
                },
              ),
            ListTile(
              leading: const Icon(Icons.add_rounded, color: kPrimary),
              title: const Text(S.getMoreLanguages),
              onTap: () {
                Navigator.of(ctx).pop();
                onMore();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.tc, required this.controller});

  final TranslationController tc;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: tc.setInput,
              minLines: 4,
              maxLines: 10,
              textDirection: tc.from.rtl ? TextDirection.rtl : TextDirection.ltr,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 19, height: 1.4),
              decoration: const InputDecoration(
                hintText: S.inputHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (tc.input.isNotEmpty)
            IconButton(
              onPressed: tc.clear,
              icon: const Icon(Icons.close_rounded, color: kSecondary),
            ),
        ],
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.tc, required this.engine});

  final TranslationController tc;
  final Engine engine;

  @override
  Widget build(BuildContext context) {
    final failed = engine.status == EngineStatus.failed;
    final starting = engine.status == EngineStatus.starting;
    final hasOutput = tc.output.isNotEmpty;

    Widget body;
    if (failed) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(S.engineFailed, style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText(
            engine.error ?? '',
            maxLines: 8,
            style: const TextStyle(color: kSoft, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: engine.retry, child: const Text(S.retry)),
        ],
      );
    } else if (tc.error != null) {
      body = Text(tc.error!, style: const TextStyle(color: Colors.white, fontSize: 16));
    } else if (hasOutput) {
      body = SelectableText(
        tc.output,
        textDirection: tc.to.rtl ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.4, fontWeight: FontWeight.w500),
      );
    } else {
      body = Text(
        starting ? S.engineStarting : S.outputEmpty,
        style: const TextStyle(color: kMid, fontSize: 17),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (tc.translating || starting)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3, color: kMid, backgroundColor: kDeep),
            ),
          body,
          if (hasOutput) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(child: _CoverageChip(tc: tc)),
                IconButton(
                  tooltip: S.copy,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: tc.output));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(S.copied), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                ),
                IconButton(
                  tooltip: S.share,
                  onPressed: () => SharePlus.instance.share(ShareParams(text: tc.output)),
                  icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CoverageChip extends StatelessWidget {
  const _CoverageChip({required this.tc});

  final TranslationController tc;

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, Color bg, Color fg, {Widget? lead}) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (lead != null) ...<Widget>[lead, const SizedBox(width: 6)],
                Flexible(
                  child: Text(text, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );

    if (tc.phase == CheckPhase.checking) {
      return pill(
        S.checkingWords,
        kDeep,
        kSoft,
        lead: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: kSoft),
        ),
      );
    }
    final check = tc.check;
    if (tc.phase != CheckPhase.done || check == null) return const SizedBox.shrink();
    if (tc.missing.isNotEmpty) {
      return pill(S.wordsToCheck(tc.missing.length), kAmberBg, kAmberInk);
    }
    if (check.total == 0) return const SizedBox.shrink();
    if (check.checked < check.total) {
      return pill(S.partlyChecked(check.checked, check.total), kSoft, kDeep);
    }
    return pill(
      S.allCovered(check.total),
      kGreenBg,
      kGreenInk,
      lead: const Icon(Icons.check_circle_rounded, size: 15, color: kGreenInk),
    );
  }
}

class _MissingWords extends StatelessWidget {
  const _MissingWords({required this.tc});

  final TranslationController tc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(S.tapWordHint, style: TextStyle(color: kSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final w in tc.missing)
              ActionChip(
                label: Text(w.word),
                backgroundColor: kAmberBg,
                side: const BorderSide(color: kAmber),
                labelStyle: const TextStyle(color: kAmberInk, fontWeight: FontWeight.w600),
                onPressed: () => showWordSheet(
                  context,
                  word: w,
                  onAdd: () => tc.addWord(w),
                  onKeep: () => tc.keepAsIs(w),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.tc});

  final TranslationController tc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(S.recent, style: TextStyle(fontSize: 13, color: kSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final h in tc.history)
              ActionChip(
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(h, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                backgroundColor: Colors.white,
                side: const BorderSide(color: kBorder),
                onPressed: () => tc.useHistory(h),
              ),
          ],
        ),
      ],
    );
  }
}
