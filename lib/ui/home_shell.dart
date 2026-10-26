import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../strings.dart';
import '../theme.dart';
import 'history_screen.dart';
import 'languages_screen.dart';
import 'translate_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        systemNavigationBarColor: c.card,
        systemNavigationBarIconBrightness: icons,
      ),
      child: PopScope(
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _index = 0);
        },
        child: Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _index,
              children: <Widget>[
                TranslateScreen(onOpenLanguages: () => setState(() => _index = 2)),
                HistoryScreen(onOpenTranslate: () => setState(() => _index = 0)),
                const LanguagesScreen(),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.translate_rounded), label: S.navTranslate),
              NavigationDestination(icon: Icon(Icons.history_rounded), label: S.navHistory),
              NavigationDestination(icon: Icon(Icons.language_rounded), label: S.navLanguages),
            ],
          ),
        ),
      ),
    );
  }
}
