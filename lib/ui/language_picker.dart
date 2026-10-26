import 'package:flutter/material.dart';

import '../core/languages.dart';
import '../strings.dart';
import '../theme.dart';

/// Searchable list of installed languages. Works for 5 languages or 50.
Future<void> showLanguagePicker(
  BuildContext context, {
  required List<Language> languages,
  required String? selected,
  required ValueChanged<String> onSelect,
  required VoidCallback onMore,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _Picker(
      languages: languages,
      selected: selected,
      onSelect: (code) {
        Navigator.of(ctx).pop();
        onSelect(code);
      },
      onMore: () {
        Navigator.of(ctx).pop();
        onMore();
      },
    ),
  );
}

class _Picker extends StatefulWidget {
  const _Picker({
    required this.languages,
    required this.selected,
    required this.onSelect,
    required this.onMore,
  });

  final List<Language> languages;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onMore;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    final q = _query.trim().toLowerCase();
    final shown = widget.languages.where((l) {
      if (q.isEmpty) return true;
      return l.name.toLowerCase().contains(q) ||
          l.native.toLowerCase().contains(q) ||
          l.code.toLowerCase().contains(q);
    }).toList();
    final height = MediaQuery.of(context).size.height * 0.7;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: S.searchLanguages,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: c.soft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? Center(child: Text(S.noMatch, style: TextStyle(color: c.secondary)))
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final l = shown[i];
                        return ListTile(
                          title: Text(l.name),
                          subtitle: l.native.isEmpty ? null : Text(l.native),
                          trailing: l.code == widget.selected
                              ? Icon(Icons.check_rounded, color: c.accent)
                              : null,
                          onTap: () => widget.onSelect(l.code),
                        );
                      },
                    ),
            ),
            ListTile(
              leading: Icon(Icons.add_rounded, color: c.accent),
              title: const Text(S.getMoreLanguages),
              onTap: widget.onMore,
            ),
          ],
        ),
      ),
    );
  }
}
