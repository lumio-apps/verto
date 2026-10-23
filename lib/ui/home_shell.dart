import 'package:flutter/material.dart';

import '../strings.dart';
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
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: <Widget>[
              TranslateScreen(onOpenLanguages: () => setState(() => _index = 1)),
              const LanguagesScreen(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.translate_rounded), label: S.navTranslate),
            NavigationDestination(icon: Icon(Icons.language_rounded), label: S.navLanguages),
          ],
        ),
      ),
    );
  }
}
