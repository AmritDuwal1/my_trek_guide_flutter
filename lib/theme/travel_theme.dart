import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reference: light canvas, green accent for active nav (travel app home).
abstract final class TravelColors {
  static const canvas = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  /// Deep copy text (headings).
  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF8E8E93);
  static const line = Color(0xFFE8E8E8);
  /// Active bottom-nav / primary actions (teal-green from reference).
  static const navActive = Color(0xFF2EB67D);
  static const primary = navActive;
  static const accent = Color(0xFFFF8B4D);
}

ThemeData buildTravelTheme() {
  const scheme = ColorScheme.light(
    primary: TravelColors.navActive,
    onPrimary: Colors.white,
    secondary: TravelColors.accent,
    onSecondary: Colors.white,
    surface: TravelColors.surface,
    onSurface: TravelColors.ink,
    outline: TravelColors.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: TravelColors.canvas,
    splashFactory: InkRipple.splashFactory,
  );

  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
    bodyColor: TravelColors.ink,
    displayColor: TravelColors.ink,
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: TravelColors.ink,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: TravelColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: TravelColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: TravelColors.line, thickness: 1),
  );
}
