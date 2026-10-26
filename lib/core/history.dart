import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'settings_store.dart';

/// One saved translation (history entry, optionally a favourite).
class SavedItem {
  const SavedItem({
    required this.id,
    required this.from,
    required this.to,
    required this.source,
    required this.target,
    required this.time,
    this.favorite = false,
  });

  final String id;
  final String from;
  final String to;
  final String source;
  final String target;
  final int time;
  final bool favorite;

  /// Same text in the same direction counts as the same entry.
  String get key => '$from>$to>$source';

  SavedItem copyWith({String? target, int? time, bool? favorite}) => SavedItem(
        id: id,
        from: from,
        to: to,
        source: source,
        target: target ?? this.target,
        time: time ?? this.time,
        favorite: favorite ?? this.favorite,
      );

  factory SavedItem.fromJson(Map<String, dynamic> j) => SavedItem(
        id: j['id'] as String,
        from: j['from'] as String,
        to: j['to'] as String,
        source: j['source'] as String,
        target: j['target'] as String,
        time: (j['time'] as num).toInt(),
        favorite: (j['favorite'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'from': from,
        'to': to,
        'source': source,
        'target': target,
        'time': time,
        'favorite': favorite,
      };
}

/// History and favourites. Stored only on this phone.
class HistoryController extends ChangeNotifier {
  HistoryController(this._settings) {
    _items = _load();
  }

  static const int maxHistory = 200;

  final SettingsStore _settings;
  List<SavedItem> _items = <SavedItem>[];
  int _counter = 0;

  /// Newest first.
  List<SavedItem> get items => List<SavedItem>.unmodifiable(_items);
  bool get enabled => _settings.historyEnabled;

  List<SavedItem> _load() {
    final raw = _settings.itemsJson;
    if (raw == null) return <SavedItem>[];
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => SavedItem.fromJson(e as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.time.compareTo(a.time));
      return list;
    } catch (_) {
      return <SavedItem>[];
    }
  }

  void _save() {
    unawaited(_settings.setItemsJson(jsonEncode(_items.map((e) => e.toJson()).toList())));
    notifyListeners();
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  int _indexOfKey(String key) => _items.indexWhere((e) => e.key == key);

  /// Record a finished translation (does nothing when history is switched off).
  void add({required String from, required String to, required String source, required String target}) {
    if (!enabled) return;
    _upsert(from: from, to: to, source: source, target: target, favorite: null);
  }

  void _upsert({
    required String from,
    required String to,
    required String source,
    required String target,
    required bool? favorite,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = '$from>$to>$source';
    final i = _indexOfKey(key);
    if (i >= 0) {
      final old = _items.removeAt(i);
      _items.insert(0, old.copyWith(target: target, time: now, favorite: favorite ?? old.favorite));
    } else {
      _items.insert(
        0,
        SavedItem(
          id: _newId(),
          from: from,
          to: to,
          source: source,
          target: target,
          time: now,
          favorite: favorite ?? false,
        ),
      );
    }
    _trim();
    _save();
  }

  void _trim() {
    var plain = 0;
    _items.removeWhere((e) {
      if (e.favorite) return false;
      plain++;
      return plain > maxHistory;
    });
  }

  bool isFavorite(String from, String to, String source) {
    final i = _indexOfKey('$from>$to>$source');
    return i >= 0 && _items[i].favorite;
  }

  /// Star or un-star a translation. Starring works even when history is off.
  void toggleFavorite({
    required String from,
    required String to,
    required String source,
    required String target,
  }) {
    final key = '$from>$to>$source';
    final i = _indexOfKey(key);
    if (i >= 0) {
      final item = _items[i];
      if (item.favorite && !enabled) {
        _items.removeAt(i);
      } else {
        _items[i] = item.copyWith(favorite: !item.favorite, target: target);
      }
      _save();
    } else {
      _upsert(from: from, to: to, source: source, target: target, favorite: true);
    }
  }

  void toggleFavoriteById(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(favorite: !_items[i].favorite);
    _save();
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    _save();
  }

  /// Delete everything except favourites.
  void clearHistory() {
    _items.removeWhere((e) => !e.favorite);
    _save();
  }

  void clearAll() {
    _items.clear();
    _save();
  }

  Future<void> setEnabled(bool value) async {
    await _settings.setHistoryEnabled(value);
    notifyListeners();
  }

  /// Latest non-empty entries for the "Recent" row.
  List<SavedItem> recent([int n = 6]) => _items.take(n).toList();

  List<SavedItem> search(String query, {bool favoritesOnly = false}) {
    final q = query.trim().toLowerCase();
    return _items.where((e) {
      if (favoritesOnly && !e.favorite) return false;
      if (q.isEmpty) return true;
      return e.source.toLowerCase().contains(q) || e.target.toLowerCase().contains(q);
    }).toList();
  }
}
