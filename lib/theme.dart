import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF534AB7);
const Color kDeep = Color(0xFF3C3489);
const Color kMid = Color(0xFFAFA9EC);
const Color kSoft = Color(0xFFEEEDFE);
const Color kInk = Color(0xFF1A1840);
const Color kSecondary = Color(0xFF5B5878);
const Color kBackground = Color(0xFFF7F6FD);
const Color kBorder = Color(0xFFE7E4F7);
const Color kAmberBg = Color(0xFFFAEEDA);
const Color kAmber = Color(0xFFBA7517);
const Color kAmberInk = Color(0xFF633806);
const Color kGreenBg = Color(0xFFEAF3DE);
const Color kGreenInk = Color(0xFF27500A);
const Color kErrorInk = Color(0xFF8A1F1F);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
  ).copyWith(
    primary: kPrimary,
    onPrimary: Colors.white,
    primaryContainer: kSoft,
    onPrimaryContainer: kDeep,
    surface: Colors.white,
    onSurface: kInk,
    outlineVariant: kBorder,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBackground,
    splashFactory: InkSparkle.splashFactory,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kSoft,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? kDeep : kSecondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? kDeep : kSecondary,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
  );
}
