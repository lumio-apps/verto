import 'package:flutter_test/flutter_test.dart';
import 'package:verto/core/languages.dart';

void main() {
  test('built-in table: English plus eight languages', () {
    expect(kForeignLanguages.length, 8);
    final codes = kForeignLanguages.map((l) => l.code).toSet();
    expect(codes, <String>{'hi', 'es', 'fr', 'de', 'ru', 'ja', 'ar', 'fa'});
    expect(codes.contains('en'), isFalse);
  });

  test('Arabic and Persian are right to left', () {
    expect(languageByCode('ar')!.rtl, isTrue);
    expect(languageByCode('fa')!.rtl, isTrue);
    expect(languageByCode('hi')!.rtl, isFalse);
    expect(languageByCode('xx'), isNull);
  });

  test('size text', () {
    expect(formatBytes(512 * 1024), '512 KB');
    expect(formatBytes(52 * 1024 * 1024), '52 MB');
  });
}
