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

  /// Saved translations (history and favourites) as JSON text.
  String? get itemsJson => _prefs.getString('items');
  Future<void> setItemsJson(String v) => _prefs.setString('items', v);

  bool get historyEnabled => _prefs.getBool('historyEnabled') ?? true;
  Future<void> setHistoryEnabled(bool v) => _prefs.setBool('historyEnabled', v);

  bool get clipboardOffer => _prefs.getBool('clipboardOffer') ?? true;
  Future<void> setClipboardOffer(bool v) => _prefs.setBool('clipboardOffer', v);

  String? get cachedManifest => _prefs.getString('manifest');
  Future<void> setCachedManifest(String v) => _prefs.setString('manifest', v);
}
