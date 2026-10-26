import 'dart:async';

import 'package:flutter/foundation.dart';

import 'engine.dart';
import 'history.dart';
import 'languages.dart';
import 'pack_controller.dart';
import 'settings_store.dart';

enum CheckPhase { idle, checking, done }

/// State of the Translate screen: direction, text, result and word check.
class TranslationController extends ChangeNotifier {
  TranslationController({
    required this.engine,
    required this.packs,
    required this.settings,
    required this.history,
  }) {
    toEnglish = settings.toEnglish;
    foreign = settings.foreign;
    packs.addListener(_packsChanged);
    _fixForeign();
  }

  final Engine engine;
  final PackController packs;
  final SettingsStore settings;
  final HistoryController history;

  String? foreign;
  bool toEnglish = false;
  String input = '';
  String output = '';
  bool translating = false;
  String? error;
  CheckPhase phase = CheckPhase.idle;
  CheckResult? check;
  List<MissingWord> missing = <MissingWord>[];

  /// Roman ("Hinglish") spelling of a Hindi result, and whether it is shown.
  String roman = '';
  bool showRoman = false;

  int _seq = 0;
  Timer? _debounce;

  Language? get foreignLanguage => foreign == null ? null : packs.languageFor(foreign!);
  Language get from => toEnglish ? (foreignLanguage ?? kEnglish) : kEnglish;
  Language get to => toEnglish ? kEnglish : (foreignLanguage ?? kEnglish);
  bool get hasLanguage => foreign != null;

  List<Language> get installedLanguages =>
      packs.languages.where((l) => packs.isInstalled(l.code)).toList();

  bool get romanSupported => to.code == 'hi';

  /// What the result card shows: the translation, or its Roman spelling.
  String get displayOutput => (showRoman && roman.isNotEmpty) ? roman : output;
  bool get displayIsRtl => to.rtl && !(showRoman && roman.isNotEmpty);

  bool get isFavorite => output.isNotEmpty && history.isFavorite(from.code, to.code, input.trim());

  String? _installedKey;

  void _packsChanged() {
    final key = packs.installed.values.map((p) => '${p.code}:${p.version}').join(',');
    if (key == _installedKey) return; // only download progress changed
    _installedKey = key;
    _fixForeign();
    _schedule(immediate: true);
    notifyListeners();
  }

  void _fixForeign() {
    if (!packs.loaded) return;
    if (foreign != null && packs.isInstalled(foreign!)) return;
    final list = installedLanguages;
    foreign = list.isEmpty ? null : list.first.code;
    unawaited(settings.setForeign(foreign));
  }

  void setInput(String text) {
    input = text;
    _schedule();
    notifyListeners();
  }

  void setForeign(String code) {
    foreign = code;
    unawaited(settings.setForeign(code));
    _schedule(immediate: true);
    notifyListeners();
  }

  /// Flip the direction. The current translation becomes the new input.
  void swap() {
    toEnglish = !toEnglish;
    unawaited(settings.setToEnglish(toEnglish));
    if (output.trim().isNotEmpty) input = output;
    output = '';
    _schedule(immediate: true);
    notifyListeners();
  }

  void loadText(String text) {
    input = text;
    _schedule(immediate: true);
    notifyListeners();
  }

  /// Open a saved translation. Returns false when its language is not installed.
  bool openItem(SavedItem item) {
    final code = item.from == 'en' ? item.to : item.from;
    if (!packs.isInstalled(code)) return false;
    foreign = code;
    toEnglish = item.to == 'en';
    unawaited(settings.setForeign(code));
    unawaited(settings.setToEnglish(toEnglish));
    input = item.source;
    _schedule(immediate: true);
    notifyListeners();
    return true;
  }

  void clear() {
    _debounce?.cancel();
    _seq++;
    input = '';
    output = '';
    roman = '';
    error = null;
    translating = false;
    phase = CheckPhase.idle;
    check = null;
    missing = <MissingWord>[];
    notifyListeners();
  }

  void toggleRoman() {
    showRoman = !showRoman;
    notifyListeners();
  }

  void toggleFavorite() {
    if (output.isEmpty) return;
    history.toggleFavorite(from: from.code, to: to.code, source: input.trim(), target: output);
    notifyListeners();
  }

  void _schedule({bool immediate = false}) {
    _debounce?.cancel();
    if (input.trim().isEmpty || !hasLanguage) {
      _seq++;
      output = '';
      roman = '';
      translating = false;
      phase = CheckPhase.idle;
      check = null;
      missing = <MissingWord>[];
      return;
    }
    _debounce = Timer(immediate ? Duration.zero : const Duration(milliseconds: 450), _run);
  }

  Future<void> _updateRoman(int seq) async {
    if (!romanSupported || output.isEmpty) {
      roman = '';
      return;
    }
    try {
      final r = await engine.romanize(text: output, lang: to.code);
      if (seq != _seq) return;
      roman = r ?? '';
    } catch (_) {
      roman = '';
    }
  }

  Future<void> _run() async {
    final seq = ++_seq;
    final text = input;
    final f = from.code;
    final t = to.code;
    translating = true;
    error = null;
    phase = CheckPhase.idle;
    check = null;
    missing = <MissingWord>[];
    notifyListeners();
    try {
      final out = await engine.translate(from: f, to: t, text: text);
      if (seq != _seq) return;
      output = out;
      translating = false;
      phase = CheckPhase.checking;
      await _updateRoman(seq);
      if (seq != _seq) return;
      notifyListeners();
      final result = await engine.check(from: f, to: t, text: text);
      if (seq != _seq) return;
      if (result != null) {
        check = result;
        output = result.translated;
        missing = List<MissingWord>.of(result.missing);
        phase = CheckPhase.done;
        await _updateRoman(seq);
        if (seq != _seq) return;
        history.add(from: f, to: t, source: text.trim(), target: output);
      } else {
        phase = CheckPhase.idle;
      }
    } catch (e) {
      if (seq != _seq) return;
      translating = false;
      phase = CheckPhase.idle;
      output = '';
      roman = '';
      error = e is EngineException ? e.message : 'Translation failed. Please try again.';
    }
    notifyListeners();
  }

  /// Put the word-by-word translation of a flagged word into the result.
  void addWord(MissingWord w) {
    final glue = const <String>{'ja', 'zh', 'th'}.contains(to.code.split('-').first) ? '' : ' ';
    output = output.trimRight() + glue + w.gloss;
    missing = missing.where((m) => m.word != w.word).toList();
    final seq = _seq;
    unawaited(_updateRoman(seq).then((_) => notifyListeners()));
    notifyListeners();
  }

  void keepAsIs(MissingWord w) {
    missing = missing.where((m) => m.word != w.word).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    packs.removeListener(_packsChanged);
    super.dispose();
  }
}
