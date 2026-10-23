import 'dart:io';

import 'package:crypto/crypto.dart';

class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// Lets the UI stop a running download.
class CancelToken {
  bool cancelled = false;
  HttpClient? _client;

  void cancel() {
    cancelled = true;
    _client?.close(force: true);
  }
}

/// Download [url] into [dest]. Resumes a previous partial download when the
/// server allows it, and verifies size and SHA-256 before the file appears at
/// [dest]. [onProgress] receives the bytes of this file received so far.
Future<void> downloadFile({
  required Uri url,
  required File dest,
  required int expectedSize,
  String? sha256Hex,
  required CancelToken cancel,
  required void Function(int bytes) onProgress,
}) async {
  await dest.parent.create(recursive: true);

  Future<bool> verify(File f) async {
    if (await f.length() != expectedSize) return false;
    if (sha256Hex == null) return true;
    final digest = await sha256.bind(f.openRead()).first;
    return digest.toString() == sha256Hex.toLowerCase();
  }

  if (await dest.exists()) {
    if (await verify(dest)) {
      onProgress(expectedSize);
      return;
    }
    await dest.delete();
  }

  final part = File('${dest.path}.part');
  var have = await part.exists() ? await part.length() : 0;
  if (have > expectedSize) {
    await part.delete();
    have = 0;
  }

  if (have < expectedSize) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    cancel._client = client;
    IOSink? sink;
    try {
      final req = await client.getUrl(url);
      req.headers.set(HttpHeaders.userAgentHeader, 'Verto');
      if (have > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      final res = await req.close();
      if (res.statusCode == 200) {
        have = 0; // server ignored the range: start again
      } else if (res.statusCode != 206) {
        await res.drain<void>();
        throw HttpException('Server answered ${res.statusCode}', uri: url);
      }
      sink = part.openWrite(mode: have > 0 ? FileMode.append : FileMode.write);
      var received = have;
      onProgress(received);
      await for (final chunk in res) {
        if (cancel.cancelled) throw const DownloadCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress(received);
      }
      await sink.flush();
      await sink.close();
      sink = null;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      if (cancel.cancelled) throw const DownloadCancelled();
      rethrow;
    } finally {
      client.close(force: true);
      cancel._client = null;
    }
  }

  if (!await verify(part)) {
    await part.delete();
    throw const FormatException('Downloaded file is damaged. Please try again.');
  }
  await part.rename(dest.path);
}
