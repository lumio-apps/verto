import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';

/// Tiny web server on 127.0.0.1 that feeds the translation engine page:
/// the page and engine files come from the app assets, the models from the
/// packs folder. A random token in the path keeps other apps out.
class EngineServer {
  EngineServer(this.packsRoot);

  final Directory packsRoot;
  final String token = _randomToken();
  HttpServer? _server;

  Uri get indexUri => Uri.parse('http://127.0.0.1:${_server!.port}/$token/index.html');

  static String _randomToken() {
    final r = Random.secure();
    return List<String>.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> start() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(_handle);
  }

  static const Map<String, String> _types = <String, String>{
    'html': 'text/html; charset=utf-8',
    'js': 'text/javascript; charset=utf-8',
    'mjs': 'text/javascript; charset=utf-8',
    'wasm': 'application/wasm',
    'json': 'application/json',
  };

  String _typeFor(String name) {
    final dot = name.lastIndexOf('.');
    return (dot < 0 ? null : _types[name.substring(dot + 1)]) ?? 'application/octet-stream';
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final segs = req.uri.pathSegments;
      if (segs.length < 2 || segs.first != token) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      final rest = segs.sublist(1);
      if (rest.any((s) => s.isEmpty || s == '..' || s == '.' || s.contains('\\'))) {
        res.statusCode = HttpStatus.forbidden;
        return;
      }
      res.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      if (rest.first == 'packs') {
        final file = File('${packsRoot.path}/${rest.sublist(1).join('/')}');
        if (!await file.exists()) {
          res.statusCode = HttpStatus.notFound;
          return;
        }
        res.headers.contentType = ContentType.binary;
        res.contentLength = await file.length();
        await res.addStream(file.openRead());
        return;
      }
      final key = rest.first == 'engine' ? 'assets/${rest.join('/')}' : 'assets/web/${rest.join('/')}';
      final data = await rootBundle.load(key);
      res.headers.set(HttpHeaders.contentTypeHeader, _typeFor(rest.last));
      res.contentLength = data.lengthInBytes;
      res.add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } on FlutterError {
      res.statusCode = HttpStatus.notFound; // asset missing
    } catch (_) {
      try {
        res.statusCode = HttpStatus.internalServerError;
      } catch (_) {}
    } finally {
      try {
        await res.close();
      } catch (_) {}
    }
  }
}
