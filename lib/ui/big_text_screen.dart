import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-screen, large text so the translation can be shown to someone else.
class BigTextScreen extends StatefulWidget {
  const BigTextScreen({super.key, required this.text, required this.rtl});

  final String text;
  final bool rtl;

  @override
  State<BigTextScreen> createState() => _BigTextScreenState();
}

class _BigTextScreenState extends State<BigTextScreen> {
  double _size = 48;

  @override
  Widget build(BuildContext context) {
    final c = context.vc;
    return Scaffold(
      backgroundColor: c.hero,
      appBar: AppBar(
        backgroundColor: c.hero,
        foregroundColor: c.onHero,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            tooltip: 'Smaller',
            onPressed: _size > 24 ? () => setState(() => _size -= 8) : null,
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            tooltip: 'Larger',
            onPressed: _size < 120 ? () => setState(() => _size += 8) : null,
            icon: const Icon(Icons.text_increase_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(color: c.onHero, fontSize: _size, fontWeight: FontWeight.w600, height: 1.25),
            ),
          ),
        ),
      ),
    );
  }
}
