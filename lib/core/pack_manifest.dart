import 'dart:convert';

/// One file inside a language pack.
class PackFile {
  const PackFile({
    required this.name,
    required this.path,
    required this.size,
    required this.sha256,
  });

  /// Asset name on the GitHub release (flat).
  final String name;

  /// Path inside the pack folder, e.g. "en-hi/model.bin".
  final String path;
  final int size;
  final String sha256;

  factory PackFile.fromJson(Map<String, dynamic> j) {
    final name = j['name'] as String;
    final path = j['path'] as String;
    if (name.contains('/') || name.contains('\\') || name.isEmpty) {
      throw FormatException('Bad file name in manifest: $name');
    }
    final parts = path.split('/');
    if (path.startsWith('/') ||
        path.contains('\\') ||
        parts.any((p) => p.isEmpty || p == '..' || p == '.')) {
      throw FormatException('Bad path in manifest: $path');
    }
    return PackFile(
      name: name,
      path: path,
      size: (j['size'] as num).toInt(),
      sha256: (j['sha256'] as String).toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'path': path,
        'size': size,
        'sha256': sha256,
      };
}

/// A downloadable language (both directions with English).
class PackInfo {
  const PackInfo({required this.code, required this.version, required this.files});

  final String code;
  final int version;
  final List<PackFile> files;

  int get size => files.fold<int>(0, (sum, f) => sum + f.size);

  factory PackInfo.fromJson(String code, Map<String, dynamic> j) => PackInfo(
        code: code,
        version: (j['version'] as num).toInt(),
        files: (j['files'] as List<dynamic>)
            .map((e) => PackFile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'files': files.map((f) => f.toJson()).toList(),
      };
}

/// The list of packs published on the GitHub "packs" release.
class PackManifest {
  const PackManifest({required this.packs});

  final Map<String, PackInfo> packs;

  static PackManifest parse(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    if ((j['schema'] as num?)?.toInt() != 1) {
      throw const FormatException('Unsupported manifest schema');
    }
    final raw = j['packs'] as Map<String, dynamic>;
    return PackManifest(
      packs: <String, PackInfo>{
        for (final e in raw.entries) e.key: PackInfo.fromJson(e.key, e.value as Map<String, dynamic>),
      },
    );
  }
}
