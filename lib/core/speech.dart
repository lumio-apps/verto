import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads a translation aloud with Android's own text-to-speech.
/// Works offline when the phone has an offline voice for that language.
class Speech extends ChangeNotifier {
  Speech() {
    _tts.setCompletionHandler(_done);
    _tts.setCancelHandler(_done);
    _tts.setErrorHandler((_) => _done());
  }

  final FlutterTts _tts = FlutterTts();
  bool speaking = false;

  static const Map<String, String> _locales = <String, String>{
    'en': 'en-US',
    'hi': 'hi-IN',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'ru': 'ru-RU',
    'ja': 'ja-JP',
    'ar': 'ar',
    'fa': 'fa-IR',
    'zh-Hans': 'zh-CN',
    'zh-Hant': 'zh-TW',
    'nb': 'nb-NO',
    'pt': 'pt-PT',
    'it': 'it-IT',
    'ko': 'ko-KR',
    'tr': 'tr-TR',
    'uk': 'uk-UA',
    'pl': 'pl-PL',
    'nl': 'nl-NL',
  };

  void _done() {
    speaking = false;
    notifyListeners();
  }

  /// Returns null when speaking started, or a short message when it could not.
  Future<String?> speak(String text, String langCode, String langName) async {
    final locale = _locales[langCode] ?? langCode;
    try {
      final ok = await _tts.isLanguageAvailable(locale);
      if (ok != true && ok != 1) {
        return 'No $langName voice on this phone. Install one in Android Settings, Text-to-speech.';
      }
      await _tts.setLanguage(locale);
      speaking = true;
      notifyListeners();
      await _tts.speak(text);
      return null;
    } catch (_) {
      speaking = false;
      notifyListeners();
      return 'Could not read this aloud.';
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _done();
  }
}
