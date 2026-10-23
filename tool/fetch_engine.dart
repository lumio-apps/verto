// Downloads the Bergamot translator (WebAssembly) from npm into assets/engine.
// Run from the project root:  dart run tool/fetch_engine.dart
// The files are MPL-2.0 and are not committed to git (see assets/engine/.gitignore).
import 'dart:io';

const String _version = '0.4.9';

Never _fail(String message) {
  stderr.writeln('ERROR: $message');
  exit(1);
}

Future<void> main() async {
  final tmp = await Directory.systemTemp.createTemp('verto_engine');
  try {
    final url = Uri.parse(
      'https://registry.npmjs.org/@browsermt/bergamot-translator/-/bergamot-translator-$_version.tgz',
    );
    stdout.writeln('Downloading $url');
    final client = HttpClient();
    final res = await (await client.getUrl(url)).close();
    if (res.statusCode != 200) _fail('npm answered ${res.statusCode}');
    final tgz = File('${tmp.path}/pkg.tgz');
    await res.pipe(tgz.openWrite());
    client.close();

    final r = await Process.run('tar', <String>['-xzf', 'pkg.tgz'], workingDirectory: tmp.path);
    if (r.exitCode != 0) _fail('tar failed: ${r.stderr}');

    final pkg = Directory('${tmp.path}/package');
    final translator = File('${pkg.path}/translator.js');
    final workerDir = Directory('${pkg.path}/worker');
    if (!await translator.exists() || !await workerDir.exists()) {
      stderr.writeln('Unexpected package layout. Found:');
      await for (final e in pkg.list(recursive: true)) {
        stderr.writeln('  ${e.path.substring(pkg.path.length)}');
      }
      _fail('translator.js or worker/ is missing.');
    }

    final out = Directory('assets/engine');
    await Directory('${out.path}/worker').create(recursive: true);
    await translator.copy('${out.path}/translator.js');
    var count = 1;
    await for (final e in workerDir.list()) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.last;
      if (name.endsWith('.js') || name.endsWith('.wasm')) {
        await e.copy('${out.path}/worker/$name');
        count++;
      }
    }
    for (final need in <String>[
      'translator.js',
      'worker/translator-worker.js',
      'worker/bergamot-translator-worker.js',
      'worker/bergamot-translator-worker.wasm',
    ]) {
      if (!await File('${out.path}/$need').exists()) _fail('Missing $need after copy.');
    }
    stdout.writeln('Engine ready: $count files in ${out.path}');
  } finally {
    await tmp.delete(recursive: true);
  }
}
