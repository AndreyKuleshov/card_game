import 'package:flutter/material.dart';
import '../engine/element.dart' as ge;

/// Centralised palette and helpers for the warm-cartoon visual theme.
class GameColors {
  GameColors._();

  // ── Background gradients ──────────────────────────────────────────────────

  /// Warm parchment/cream gradient for menu screens.
  static const List<Color> backgroundStops = [
    Color(0xFFFFF8E1), // amber50
    Color(0xFFFFE0B2), // orange100
  ];

  /// Soft green-felt gradient for the duel tabletop.
  static const List<Color> tabletopStops = [
    Color(0xFF81C784), // green300
    Color(0xFF388E3C), // green700
  ];

  // ── Element colours ───────────────────────────────────────────────────────

  /// Returns the primary colour for a given element.
  static Color elementColor(ge.Element e) {
    switch (e) {
      case ge.Element.fire:
        return const Color(0xFFE64A19); // deep-orange700
      case ge.Element.nature:
        return const Color(0xFF388E3C); // green700
      case ge.Element.water:
        return const Color(0xFF0288D1); // lightBlue700
    }
  }

  /// Returns a single emoji representing the element.
  static String elementEmoji(ge.Element e) {
    switch (e) {
      case ge.Element.fire:
        return '🔥';
      case ge.Element.nature:
        return '🌿';
      case ge.Element.water:
        return '💧';
    }
  }

  /// Returns the Russian display name for the element.
  static String elementName(ge.Element e) {
    switch (e) {
      case ge.Element.fire:
        return 'Огонь';
      case ge.Element.nature:
        return 'Природа';
      case ge.Element.water:
        return 'Вода';
    }
  }

  // ── Shapes ────────────────────────────────────────────────────────────────

  /// Standard corner radius for cards.
  static const double cardRadius = 16;

  /// Corner radius for pill/chip widgets.
  static const double chipRadius = 20;

  // ── ThemeData ─────────────────────────────────────────────────────────────

  /// Warm amber-based Material 3 theme. No custom font assets — uses
  /// fontWeight and letterSpacing to achieve a bold rounded feel.
  static ThemeData warmTheme() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFFF57C00), // orange700
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: base,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFFF8E1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF57C00),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        color: const Color(0xFFFFFDE7),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium:
            TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        headlineSmall: TextStyle(fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400),
        labelSmall:
            TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.3),
      ),
    );
  }
}
