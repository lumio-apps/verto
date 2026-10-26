import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'downloader.dart';

/// A published app version on GitHub.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.apkSize,
    this.apkSha256,
  });

  final String version;
  final String notes;
  final String apkUrl;
  final int apkSize;
  final String? apkSha256;
}

/// Compare "1.2.3" style versions. Ignores a leading "v", "+build" and "-pre".
int compareVersions(String a, String b) {
  List<int> parse(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    s = s.split('+').first.split('-').first;
    return s.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  final x = parse(a);
  final y = parse(b);
  final n = x.length > y.length ? x.length : y.length;
  for (var i = 0; i < n; i++) {
    final xi = i < x.length ? x[i] : 0;
    final yi = i < y.length ? y[i] : 0;
    if (xi != yi) return xi < yi ? -1 : 1;
  }
  return 0;
}

/// Checks GitHub for a newer Verto and installs it from inside the app.
/// Installing an update keeps all app data (settings, history, language packs).
class UpdateService extends ChangeNotifier {
  UpdateService({required this.currentVersion});

  final String currentVersion;

  bool checking = false;
  bool checkedOnce = false;
  String? error;
  AppRelease? latest;
  double? downloadProgress;
  CancelToken? _cancel;

  bool get updateAvailable => latest != null && compareVersions(latest!.version, currentVersion) > 0;
  bool get downloading => downloadProgress != null;

  static Future<UpdateService> create() async {
    final info = await PackageInfo.fromPlatform();
    return UpdateService(currentVersion: info.version);
  }

  Future<void> check() async {
    if (checking) return;
    checking = true;
    error = null;
    notifyListeners();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(Config.latestReleaseApi));
      req.headers.set(HttpHeaders.userAgentHeader, 'Verto');
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 30));
      if (res.statusCode == 404) {
        await res.drain<void>();
        latest = null; // no release yet
      } else if (res.statusCode != 200) {
        await res.drain<void>();
        throw HttpException('GitHub answered ${res.statusCode}');
      } else {
        final body = await res.transform(utf8.decoder).join();
        latest = _parse(jsonDecode(body) as Map<String, dynamic>);
      }
      checkedOnce = true;
    } catch (_) {
      error = 'Could not check for updates. Check your internet connection.';
    } finally {
      client.close(force: true);
      checking = false;
      notifyListeners();
    }
  }

  AppRelease? _parse(Map<String, dynamic> j) {
    final tag = (j['tag_name'] as String?) ?? '';
    for (final a in (j['assets'] as List<dynamic>? ?? <dynamic>[])) {
      final m = a as Map<String, dynamic>;
      final name = (m['name'] as String?) ?? '';
      if (!name.toLowerCase().endsWith('.apk')) continue;
      final digest = m['digest'] as String?;
      return AppRelease(
        version: tag.startsWith('v') ? tag.substring(1) : tag,
        notes: ((j['body'] as String?) ?? '').trim(),
        apkUrl: m['browser_download_url'] as String,
        apkSize: (m['size'] as num).toInt(),
        apkSha256: (digest != null && digest.startsWith('sha256:')) ? digest.substring(7) : null,
      );
    }
    return null;
  }

  /// Download the new APK and hand it to Android's installer.
  Future<void> install() async {
    final release = latest;
    if (release == null || downloading) return;
    error = null;
    downloadProgress = 0;
    final cancel = CancelToken();
    _cancel = cancel;
    notifyListeners();
    try {
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final file = File('${dir.path}/verto-${release.version}.apk');
      var last = 0.0;
      await downloadFile(
        url: Uri.parse(release.apkUrl),
        dest: file,
        expectedSize: release.apkSize,
        sha256Hex: release.apkSha256,
        cancel: cancel,
        onProgress: (b) {
          final p = release.apkSize == 0 ? 0.0 : b / release.apkSize;
          if (p - last >= 0.01 || p >= 1) {
            last = p;
            downloadProgress = p;
            notifyListeners();
          }
        },
      );
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        error = 'Android did not open the installer. Allow Verto to install apps in '
            'Settings, then tap Update again.';
      }
    } on DownloadCancelled {
      // Stopped by the user.
    } catch (_) {
      error = 'Update download failed. Please try again.';
    } finally {
      downloadProgress = null;
      _cancel = null;
      notifyListeners();
    }
  }

  void cancelInstall() => _cancel?.cancel();

  Future<List<File>> _downloadedFiles() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null || !await dir.exists()) return <File>[];
    final out = <File>[];
    await for (final e in dir.list()) {
      final name = e.uri.pathSegments.last;
      if (e is File && name.startsWith('verto-') && (name.endsWith('.apk') || name.endsWith('.apk.part'))) {
        out.add(e);
      }
    }
    return out;
  }

  /// Space used by update files that were downloaded earlier.
  Future<int> downloadsSize() async {
    var sum = 0;
    for (final f in await _downloadedFiles()) {
      sum += await f.length();
    }
    return sum;
  }

  Future<void> clearDownloads() async {
    for (final f in await _downloadedFiles()) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}
