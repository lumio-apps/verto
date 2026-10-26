import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/engine.dart';
import '../core/languages.dart';
import '../core/translation_controller.dart';
import '../services.dart';
import '../strings.dart';
import '../theme.dart';
import 'big_text_screen.dart';
import 'language_picker.dart';
import 'logo.dart';
import 'word_sheet.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key, required this.onOpenLanguages});

  final VoidCallback onOpenLanguages;

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> with WidgetsBindingObserver {
  final TextEditingController _text = TextEditingController();
  TranslationController? _tc;
  String? _clip;
  static String _handledClip = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
  }

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
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

  Future<void> _checkClipboard() async {
    if (!mounted) return;
    final services = AppScope.of(context);
    final tc = services.translation;
    if (!services.settings.clipboardOffer || !tc.hasLanguage) {
      if (_clip != null) setState(() => _clip = null);
      return;
    }
    String? text;
    try {
      text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final offer = text != null &&
        text.isNotEmpty &&
        text.length <= 3000 &&
        text != _handledClip &&
        text != tc.input.trim();
    setState(() => _clip = offer ? text : null);
  }

  void _useClip() {
    final text = _clip;
    if (text == null) return;
    _handledClip = text;
    setState(() => _clip = null);
    _tc!.loadText(text);
  }

  void _dismissClip() {
    _handledClip = _clip ?? '';
    setState(() => _clip = null);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) _tc?.loadText(text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tc?.removeListener(_syncText);
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final tc = services.translation;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        tc,
        services.engine,
        services.packs,
        services.history,
        services.speech,
      ]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            const _Header(),
            const SizedBox(height: 14),
            if (!tc.hasLanguage)
              _NoLanguageCard(onTap: widget.onOpenLanguages)
            else ...<Widget>[
              if (_clip != null) ...<Widget>[
                _ClipboardBanner(text: _clip!, onUse: _useClip, onDismiss: _dismissClip),
                const SizedBox(height: 12),
              ],
              _LanguageBar(tc: tc, onMore: widget.onOpenLanguages),
              const SizedBox(height: 12),
              _InputCard(tc: tc, controller: _text, onPaste: _paste),
              const SizedBox(height: 12),
              _OutputCard(tc: tc, services: services),
              if (tc.missing.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MissingWords(tc: tc),
              ],
              if (services.history.recent().isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                _Recent(tc: tc, services: services),
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
    final c = context.vc;
    return Row(
      children: <Widget>[
        const VertoLogo(size: 34),
        const SizedBox(width: 10),
        Text(S.appName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.heading)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(S.tagline, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.secondary)),
        ),
      ],
    );
  }
}

BoxDecoration _card(BuildContext context) {
  final c = context.vc;
  return BoxDecoration(
    color: c.card,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: c.border),
  );
}

class _NoLanguageCard extends StatelessWidget {
  const _NoLanguageCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(S.noLanguageTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(S.noLanguageBody, style: TextStyle(color: c.secondary, height: 1.4)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: const Text(S.openLanguages)),
        ],
      ),
    );
  }
}

class _ClipboardBanner extends StatelessWidget {
  const _ClipboardBanner({required this.text, required this.onUse, required this.onDismiss});

  final String text;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(color: c.soft, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: <Widget>[
          Icon(Icons.content_paste_rounded, color: c.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(S.clipboardTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.heading)),
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.secondary)),
              ],
            ),
          ),
          TextButton(onPressed: onUse, child: const Text(S.clipboardAction)),
          IconButton(
            tooltip: S.clipboardDismiss,
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, size: 18, color: c.secondary),
          ),
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
    final c = context.vc;
    Widget chip(Language l, {required bool pickable}) => Expanded(
          child: Material(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: pickable ? () => _pick(context) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
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
                    if (pickable) Icon(Icons.expand_more_rounded, size: 20, color: c.secondary),
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
          icon: Icon(Icons.swap_horiz_rounded, color: c.accent),
        ),
        chip(right, pickable: right.code != 'en'),
      ],
    );
  }

  void _pick(BuildContext context) {
    showLanguagePicker(
      context,
      languages: tc.installedLanguages,
      selected: tc.foreign,
      onSelect: tc.setForeign,
      onMore: onMore,
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.tc, required this.controller, required this.onPaste});

  final TranslationController tc;
  final TextEditingController controller;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: _card(context),
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
              icon: Icon(Icons.close_rounded, color: c.secondary),
            )
          else
            IconButton(
              tooltip: S.paste,
              onPressed: onPaste,
              icon: Icon(Icons.content_paste_rounded, color: c.secondary),
            ),
        ],
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.tc, required this.services});

  final TranslationController tc;
  final Services services;

  Future<void> _speak(BuildContext context) async {
    final speech = services.speech;
    if (speech.speaking) {
      await speech.stop();
      return;
    }
    final msg = await speech.speak(tc.output, tc.to.code, tc.to.name);
    if (msg != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    final engine = services.engine;
    final failed = engine.status == EngineStatus.failed;
    final starting = engine.status == EngineStatus.starting;
    final hasOutput = tc.output.isNotEmpty;

    Widget body;
    if (failed) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(S.engineFailed, style: TextStyle(color: c.onHero, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText(
            engine.error ?? '',
            maxLines: 8,
            style: TextStyle(color: c.heroMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: engine.retry, child: const Text(S.retry)),
        ],
      );
    } else if (tc.error != null) {
      body = Text(tc.error!, style: TextStyle(color: c.onHero, fontSize: 16));
    } else if (hasOutput) {
      body = SelectableText(
        tc.displayOutput,
        textDirection: tc.displayIsRtl ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(color: c.onHero, fontSize: 22, height: 1.4, fontWeight: FontWeight.w500),
      );
    } else {
      body = Text(
        starting ? S.engineStarting : S.outputEmpty,
        style: TextStyle(color: c.heroMuted, fontSize: 17),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.hero, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (tc.translating || starting)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3, color: c.heroMuted, backgroundColor: c.heroDeep),
            ),
          body,
          if (hasOutput) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _CoverageChip(tc: tc),
                if (tc.romanSupported && tc.roman.isNotEmpty)
                  _Pill(
                    text: S.romanToggle,
                    bg: tc.showRoman ? c.onHero : c.heroDeep,
                    fg: tc.showRoman ? c.hero : c.onHero,
                    lead: Icon(Icons.abc_rounded, size: 18, color: tc.showRoman ? c.hero : c.onHero),
                    onTap: tc.toggleRoman,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  tooltip: tc.isFavorite ? S.unfavorite : S.favorite,
                  onPressed: tc.toggleFavorite,
                  icon: Icon(
                    tc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: tc.isFavorite ? const Color(0xFFFFD36B) : c.onHero,
                  ),
                ),
                IconButton(
                  tooltip: services.speech.speaking ? S.stopSpeaking : S.speak,
                  onPressed: () => _speak(context),
                  icon: Icon(
                    services.speech.speaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                    color: c.onHero,
                  ),
                ),
                IconButton(
                  tooltip: S.bigText,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BigTextScreen(text: tc.displayOutput, rtl: tc.displayIsRtl),
                    ),
                  ),
                  icon: Icon(Icons.fullscreen_rounded, color: c.onHero),
                ),
                IconButton(
                  tooltip: S.copy,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: tc.displayOutput));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(S.copied), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: Icon(Icons.copy_rounded, color: c.onHero),
                ),
                IconButton(
                  tooltip: S.share,
                  onPressed: () => SharePlus.instance.share(ShareParams(text: tc.displayOutput)),
                  icon: Icon(Icons.ios_share_rounded, color: c.onHero),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg, this.lead, this.onTap});

  final String text;
  final Color bg;
  final Color fg;
  final Widget? lead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (lead != null) ...<Widget>[lead!, const SizedBox(width: 5)],
              Text(text, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverageChip extends StatelessWidget {
  const _CoverageChip({required this.tc});

  final TranslationController tc;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    if (tc.phase == CheckPhase.checking) {
      return _Pill(
        text: S.checkingWords,
        bg: c.heroDeep,
        fg: c.onHero,
        lead: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.onHero),
        ),
      );
    }
    final check = tc.check;
    if (tc.phase != CheckPhase.done || check == null) return const SizedBox.shrink();
    if (tc.missing.isNotEmpty) {
      return _Pill(text: S.wordsToCheck(tc.missing.length), bg: c.amberBg, fg: c.amberInk);
    }
    if (check.total == 0) return const SizedBox.shrink();
    if (check.checked < check.total) {
      return _Pill(text: S.partlyChecked(check.checked, check.total), bg: c.soft, fg: c.heading);
    }
    return _Pill(
      text: S.allCovered(check.total),
      bg: c.greenBg,
      fg: c.greenInk,
      lead: Icon(Icons.check_circle_rounded, size: 15, color: c.greenInk),
    );
  }
}

class _MissingWords extends StatelessWidget {
  const _MissingWords({required this.tc});

  final TranslationController tc;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(S.tapWordHint, style: TextStyle(color: c.secondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final w in tc.missing)
              ActionChip(
                label: Text(w.word),
                backgroundColor: c.amberBg,
                side: BorderSide(color: c.amber),
                labelStyle: TextStyle(color: c.amberInk, fontWeight: FontWeight.w600),
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
  const _Recent({required this.tc, required this.services});

  final TranslationController tc;
  final Services services;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(S.recent, style: TextStyle(fontSize: 13, color: c.secondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final h in services.history.recent())
              ActionChip(
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(h.source, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                backgroundColor: c.card,
                side: BorderSide(color: c.border),
                onPressed: () {
                  if (!tc.openItem(h)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.downloadFirst(h.from == 'en' ? h.to : h.from))),
                    );
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}
