import 'package:flutter/material.dart';

// Brand colours used by the logo and as the seed for both themes.
const Color kPrimary = Color(0xFF534AB7);
const Color kMid = Color(0xFFAFA9EC);
const Color kSoft = Color(0xFFEEEDFE);

/// All screen colours, one set for light and one for dark.
@immutable
class VertoColors extends ThemeExtension<VertoColors> {
  const VertoColors({
    required this.bg,
    required this.card,
    required this.border,
    required this.soft,
    required this.secondary,
    required this.accent,
    required this.onAccent,
    required this.heading,
    required this.hero,
    required this.onHero,
    required this.heroMuted,
    required this.heroDeep,
    required this.amberBg,
    required this.amber,
    required this.amberInk,
    required this.greenBg,
    required this.greenInk,
    required this.danger,
  });

  final Color bg;
  final Color card;
  final Color border;
  final Color soft;
  final Color secondary;
  final Color accent;
  final Color onAccent;
  final Color heading;
  final Color hero;
  final Color onHero;
  final Color heroMuted;
  final Color heroDeep;
  final Color amberBg;
  final Color amber;
  final Color amberInk;
  final Color greenBg;
  final Color greenInk;
  final Color danger;

  static const VertoColors light = VertoColors(
    bg: Color(0xFFF7F6FD),
    card: Colors.white,
    border: Color(0xFFE7E4F7),
    soft: Color(0xFFEEEDFE),
    secondary: Color(0xFF5B5878),
    accent: Color(0xFF534AB7),
    onAccent: Colors.white,
    heading: Color(0xFF3C3489),
    hero: Color(0xFF534AB7),
    onHero: Colors.white,
    heroMuted: Color(0xFFAFA9EC),
    heroDeep: Color(0xFF3C3489),
    amberBg: Color(0xFFFAEEDA),
    amber: Color(0xFFBA7517),
    amberInk: Color(0xFF633806),
    greenBg: Color(0xFFEAF3DE),
    greenInk: Color(0xFF27500A),
    danger: Color(0xFF8A1F1F),
  );

  static const VertoColors dark = VertoColors(
    bg: Color(0xFF12111F),
    card: Color(0xFF1C1A30),
    border: Color(0xFF2E2B4A),
    soft: Color(0xFF2A2650),
    secondary: Color(0xFFA8A5C8),
    accent: Color(0xFF8A81F0),
    onAccent: Color(0xFF0F0D2E),
    heading: Color(0xFFCFCBFF),
    hero: Color(0xFF3C3489),
    onHero: Colors.white,
    heroMuted: Color(0xFFAFA9EC),
    heroDeep: Color(0xFF2A2468),
    amberBg: Color(0xFF3A2C14),
    amber: Color(0xFFBA7517),
    amberInk: Color(0xFFF5D9A6),
    greenBg: Color(0xFF1E3318),
    greenInk: Color(0xFFB5E08C),
    danger: Color(0xFFFFB4AB),
  );

  @override
  VertoColors copyWith() => this;

  @override
  VertoColors lerp(ThemeExtension<VertoColors>? other, double t) =>
      (other is VertoColors && t >= 0.5) ? other : this;
}

extension VertoContext on BuildContext {
  VertoColors get vc => Theme.of(this).extension<VertoColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? VertoColors.dark : VertoColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: brightness,
  ).copyWith(
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.soft,
    onPrimaryContainer: c.heading,
    surface: c.card,
    onSurface: brightness == Brightness.dark ? const Color(0xFFECEBFA) : const Color(0xFF1A1840),
    outlineVariant: c.border,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    extensions: <ThemeExtension<dynamic>>[c],
    splashFactory: InkSparkle.splashFactory,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.card,
      indicatorColor: c.soft,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? c.heading : c.secondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? c.heading : c.secondary,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.card),
  );
}
