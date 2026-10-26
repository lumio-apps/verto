import 'package:flutter/widgets.dart';

import 'core/engine.dart';
import 'core/engine_server.dart';
import 'core/history.dart';
import 'core/pack_controller.dart';
import 'core/pack_store.dart';
import 'core/settings_store.dart';
import 'core/speech.dart';
import 'core/translation_controller.dart';
import 'core/update_service.dart';

/// Everything the screens need, created once at startup.
class Services {
  Services._({
    required this.settings,
    required this.engine,
    required this.packs,
    required this.updates,
    required this.translation,
    required this.history,
    required this.speech,
  });

  final SettingsStore settings;
  final Engine engine;
  final PackController packs;
  final UpdateService updates;
  final TranslationController translation;
  final HistoryController history;
  final Speech speech;

  static Future<Services> create() async {
    final settings = await SettingsStore.open();
    final store = await PackStore.open();
    final engine = Engine(EngineServer(store.root));
    final packs = PackController(
      store: store,
      settings: settings,
      onInstalledChanged: engine.setPacks,
    );
    final updates = await UpdateService.create();
    final history = HistoryController(settings);
    final translation = TranslationController(
      engine: engine,
      packs: packs,
      settings: settings,
      history: history,
    );
    await packs.init();
    // Start in the background; screens show progress.
    engine.start();
    return Services._(
      settings: settings,
      engine: engine,
      packs: packs,
      updates: updates,
      translation: translation,
      history: history,
      speech: Speech(),
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final Services services;

  static Services of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
