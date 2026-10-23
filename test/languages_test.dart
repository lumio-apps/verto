import 'package:flutter_test/flutter_test.dart';
import 'package:verto/core/languages.dart';

void main() {
  test('ten languages: English plus nine others', () {
    expect(kForeignLanguages.length, 9);
    final codes = kForeignLanguages.map((l) => l.code).toSet();
    expect(codes, <String>{'hi', 'es', 'fr', 'de', 'ru', 'ja', 'ar', 'fa', 'hy'});
    expect(codes.contains('en'), isFalse);
  });

  test('Arabic and Persian are right to left, Armenian is coming soon', () {
    expect(languageByCode('ar')!.rtl, isTrue);
    expect(languageByCode('fa')!.rtl, isTrue);
    expect(languageByCode('hi')!.rtl, isFalse);
    expect(languageByCode('hy')!.comingSoon, isTrue);
  });

  test('size text', () {
    expect(formatBytes(512 * 1024), '512 KB');
    expect(formatBytes(52 * 1024 * 1024), '52 MB');
  });
}
