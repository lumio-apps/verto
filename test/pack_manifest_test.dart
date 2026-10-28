import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:verto/core/pack_manifest.dart';

String _manifest({String path = 'en-hi/model.bin', bool? beta}) => jsonEncode(<String, dynamic>{
      'schema': 1,
      'packs': <String, dynamic>{
        'hi': <String, dynamic>{
          'version': 3,
          'beta': ?beta,
          'files': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'en-hi.model.bin', 'path': path, 'size': 100, 'sha256': 'AB'},
            <String, dynamic>{'name': 'en-hi.lex.bin', 'path': 'en-hi/lex.bin', 'size': 50, 'sha256': 'cd'},
          ],
        },
      },
    });

void main() {
  test('parses packs and adds up sizes', () {
    final m = PackManifest.parse(_manifest());
    final hi = m.packs['hi']!;
    expect(hi.version, 3);
    expect(hi.size, 150);
    expect(hi.files.first.sha256, 'ab');
  });

  test('rejects paths that could escape the pack folder', () {
    expect(() => PackManifest.parse(_manifest(path: '../evil.bin')), throwsFormatException);
    expect(() => PackManifest.parse(_manifest(path: '/etc/passwd')), throwsFormatException);
  });

  test('reads the beta flag, which is off when missing', () {
    expect(PackManifest.parse(_manifest()).packs['hi']!.beta, isFalse);
    expect(PackManifest.parse(_manifest(beta: true)).packs['hi']!.beta, isTrue);
  });

  test('rejects an unknown schema', () {
    expect(() => PackManifest.parse('{"schema":2,"packs":{}}'), throwsFormatException);
  });
}
