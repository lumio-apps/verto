import 'package:flutter/material.dart';

import '../core/languages.dart';
import '../core/pack_controller.dart';
import '../core/update_service.dart';
import '../services.dart';
import '../strings.dart';
import '../theme.dart';

class LanguagesScreen extends StatelessWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final packs = services.packs;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[packs, services.updates]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            const Text(S.languagesTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kDeep)),
            const SizedBox(height: 14),
            _AppUpdateCard(service: services.updates),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(S.languagesIntro, style: TextStyle(color: kSecondary, height: 1.35)),
                ),
                IconButton(
                  tooltip: S.refreshList,
                  onPressed: packs.loadingManifest ? null : packs.refreshManifest,
                  icon: packs.loadingManifest
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, color: kPrimary),
                ),
              ],
            ),
            if (packs.manifestError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(packs.manifestError!, style: const TextStyle(color: kAmberInk, fontSize: 13)),
              ),
            const SizedBox(height: 4),
            const _EnglishTile(),
            for (final l in packs.languages) _LanguageTile(language: l, packs: packs),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: S.appName,
                  applicationVersion: services.updates.currentVersion,
                ),
                child: const Text(S.about),
              ),
            ),
          ],
        );
      },
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kBorder),
    );

class _EnglishTile extends StatelessWidget {
  const _EnglishTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('English', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(S.englishBuiltIn, style: TextStyle(color: kSecondary, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: kPrimary),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.language, required this.packs});

  final Language language;
  final PackController packs;

  @override
  Widget build(BuildContext context) {
    final code = language.code;
    final info = packs.info(code);
    final installed = packs.installed[code];
    final busy = packs.isBusy(code);
    final hasUpdate = packs.hasUpdate(code);
    final error = packs.errors[code];

    String subtitle;
    if (busy) {
      subtitle = 'Downloading ${(packs.progress[code]! * 100).toStringAsFixed(0)}%';
    } else if (installed != null) {
      subtitle = hasUpdate
          ? '${S.updateAvailable} · ${formatBytes(info!.size)}'
          : '${S.installed} · ${formatBytes(installed.size)}';
    } else if (info != null) {
      subtitle = '${language.native} · ${formatBytes(info.size)}';
    } else {
      subtitle = language.native;
    }

    Widget trailing;
    if (busy) {
      trailing = TextButton(onPressed: () => packs.cancel(code), child: const Text(S.cancel));
    } else if (installed != null && hasUpdate) {
      trailing = FilledButton.tonal(onPressed: () => packs.install(code), child: const Text(S.update));
    } else if (installed != null) {
      trailing = IconButton(
        tooltip: S.remove,
        icon: const Icon(Icons.delete_outline_rounded, color: kSecondary),
        onPressed: () => _confirmRemove(context),
      );
    } else if (info != null) {
      trailing = FilledButton(onPressed: () => packs.install(code), child: const Text(S.get));
    } else {
      trailing = const _Tag(S.notPublished);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(language.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: kSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
          if (busy) ...<Widget>[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: packs.progress[code], minHeight: 4, borderRadius: BorderRadius.circular(4)),
          ],
          if (error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: kErrorInk, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.removeTitle(language.name)),
        content: const Text(S.removeBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(S.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text(S.remove)),
        ],
      ),
    );
    if (yes == true) await packs.remove(language.code);
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: kSoft, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: kDeep, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _AppUpdateCard extends StatelessWidget {
  const _AppUpdateCard({required this.service});

  final UpdateService service;

  @override
  Widget build(BuildContext context) {
    final release = service.latest;
    String status;
    if (service.checking) {
      status = S.checking;
    } else if (service.updateAvailable && release != null) {
      status = S.updateReady(release.version);
    } else if (service.checkedOnce && service.error == null) {
      status = S.upToDate;
    } else {
      status = 'Version ${service.currentVersion}';
    }

    Widget action;
    if (service.downloading) {
      action = TextButton(onPressed: service.cancelInstall, child: const Text(S.cancel));
    } else if (service.updateAvailable) {
      action = FilledButton(onPressed: service.install, child: const Text(S.updateNow));
    } else {
      action = OutlinedButton(
        onPressed: service.checking ? null : service.check,
        child: const Text(S.checkForUpdate),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSoft, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(S.appUpdateTitle, style: TextStyle(fontSize: 13, color: kSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kDeep)),
                    if (service.updateAvailable)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(S.updateKeepsData, style: TextStyle(fontSize: 12.5, color: kSecondary)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              action,
            ],
          ),
          if (service.downloading) ...<Widget>[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: service.downloadProgress, minHeight: 4, borderRadius: BorderRadius.circular(4)),
          ],
          if (service.error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(service.error!, style: const TextStyle(color: kErrorInk, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
