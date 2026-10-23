import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'core/engine.dart';
import 'services.dart';
import 'strings.dart';
import 'theme.dart';
import 'ui/home_shell.dart';
import 'ui/logo.dart';

class VertoApp extends StatefulWidget {
  const VertoApp({super.key});

  @override
  State<VertoApp> createState() => _VertoAppState();
}

class _VertoAppState extends State<VertoApp> {
  late final Future<Services> _services = Services.create();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Services>(
      future: _services,
      builder: (context, snap) {
        final services = snap.data;
        if (services == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            home: Scaffold(
              body: Center(
                child: snap.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Verto could not start.\n${snap.error}', textAlign: TextAlign.center),
                      )
                    : const VertoLogo(size: 84),
              ),
            ),
          );
        }
        return AppScope(
          services: services,
          child: MaterialApp(
            title: S.appName,
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            builder: (context, child) => Stack(
              fit: StackFit.expand,
              children: <Widget>[
                child ?? const SizedBox.shrink(),
                // The translation engine lives in this 1 px hidden web view.
                Positioned(
                  left: 0,
                  top: 0,
                  width: 1,
                  height: 1,
                  child: IgnorePointer(child: _EngineHost(engine: services.engine)),
                ),
              ],
            ),
            home: const HomeShell(),
          ),
        );
      },
    );
  }
}

class _EngineHost extends StatelessWidget {
  const _EngineHost({required this.engine});

  final Engine engine;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final c = engine.controller;
        return c == null ? const SizedBox.shrink() : WebViewWidget(controller: c);
      },
    );
  }
}
