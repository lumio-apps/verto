import 'package:shared_preferences/shared_preferences.dart';

/// Small user settings. Lives in app data, so it survives app and pack updates.
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsStore> open() async => SettingsStore(await SharedPreferences.getInstance());

  String? get foreign => _prefs.getString('foreign');
  Future<void> setForeign(String? code) =>
      code == null ? _prefs.remove('foreign') : _prefs.setString('foreign', code);

  bool get toEnglish => _prefs.getBool('toEnglish') ?? false;
  Future<void> setToEnglish(bool v) => _prefs.setBool('toEnglish', v);

  List<String> get history => _prefs.getStringList('history') ?? <String>[];
  Future<void> setHistory(List<String> v) => _prefs.setStringList('history', v);

  String? get cachedManifest => _prefs.getString('manifest');
  Future<void> setCachedManifest(String v) => _prefs.setString('manifest', v);
}
