import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

class AppTheme {
  // ---------- COLORS ----------
  /// Brand accent (light theme). Prefer `context.palette.accent`, which
  /// adapts to the active theme.
  static const Color primary = Color(0xFF2747D9);

  // ---------- THEMES ----------
  static final lightTheme = _build(Brightness.light, AppPalette.light);
  static final darkTheme = _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.accent,
      secondary: p.ink,
      onSecondary: p.paper,
      tertiary: p.families[2],
      onTertiary: p.paper,
      error: p.danger,
      onError: p.paper,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkMuted,
      surfaceContainerLowest: p.paper,
      surfaceContainerLow: p.paper,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceSunken,
      outline: p.lineStrong,
      outlineVariant: p.line,
      inverseSurface: p.ink,
      onInverseSurface: p.paper,
      inversePrimary: p.accentSoft,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
    );
    final textTheme = buildAppTextTheme(p.ink, p.inkMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
      textTheme: textTheme,
      primaryColor: p.accent,
      scaffoldBackgroundColor: p.paper,
      canvasColor: p.surface,
      cardColor: p.surface,
      dividerColor: p.line,
      hintColor: p.inkMuted,
      disabledColor: p.inkFaint,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: IconThemeData(color: p.ink, size: 22),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceSunken,
        circularTrackColor: p.surfaceSunken,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.paper),
        actionTextColor: p.accentSoft,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: AppType.mono.copyWith(color: p.paper, fontSize: 11),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.inkMuted),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.ink,
        textColor: p.ink,
        minVerticalPadding: AppSpace.sm,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: p.inkMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: p.lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: p.lineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: p.danger, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.25),
        selectionHandleColor: p.accent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
