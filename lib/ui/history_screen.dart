import 'package:flutter/material.dart';

import '../core/history.dart';
import '../core/languages.dart';
import '../services.dart';
import '../strings.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.onOpenTranslate});

  final VoidCallback onOpenTranslate;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';
  bool _favoritesOnly = false;

  Future<void> _confirm(BuildContext context, String title, String body, VoidCallback onYes) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(S.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text(S.delete)),
        ],
      ),
    );
    if (yes == true) onYes();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final history = services.history;
    final c = context.vc;
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        final items = history.search(_query, favoritesOnly: _favoritesOnly);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    S.historyTitle,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.heading),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: c.secondary),
                  onSelected: (v) {
                    if (v == 'history') {
                      _confirm(context, S.clearHistory, S.clearHistoryBody, history.clearHistory);
                    } else {
                      _confirm(context, S.clearEverything, S.clearEverythingBody, history.clearAll);
                    }
                  },
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'history', child: Text(S.clearHistory)),
                    PopupMenuItem<String>(value: 'all', child: Text(S.clearEverything)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: S.searchHistory,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: c.soft,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: false, label: Text(S.all)),
                ButtonSegment<bool>(value: true, icon: Icon(Icons.star_rounded), label: Text(S.favourites)),
              ],
              selected: <bool>{_favoritesOnly},
              onSelectionChanged: (s) => setState(() => _favoritesOnly = s.first),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(S.saveHistory),
              subtitle: const Text(S.saveHistoryHint),
              value: history.enabled,
              onChanged: (v) => history.setEnabled(v),
            ),
            const SizedBox(height: 4),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    _favoritesOnly ? S.favouritesEmpty : S.historyEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.secondary),
                  ),
                ),
              )
            else
              for (final item in items)
                _ItemCard(item: item, onOpened: widget.onOpenTranslate),
          ],
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onOpened});

  final SavedItem item;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.vc;
    String name(String code) => services.packs.languageFor(code)?.name ?? code;
    final toLang = languageByCode(item.to) ?? services.packs.languageFor(item.to);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (services.translation.openItem(item)) {
            onOpened();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.downloadFirst(name(item.from == 'en' ? item.to : item.from)))),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${name(item.from)} → ${name(item.to)}',
                      style: TextStyle(fontSize: 12, color: c.secondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: item.favorite ? S.unfavorite : S.favorite,
                    onPressed: () => services.history.toggleFavoriteById(item.id),
                    icon: Icon(
                      item.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: item.favorite ? const Color(0xFFE5A400) : c.secondary,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: S.delete,
                    onPressed: () => services.history.remove(item.id),
                    icon: Icon(Icons.delete_outline_rounded, color: c.secondary),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(item.source, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.secondary)),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  item.target,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textDirection: (toLang?.rtl ?? false) ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
