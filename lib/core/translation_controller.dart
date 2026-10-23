import 'dart:async';

import 'package:flutter/foundation.dart';

import 'engine.dart';
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
  }) {
    toEnglish = settings.toEnglish;
    history = settings.history;
    foreign = settings.foreign;
    packs.addListener(_packsChanged);
    _fixForeign();
  }

  final Engine engine;
  final PackController packs;
  final SettingsStore settings;

  String? foreign;
  bool toEnglish = false;
  String input = '';
  String output = '';
  bool translating = false;
  String? error;
  CheckPhase phase = CheckPhase.idle;
  CheckResult? check;
  List<MissingWord> missing = <MissingWord>[];
  List<String> history = <String>[];

  int _seq = 0;
  Timer? _debounce;

  Language? get foreignLanguage => foreign == null ? null : languageByCode(foreign!);
  Language get from => toEnglish ? (foreignLanguage ?? kEnglish) : kEnglish;
  Language get to => toEnglish ? kEnglish : (foreignLanguage ?? kEnglish);
  bool get hasLanguage => foreign != null;

  List<Language> get installedLanguages => kForeignLanguages
      .where((l) => packs.isInstalled(l.code))
      .toList();

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

  void useHistory(String text) {
    input = text;
    _schedule(immediate: true);
    notifyListeners();
  }

  void clear() {
    _debounce?.cancel();
    _seq++;
    input = '';
    output = '';
    error = null;
    translating = false;
    phase = CheckPhase.idle;
    check = null;
    missing = <MissingWord>[];
    notifyListeners();
  }

  void _schedule({bool immediate = false}) {
    _debounce?.cancel();
    if (input.trim().isEmpty || !hasLanguage) {
      _seq++;
      output = '';
      translating = false;
      phase = CheckPhase.idle;
      check = null;
      missing = <MissingWord>[];
      return;
    }
    _debounce = Timer(immediate ? Duration.zero : const Duration(milliseconds: 450), _run);
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
      notifyListeners();
      final result = await engine.check(from: f, to: t, text: text);
      if (seq != _seq) return;
      if (result != null) {
        check = result;
        output = result.translated;
        missing = List<MissingWord>.of(result.missing);
        phase = CheckPhase.done;
        await _remember(text);
      } else {
        phase = CheckPhase.idle;
      }
    } catch (e) {
      if (seq != _seq) return;
      translating = false;
      phase = CheckPhase.idle;
      output = '';
      error = e is EngineException ? e.message : 'Translation failed. Please try again.';
    }
    notifyListeners();
  }

  /// Put the word-by-word translation of a flagged word into the result.
  void addWord(MissingWord w) {
    final glue = to.code == 'ja' ? '' : ' ';
    output = output.trimRight() + glue + w.gloss;
    missing = missing.where((m) => m.word != w.word).toList();
    notifyListeners();
  }

  void keepAsIs(MissingWord w) {
    missing = missing.where((m) => m.word != w.word).toList();
    notifyListeners();
  }

  Future<void> _remember(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    history = <String>[t, ...history.where((h) => h != t)].take(8).toList();
    await settings.setHistory(history);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    packs.removeListener(_packsChanged);
    super.dispose();
  }
}
