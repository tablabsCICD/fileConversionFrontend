import 'package:flutter/material.dart';

/// Design tokens shared by every screen and component.
///
/// Colors live in [AppPalette] (a [ThemeExtension], so they switch with the
/// theme). Everything that does not depend on brightness lives here.

/// Spacing scale (4pt base).
abstract final class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Horizontal page gutter for a given viewport width.
  static double gutter(double width) {
    if (width >= AppBreakpoints.desktop) return xxl;
    if (width >= AppBreakpoints.tablet) return xl;
    return md + xxs; // 20
  }

  /// Bottom padding that keeps content clear of the floating nav bar.
  static const double navClearance = 112;
}

/// Corner radii. Controls are tight, surfaces are soft, pills are pills.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius control = BorderRadius.all(Radius.circular(md));
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet = BorderRadius.all(Radius.circular(xl));
}

/// Width breakpoints, shared with [ResponsiveWidget].
abstract final class AppBreakpoints {
  static const double tablet = 750;
  static const double desktop = 1100;

  /// Comfortable reading width for forms and single-column flows.
  static const double content = 640;
}

/// Component dimensions.
abstract final class AppSize {
  /// Minimum interactive size (WCAG / Material guidance).
  static const double tapTarget = 48;
  static const double buttonSm = 36;
  static const double buttonMd = 48;
  static const double buttonLg = 56;
  static const double field = 52;
  static const double hairline = 1;
}

/// Motion: three durations and two curves. Use [AppMotion.of] so motion
/// collapses when the platform asks for reduced animation.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 460);

  /// Entering / emphasised movement.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// Small state changes (colour, opacity).
  static const Curve standard = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when reduced motion is requested.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Elevation is mostly expressed with hairlines; shadows are reserved for
/// surfaces that genuinely float (nav bar, hovered drop zone, dialogs).
abstract final class AppShadows {
  static List<BoxShadow> float(Brightness brightness) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.5 : 0.08,
      ),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.3 : 0.04,
      ),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}
