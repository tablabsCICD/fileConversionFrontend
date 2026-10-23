import 'package:flutter/material.dart';

/// Font families bundled in `assets/fonts` (SIL Open Font License).
abstract final class AppFonts {
  /// Editorial display face for headlines and large numerals.
  static const serif = 'InstrumentSerif';

  /// Technical face for formats, sizes, counters and eyebrows.
  static const mono = 'IBMPlexMono';
}

/// Type roles that sit outside Material's [TextTheme].
///
/// Colours are deliberately omitted so styles inherit from the surrounding
/// [DefaultTextStyle]; add one with `copyWith(color: ...)` where needed.
abstract final class AppType {
  /// Small uppercase label above a heading: `02 — RECENT`.
  static const eyebrow = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    height: 1.3,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// Inline technical data: file sizes, formats, percentages.
  static const mono = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 12,
    height: 1.35,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w500,
  );

  /// Large serif numerals (storage %, progress).
  static const numeral = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 44,
    height: 1,
    letterSpacing: -1,
  );
}

/// Builds the Material [TextTheme]: serif for display/headline roles, the
/// platform sans (SF Pro / Roboto) for UI text, mono for the smallest labels.
TextTheme buildAppTextTheme(Color ink, Color inkMuted) {
  const serif = AppFonts.serif;
  return TextTheme(
    displayLarge: const TextStyle(
      fontFamily: serif,
      fontSize: 64,
      height: 0.98,
      letterSpacing: -1.8,
    ),
    displayMedium: const TextStyle(
      fontFamily: serif,
      fontSize: 52,
      height: 1,
      letterSpacing: -1.4,
    ),
    displaySmall: const TextStyle(
      fontFamily: serif,
      fontSize: 42,
      height: 1.02,
      letterSpacing: -1,
    ),
    headlineLarge: const TextStyle(
      fontFamily: serif,
      fontSize: 36,
      height: 1.05,
      letterSpacing: -0.6,
    ),
    headlineMedium: const TextStyle(
      fontFamily: serif,
      fontSize: 31,
      height: 1.08,
      letterSpacing: -0.4,
    ),
    headlineSmall: const TextStyle(
      fontFamily: serif,
      fontSize: 27,
      height: 1.1,
      letterSpacing: -0.2,
    ),
    titleLarge: const TextStyle(
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
    bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: inkMuted),
    labelLarge: const TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    labelMedium: const TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: const TextStyle(
      fontFamily: AppFonts.mono,
      fontSize: 11,
      height: 1.25,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w500,
    ),
  ).apply(bodyColor: ink, displayColor: ink);
}
