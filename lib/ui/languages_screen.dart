import 'package:flutter/material.dart';

import '../core/languages.dart';
import '../core/pack_controller.dart';
import '../core/update_service.dart';
import '../services.dart';
import '../strings.dart';
import '../theme.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});

  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  String _query = '';

  bool _matches(Language l) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return l.name.toLowerCase().contains(q) ||
        l.native.toLowerCase().contains(q) ||
        l.code.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final packs = services.packs;
    final c = context.vc;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[packs, services.updates]),
      builder: (context, _) {
        final all = packs.languages.where(_matches).toList();
        final installed = all.where((l) => packs.isInstalled(l.code) || packs.isBusy(l.code)).toList();
        final available = all.where((l) => !packs.isInstalled(l.code) && !packs.isBusy(l.code)).toList();
        final showEnglish = _query.trim().isEmpty || 'english'.contains(_query.trim().toLowerCase());
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text(S.languagesTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.heading)),
            const SizedBox(height: 14),
            _AppUpdateCard(service: services.updates),
            const SizedBox(height: 12),
            _StorageCard(packs: packs, updates: services.updates),
            const SizedBox(height: 12),
            const _SettingsCard(),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(S.languagesIntro, style: TextStyle(color: c.secondary, height: 1.35)),
                ),
                IconButton(
                  tooltip: S.refreshList,
                  onPressed: packs.loadingManifest ? null : packs.refreshManifest,
                  icon: packs.loadingManifest
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.refresh_rounded, color: c.accent),
                ),
              ],
            ),
            if (packs.manifestError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(packs.manifestError!, style: TextStyle(color: c.amber, fontSize: 13)),
              ),
            const SizedBox(height: 4),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: S.searchLanguages,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: c.soft,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            if (showEnglish || installed.isNotEmpty) const _Section(S.sectionInstalled),
            if (showEnglish) const _EnglishTile(),
            for (final l in installed) _LanguageTile(language: l, packs: packs),
            if (available.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              const _Section(S.sectionAvailable),
              for (final l in available) _LanguageTile(language: l, packs: packs),
            ],
            if (!showEnglish && all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text(S.noMatch, style: TextStyle(color: c.secondary))),
              ),
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

BoxDecoration _cardDecoration(BuildContext context) {
  final c = context.vc;
  return BoxDecoration(
    color: c.card,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: c.border),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.vc.secondary),
      ),
    );
  }
}

class _EnglishTile extends StatelessWidget {
  const _EnglishTile();

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(context),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('English', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(S.englishBuiltIn, style: TextStyle(color: c.secondary, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: c.accent),
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
    final c = context.vc;
    final code = language.code;
    final info = packs.info(code);
    final installed = packs.installed[code];
    final busy = packs.isBusy(code);
    final hasUpdate = packs.hasUpdate(code);
    final error = packs.errors[code];
    final native = language.native.isEmpty ? '' : '\u2068${language.native}\u2069 · ';
    final beta = (info?.beta ?? false) ? ' · ${S.beta}' : '';

    String subtitle;
    if (busy) {
      subtitle = 'Downloading ${(packs.progress[code]! * 100).toStringAsFixed(0)}%';
    } else if (installed != null) {
      subtitle = hasUpdate
          ? '${S.updateAvailable} · ${formatBytes(info!.size)}'
          : '$native${S.installed} · ${formatBytes(installed.size)}$beta';
    } else if (info != null) {
      subtitle = '$native${formatBytes(info.size)}$beta';
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
        icon: Icon(Icons.delete_outline_rounded, color: c.secondary),
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
      decoration: _cardDecoration(context),
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
                    Text(subtitle, style: TextStyle(color: c.secondary, fontSize: 13)),
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
            Text(error, style: TextStyle(color: c.danger, fontSize: 13)),
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
    final c = context.vc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.soft, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: c.heading, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StorageCard extends StatefulWidget {
  const _StorageCard({required this.packs, required this.updates});

  final PackController packs;
  final UpdateService updates;

  @override
  State<_StorageCard> createState() => _StorageCardState();
}

class _StorageCardState extends State<_StorageCard> {
  int _updateBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  Future<void> _loadSize() async {
    final n = await widget.updates.downloadsSize();
    if (mounted) setState(() => _updateBytes = n);
  }

  Future<void> _removeAll() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.removeAllTitle),
        content: const Text(S.removeAllBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(S.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text(S.remove)),
        ],
      ),
    );
    if (yes == true) await widget.packs.removeAll();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    final packs = widget.packs;
    final count = packs.installed.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(S.storageTitle, style: TextStyle(fontSize: 13, color: c.secondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  count == 0 ? 'No language packs downloaded' : S.packsUsed(formatBytes(packs.installedBytes), count),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (count > 0) TextButton(onPressed: _removeAll, child: const Text(S.removeAll)),
            ],
          ),
          if (_updateBytes > 0)
            Row(
              children: <Widget>[
                Expanded(child: Text(S.updateFiles(formatBytes(_updateBytes)), style: TextStyle(color: c.secondary))),
                TextButton(
                  onPressed: () async {
                    await widget.updates.clearDownloads();
                    await _loadSize();
                  },
                  child: const Text(S.clear),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatefulWidget {
  const _SettingsCard();

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final c = context.vc;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(S.settingsTitle, style: TextStyle(fontSize: 13, color: c.secondary, fontWeight: FontWeight.w700)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(S.clipboardSetting),
            subtitle: const Text(S.clipboardSettingHint),
            value: settings.clipboardOffer,
            onChanged: (v) async {
              await settings.setClipboardOffer(v);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _AppUpdateCard extends StatelessWidget {
  const _AppUpdateCard({required this.service});

  final UpdateService service;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
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
      decoration: BoxDecoration(color: c.soft, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(S.appUpdateTitle, style: TextStyle(fontSize: 13, color: c.secondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(status, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.heading)),
                    if (service.updateAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(S.updateKeepsData, style: TextStyle(fontSize: 12.5, color: c.secondary)),
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
            Text(service.error!, style: TextStyle(color: c.danger, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
