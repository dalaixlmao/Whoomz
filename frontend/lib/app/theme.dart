import 'package:flutter/material.dart';

/// Design tokens from the Whoomz AI board:
/// #FAF9F6 paper · #111110 ink · one electric accent held under 5% of any
/// screen (voice state, streaming caret, primary CTA). 1g: OLED true black.
/// The accent is switchable in Tweaks; everything else is fixed.
class WhoomzPalette {
  const WhoomzPalette({
    required this.paper,
    required this.ink,
    required this.surface,
    this.accent = electric,
  });

  final Color paper;
  final Color ink;
  final Color surface;
  final Color accent;

  static const Color electric = Color(0xFF2635F0);

  Color get whisper => ink.withValues(alpha: 0.45);
  Color get faint => ink.withValues(alpha: 0.22);
  Color get hairline => ink.withValues(alpha: 0.08);
  Color get onInk => paper;

  WhoomzPalette withAccent(Color accent) =>
      WhoomzPalette(paper: paper, ink: ink, surface: surface, accent: accent);

  static const WhoomzPalette light = WhoomzPalette(
    paper: Color(0xFFFAF9F6),
    ink: Color(0xFF111110),
    surface: Color(0xFFFFFFFF),
  );

  static const WhoomzPalette dark = WhoomzPalette(
    paper: Color(0xFF000000),
    ink: Color(0xFFFAF9F6),
    surface: Color(0xFF111110),
  );
}

/// General Sans, the only family.
/// Scale: 96 display / 42 metric / 17 body / 11 caps labels at +8% tracking.
class WhoomzType {
  static const String family = 'General Sans';

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 96,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: -2,
  );

  static const TextStyle metric = TextStyle(
    fontFamily: family,
    fontSize: 42,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle caps = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.88,
  );

  static const TextStyle keypad = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );
}

ThemeData whoomzTheme(
  Brightness brightness, {
  Color accent = WhoomzPalette.electric,
}) {
  final palette = brightness == Brightness.dark
      ? WhoomzPalette.dark
      : WhoomzPalette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: WhoomzType.family,
    scaffoldBackgroundColor: palette.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      surface: palette.paper,
      onSurface: palette.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(cursorColor: accent),
  );
}

extension WhoomzContext on BuildContext {
  WhoomzPalette get wz {
    final theme = Theme.of(this);
    final base = theme.brightness == Brightness.dark
        ? WhoomzPalette.dark
        : WhoomzPalette.light;
    return base.withAccent(theme.colorScheme.primary);
  }
}
