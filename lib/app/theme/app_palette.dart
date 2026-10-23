import 'package:file_convertor/core/utils/file_format.dart';
import 'package:flutter/material.dart';

/// Semantic colour tokens. Read them with `context.palette`.
///
/// The palette is "studio paper": warm neutral surfaces, ink-coloured text,
/// one cobalt accent, and a muted, art-directed colour per file family.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.paper,
    required this.surface,
    required this.surfaceSunken,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.families,
  });

  /// Page background.
  final Color paper;

  /// Cards and raised surfaces.
  final Color surface;

  /// Wells, tracks and inset areas.
  final Color surfaceSunken;

  /// Primary text and icons.
  final Color ink;

  /// Secondary text. Meets 4.5:1 on [paper] and [surface].
  final Color inkMuted;

  /// Decorative / disabled only. Never for body text.
  final Color inkFaint;

  /// Hairline borders and dividers.
  final Color line;

  /// Borders that must be visible (inputs, dashed drop zones).
  final Color lineStrong;

  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;

  /// One colour per [FileFamily]. Indexed by [FileFamily.index].
  final List<Color> families;

  Color family(FileFamily family) => families[family.index];

  static const light = AppPalette(
    paper: Color(0xFFF4F1EA),
    surface: Color(0xFFFCFBF7),
    surfaceSunken: Color(0xFFEAE6DC),
    ink: Color(0xFF17160F),
    inkMuted: Color(0xFF5C5950),
    inkFaint: Color(0xFFA19D91),
    line: Color(0xFFE2DDD1),
    lineStrong: Color(0xFF8E887B),
    accent: Color(0xFF2747D9),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE4E8FB),
    success: Color(0xFF1B7148),
    successSoft: Color(0xFFDDF0E4),
    warning: Color(0xFF8F5409),
    warningSoft: Color(0xFFF7EAD2),
    danger: Color(0xFFB8322A),
    dangerSoft: Color(0xFFF8E1DD),
    families: [
      Color(0xFFB23A22), // pdf — vermilion
      Color(0xFF2747D9), // document — cobalt
      Color(0xFF0E6E85), // data — petrol
      Color(0xFF1A6E47), // image — green
      Color(0xFF6B45C9), // video — violet
      Color(0xFF875507), // audio — ochre
      Color(0xFF7D5236), // archive — umber
      Color(0xFF5C5950), // other — graphite
    ],
  );

  static const dark = AppPalette(
    paper: Color(0xFF0F0F0D),
    surface: Color(0xFF181815),
    surfaceSunken: Color(0xFF232320),
    ink: Color(0xFFF2EFE7),
    inkMuted: Color(0xFFA9A598),
    inkFaint: Color(0xFF64615A),
    line: Color(0xFF2B2A26),
    lineStrong: Color(0xFF6B6860),
    accent: Color(0xFF8A9DFF),
    onAccent: Color(0xFF0F0F0D),
    accentSoft: Color(0xFF1F2547),
    success: Color(0xFF5FCB93),
    successSoft: Color(0xFF15301F),
    warning: Color(0xFFE9B04E),
    warningSoft: Color(0xFF33270F),
    danger: Color(0xFFFF7B6E),
    dangerSoft: Color(0xFF3A1915),
    families: [
      Color(0xFFFF8566), // pdf
      Color(0xFF8A9DFF), // document
      Color(0xFF5CC8DF), // data
      Color(0xFF5DD39C), // image
      Color(0xFFB9A0FF), // video
      Color(0xFFF0B651), // audio
      Color(0xFFD9A47E), // archive
      Color(0xFFA9A598), // other
    ],
  );

  @override
  AppPalette copyWith({
    Color? paper,
    Color? surface,
    Color? surfaceSunken,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? line,
    Color? lineStrong,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    List<Color>? families,
  }) {
    return AppPalette(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      families: families ?? this.families,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      paper: l(paper, other.paper),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkFaint: l(inkFaint, other.inkFaint),
      line: l(line, other.line),
      lineStrong: l(lineStrong, other.lineStrong),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      families: [
        for (var i = 0; i < families.length; i++)
          l(families[i], other.families[i]),
      ],
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
