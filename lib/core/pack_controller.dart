import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'downloader.dart';
import 'languages.dart';
import 'pack_manifest.dart';
import 'pack_store.dart';
import 'settings_store.dart';

/// Knows which language packs are published, which are installed, and runs
/// downloads, updates and removals.
class PackController extends ChangeNotifier {
  PackController({
    required this.store,
    required this.settings,
    required this.onInstalledChanged,
  });

  final PackStore store;
  final SettingsStore settings;
  final Future<void> Function(Map<String, InstalledPack> installed) onInstalledChanged;

  Map<String, InstalledPack> installed = <String, InstalledPack>{};
  PackManifest? manifest;
  bool loaded = false;
  bool loadingManifest = false;
  String? manifestError;

  /// 0..1 for packs being downloaded right now.
  final Map<String, double> progress = <String, double>{};
  final Map<String, String> errors = <String, String>{};
  final Map<String, CancelToken> _cancels = <String, CancelToken>{};

  Future<void> init() async {
    installed = await store.readAll();
    loaded = true;
    final cached = settings.cachedManifest;
    if (cached != null) {
      try {
        manifest = PackManifest.parse(cached);
      } catch (_) {}
    }
    notifyListeners();
    await onInstalledChanged(installed);
    unawaited(refreshManifest());
  }

  /// Language details for a code: built-in table first, then what the pack list says.
  Language? languageFor(String code) {
    final known = languageByCode(code);
    if (known != null) return known;
    final info = manifest?.packs[code];
    final have = installed[code];
    final name = info?.name ?? have?.name;
    if (info == null && have == null) return null;
    return Language(
      code: code,
      name: name ?? code,
      native: info?.native ?? have?.native ?? '',
      rtl: info?.rtl ?? have?.rtl ?? false,
    );
  }

  /// Every language to show: the built-in ones first, then any extra the pack list offers.
  List<Language> get languages {
    final out = List<Language>.of(kForeignLanguages);
    final known = out.map((l) => l.code).toSet();
    final extra = <String>{...?manifest?.packs.keys, ...installed.keys}..removeAll(known);
    final more = <Language>[
      for (final c in extra)
        if (languageFor(c) != null) languageFor(c)!,
    ]..sort((a, b) => a.name.compareTo(b.name));
    return <Language>[...out, ...more];
  }

  bool isInstalled(String code) => installed.containsKey(code);
  bool isBusy(String code) => progress.containsKey(code);
  PackInfo? info(String code) => manifest?.packs[code];

  bool hasUpdate(String code) {
    final have = installed[code];
    final latest = manifest?.packs[code];
    return have != null && latest != null && latest.version > have.version;
  }

  int get installedBytes => installed.values.fold<int>(0, (sum, p) => sum + p.size);

  Future<void> removeAll() async {
    for (final code in installed.keys.toList()) {
      if (!isBusy(code)) await store.remove(code);
    }
    errors.clear();
    installed = await store.readAll();
    await onInstalledChanged(installed);
    notifyListeners();
  }

  bool get anyUpdate => installed.keys.any(hasUpdate);

  Future<void> refreshManifest() async {
    if (loadingManifest) return;
    loadingManifest = true;
    manifestError = null;
    notifyListeners();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(Config.packsManifestUrl));
      req.headers.set(HttpHeaders.userAgentHeader, 'Verto');
      final res = await req.close().timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        await res.drain<void>();
        throw HttpException('Server answered ${res.statusCode}');
      }
      final body = await res.transform(const Utf8Decoder()).join();
      manifest = PackManifest.parse(body);
      await settings.setCachedManifest(body);
    } catch (_) {
      manifestError = manifest == null
          ? 'Could not load the language list. Check your internet connection.'
          : 'Offline. Showing the last known list.';
    } finally {
      client.close(force: true);
      loadingManifest = false;
      notifyListeners();
    }
  }

  /// Download a language, or update it when a newer version exists.
  Future<void> install(String code) async {
    final info = manifest?.packs[code];
    if (info == null || isBusy(code)) return;
    errors.remove(code);
    progress[code] = 0;
    final cancel = CancelToken();
    _cancels[code] = cancel;
    notifyListeners();
    try {
      final staging = store.stagingFor(code);
      await staging.create(recursive: true);
      final done = <String, int>{};
      final total = info.size;
      var lastShown = 0.0;
      for (final f in info.files) {
        await downloadFile(
          url: Uri.parse('${Config.packsBaseUrl}${f.name}'),
          dest: File('${staging.path}/${f.path}'),
          expectedSize: f.size,
          sha256Hex: f.sha256,
          cancel: cancel,
          onProgress: (bytes) {
            done[f.path] = bytes;
            final sum = done.values.fold<int>(0, (a, b) => a + b);
            final p = total == 0 ? 0.0 : sum / total;
            if (p - lastShown >= 0.005 || p >= 1) {
              lastShown = p;
              progress[code] = p;
              notifyListeners();
            }
          },
        );
      }
      await store.writeMeta(staging, InstalledPack.fromInfo(info));
      await store.commit(code);
      installed = await store.readAll();
      await onInstalledChanged(installed);
    } on DownloadCancelled {
      // Partial files stay on disk so the download can resume later.
    } catch (e) {
      errors[code] = _friendly(e);
    } finally {
      progress.remove(code);
      _cancels.remove(code);
      notifyListeners();
    }
  }

  void cancel(String code) => _cancels[code]?.cancel();

  Future<void> remove(String code) async {
    if (isBusy(code)) return;
    await store.remove(code);
    errors.remove(code);
    installed = await store.readAll();
    await onInstalledChanged(installed);
    notifyListeners();
  }

  String _friendly(Object e) {
    if (e is SocketException || e is TimeoutException || e is HandshakeException) {
      return 'Download stopped. Check your internet connection and try again.';
    }
    if (e is FileSystemException) {
      return 'Could not save the file. Is there enough free space?';
    }
    if (e is FormatException) return e.message;
    return 'Download failed. Please try again.';
  }
}
