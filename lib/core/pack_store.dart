import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'pack_manifest.dart';

/// A pack that is fully downloaded and ready to use.
class InstalledPack {
  const InstalledPack({
    required this.code,
    required this.version,
    required this.size,
    required this.files,
  });

  final String code;
  final int version;
  final int size;

  /// Paths inside the pack folder, e.g. "hi-en/model.bin".
  final List<String> files;

  factory InstalledPack.fromJson(String code, Map<String, dynamic> j) => InstalledPack(
        code: code,
        version: (j['version'] as num).toInt(),
        size: (j['size'] as num).toInt(),
        files: (j['files'] as List<dynamic>).cast<String>(),
      );

  factory InstalledPack.fromInfo(PackInfo info) => InstalledPack(
        code: info.code,
        version: info.version,
        size: info.size,
        files: info.files.map((f) => f.path).toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'size': size,
        'files': files,
      };
}

/// Language packs on disk. Only the packs folder is touched here, so app data
/// (history, settings) is never affected by installing, updating or removing.
class PackStore {
  PackStore(this.root);

  final Directory root;

  static Future<PackStore> open() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/packs');
    await dir.create(recursive: true);
    final store = PackStore(dir);
    await store.recover();
    return store;
  }

  Directory dirFor(String code) => Directory('${root.path}/$code');
  Directory stagingFor(String code) => Directory('${root.path}/$code.new');
  Directory _oldFor(String code) => Directory('${root.path}/$code.old');

  /// Finish or undo a swap that was interrupted (app killed mid-update).
  Future<void> recover() async {
    final entries = await root.list().toList();
    for (final e in entries) {
      if (e is! Directory) continue;
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (name.endsWith('.old')) {
        final code = name.substring(0, name.length - 4);
        if (!await dirFor(code).exists()) {
          await e.rename(dirFor(code).path);
        } else {
          await e.delete(recursive: true);
        }
      }
    }
  }

  Future<Map<String, InstalledPack>> readAll() async {
    final out = <String, InstalledPack>{};
    await for (final e in root.list()) {
      if (e is! Directory) continue;
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (name.contains('.')) continue;
      final meta = File('${e.path}/pack.json');
      if (!await meta.exists()) continue;
      try {
        final j = jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
        out[name] = InstalledPack.fromJson(name, j);
      } catch (_) {
        // Broken pack.json: treat as not installed.
      }
    }
    return out;
  }

  Future<void> writeMeta(Directory dir, InstalledPack pack) async {
    await File('${dir.path}/pack.json').writeAsString(jsonEncode(pack.toJson()));
  }

  /// Replace the live pack with the finished staging folder.
  Future<void> commit(String code) async {
    final live = dirFor(code);
    final old = _oldFor(code);
    if (await old.exists()) await old.delete(recursive: true);
    if (await live.exists()) await live.rename(old.path);
    await stagingFor(code).rename(live.path);
    if (await old.exists()) await old.delete(recursive: true);
  }

  Future<void> remove(String code) async {
    for (final d in <Directory>[dirFor(code), stagingFor(code), _oldFor(code)]) {
      if (await d.exists()) await d.delete(recursive: true);
    }
  }
}
