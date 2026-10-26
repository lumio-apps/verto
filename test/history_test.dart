import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verto/core/history.dart';
import 'package:verto/core/settings_store.dart';

Future<HistoryController> _make([Map<String, Object> initial = const <String, Object>{}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return HistoryController(await SettingsStore.open());
}

void main() {
  test('adds, de-duplicates and puts the newest first', () async {
    final h = await _make();
    h.add(from: 'en', to: 'hi', source: 'hello', target: 'नमस्ते');
    h.add(from: 'en', to: 'hi', source: 'thanks', target: 'धन्यवाद');
    h.add(from: 'en', to: 'hi', source: 'hello', target: 'हैलो');
    expect(h.items.length, 2);
    expect(h.items.first.source, 'hello');
    expect(h.items.first.target, 'हैलो');
  });

  test('favourites survive "clear history"', () async {
    final h = await _make();
    h.add(from: 'en', to: 'fr', source: 'a', target: 'a1');
    h.add(from: 'en', to: 'fr', source: 'b', target: 'b1');
    h.toggleFavorite(from: 'en', to: 'fr', source: 'a', target: 'a1');
    expect(h.isFavorite('en', 'fr', 'a'), isTrue);
    h.clearHistory();
    expect(h.items.map((e) => e.source), <String>['a']);
    h.clearAll();
    expect(h.items, isEmpty);
  });

  test('search and favourites filter', () async {
    final h = await _make();
    h.add(from: 'en', to: 'es', source: 'Good morning', target: 'Buenos días');
    h.add(from: 'en', to: 'es', source: 'Thank you', target: 'Gracias');
    h.toggleFavorite(from: 'en', to: 'es', source: 'Thank you', target: 'Gracias');
    expect(h.search('morning').length, 1);
    expect(h.search('gracias').length, 1);
    expect(h.search('', favoritesOnly: true).single.source, 'Thank you');
  });

  test('history off: nothing is recorded, but starring still works', () async {
    final h = await _make(<String, Object>{'historyEnabled': false});
    h.add(from: 'en', to: 'de', source: 'x', target: 'y');
    expect(h.items, isEmpty);
    h.toggleFavorite(from: 'en', to: 'de', source: 'x', target: 'y');
    expect(h.items.single.favorite, isTrue);
    h.toggleFavorite(from: 'en', to: 'de', source: 'x', target: 'y');
    expect(h.items, isEmpty);
  });

  test('data is stored and loaded again', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = await SettingsStore.open();
    HistoryController(settings).add(from: 'en', to: 'ru', source: 'hi', target: 'привет');
    final again = HistoryController(settings);
    expect(again.items.single.target, 'привет');
  });
}
