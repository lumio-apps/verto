import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'engine_server.dart';
import 'pack_store.dart';

enum EngineStatus { starting, ready, failed }

class EngineException implements Exception {
  const EngineException(this.message);
  final String message;
  @override
  String toString() => message;
}

class MissingWord {
  const MissingWord({required this.word, required this.gloss});
  final String word;
  final String gloss;
}

/// Result of the word safety net.
class CheckResult {
  const CheckResult({
    required this.translated,
    required this.total,
    required this.checked,
    required this.missing,
  });

  final String translated;

  /// Meaningful words found in the source text.
  final int total;

  /// How many of them were actually verified.
  final int checked;
  final List<MissingWord> missing;
}

/// The translation engine (Bergamot, WebAssembly) running in a hidden WebView.
class Engine extends ChangeNotifier {
  Engine(this._server);

  final EngineServer _server;

  WebViewController? controller;
  EngineStatus status = EngineStatus.starting;
  String? error;

  Completer<bool> _ready = Completer<bool>();
  final Map<int, Completer<dynamic>> _pending = <int, Completer<dynamic>>{};
  int _nextId = 1;
  Map<String, InstalledPack> _packs = <String, InstalledPack>{};

  Future<void> start() async {
    try {
      await _server.start();
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel('Verto', onMessageReceived: (m) => _onMessage(m.message));
      controller = c;
      notifyListeners();
      await c.loadRequest(_server.indexUri);
      unawaited(
        _ready.future.timeout(const Duration(seconds: 25), onTimeout: () {
          _fail('The translation engine did not start in time.');
          return false;
        }),
      );
    } catch (e) {
      _fail('Could not start the translation engine: $e');
    }
  }

  Future<void> retry() async {
    status = EngineStatus.starting;
    error = null;
    _ready = Completer<bool>();
    notifyListeners();
    final c = controller;
    if (c == null) {
      await start();
      return;
    }
    await c.loadRequest(_server.indexUri);
    unawaited(
      _ready.future.timeout(const Duration(seconds: 25), onTimeout: () {
        _fail('The translation engine did not start in time.');
        return false;
      }),
    );
  }

  void _fail(String message) {
    if (status == EngineStatus.ready) return;
    status = EngineStatus.failed;
    error = message;
    if (!_ready.isCompleted) _ready.complete(false);
    notifyListeners();
  }

  void _onMessage(String raw) {
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (m['t']) {
      case 'ready':
        status = EngineStatus.ready;
        error = null;
        if (!_ready.isCompleted) _ready.complete(true);
        notifyListeners();
        unawaited(_sendPacks());
      case 'fatal':
        _fail(m['error']?.toString() ?? 'Unknown engine error');
      case 'reply':
        final c = _pending.remove((m['id'] as num).toInt());
        if (c == null) return;
        if (m['ok'] == true) {
          c.complete(m['result']);
        } else {
          c.completeError(EngineException(m['error']?.toString() ?? 'Engine error'));
        }
    }
  }

  Future<void> _sendPacks() async {
    final map = <String, dynamic>{
      for (final p in _packs.values) p.code: <String, dynamic>{'files': p.files},
    };
    try {
      await _call('setPacks', <String, dynamic>{'packs': map});
    } catch (_) {}
  }

  /// Tell the engine which languages are installed.
  Future<void> setPacks(Map<String, InstalledPack> packs) async {
    _packs = packs;
    if (status == EngineStatus.ready) await _sendPacks();
  }

  Future<dynamic> _call(String method, Map<String, dynamic> args, {Duration? timeout}) async {
    final ok = await _ready.future;
    if (!ok) throw EngineException(error ?? 'The translation engine is not running.');
    final c = controller;
    if (c == null) throw const EngineException('The translation engine is not running.');
    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    await c.runJavaScript(
      'vertoCall($id, ${jsonEncode(method)}, ${jsonEncode(jsonEncode(args))})',
    );
    return completer.future.timeout(timeout ?? const Duration(seconds: 90), onTimeout: () {
      _pending.remove(id);
      throw const EngineException('Translation took too long.');
    });
  }

  Future<String> translate({required String from, required String to, required String text}) async {
    final r = await _call('translate', <String, dynamic>{'from': from, 'to': to, 'text': text})
        as Map<String, dynamic>;
    return r['text'] as String;
  }

  /// Roman ("Hinglish") spelling of Hindi text. Null when the language is not supported.
  Future<String?> romanize({required String text, required String lang}) async {
    final r = await _call('romanize', <String, dynamic>{'text': text, 'lang': lang})
        as Map<String, dynamic>;
    return r['text'] as String?;
  }

  /// Verify the translation word by word. Returns null when a newer check replaced this one.
  Future<CheckResult?> check({required String from, required String to, required String text}) async {
    final r = await _call(
      'check',
      <String, dynamic>{'from': from, 'to': to, 'text': text},
      timeout: const Duration(seconds: 180),
    ) as Map<String, dynamic>;
    if (r['cancelled'] == true) return null;
    return CheckResult(
      translated: r['translated'] as String,
      total: (r['total'] as num).toInt(),
      checked: (r['checked'] as num).toInt(),
      missing: (r['missing'] as List<dynamic>)
          .map((e) => MissingWord(
                word: (e as Map<String, dynamic>)['word'] as String,
                gloss: e['gloss'] as String,
              ))
          .toList(),
    );
  }
}
