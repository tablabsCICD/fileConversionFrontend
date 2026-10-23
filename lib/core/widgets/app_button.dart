import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant {
  /// Solid accent — one per view, for the main action.
  primary,

  /// Solid ink — high emphasis without competing with the accent.
  ink,

  /// Hairline outline — secondary actions.
  secondary,

  /// Text only — tertiary actions.
  ghost,

  /// Destructive actions.
  danger,
}

enum AppButtonSize { small, medium, large }

/// The single button used across the app.
///
/// Built on Material buttons so focus, keyboard activation, hover and
/// semantics come for free. Pass `onPressed: null` to disable.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Shows a spinner and blocks presses while keeping the button's width.
  final bool isLoading;

  /// Stretch to the available width.
  final bool expand;

  double get _height => switch (size) {
    AppButtonSize.small => AppSize.buttonSm,
    AppButtonSize.medium => AppSize.buttonMd,
    AppButtonSize.large => AppSize.buttonLg,
  };

  double get _hPad => switch (size) {
    AppButtonSize.small => AppSpace.sm + 2,
    AppButtonSize.medium => AppSpace.lg - 2,
    AppButtonSize.large => AppSpace.xl - 4,
  };

  double get _iconSize => size == AppButtonSize.small ? 16 : 19;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final (Color bg, Color fg, BorderSide? side) = switch (variant) {
      AppButtonVariant.primary => (p.accent, p.onAccent, null),
      AppButtonVariant.ink => (p.ink, p.paper, null),
      AppButtonVariant.secondary => (
        Colors.transparent,
        p.ink,
        BorderSide(color: p.lineStrong),
      ),
      AppButtonVariant.ghost => (Colors.transparent, p.ink, null),
      AppButtonVariant.danger => (p.danger, p.onAccent, null),
    };
    final solid = bg != Colors.transparent;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(_height, _height)),
      fixedSize: WidgetStatePropertyAll(Size.fromHeight(_height)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: _hPad)),
      // Small buttons keep a 48dp hit area even though they draw at 36.
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(
        (size == AppButtonSize.small ? text.labelMedium : text.labelLarge),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return solid ? p.surfaceSunken : Colors.transparent;
        }
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return p.inkMuted;
        return fg;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        final base = solid ? fg : p.ink;
        if (states.contains(WidgetState.pressed)) {
          return base.withValues(alpha: 0.14);
        }
        if (states.contains(WidgetState.hovered)) {
          return base.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return base.withValues(alpha: 0.12);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: p.accent, width: 2);
        }
        if (side != null && states.contains(WidgetState.disabled)) {
          return BorderSide(color: p.line);
        }
        return side;
      }),
      animationDuration: AppMotion.of(context, AppMotion.fast),
    );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox.square(
            dimension: _iconSize - 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: solid ? fg : p.ink,
              backgroundColor: Colors.transparent,
            ),
          )
        else if (icon != null)
          Icon(icon, size: _iconSize),
        if (isLoading || icon != null) const SizedBox(width: AppSpace.xs),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpace.xs),
          Icon(trailingIcon, size: _iconSize),
        ],
      ],
    );

    final button = TextButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: content,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Square icon-only button with a required tooltip (which doubles as its
/// accessible name).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
    this.color,
    this.size = 20,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Draws a sunken circular background behind the icon.
  final bool filled;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      icon: Icon(icon, size: size),
      tooltip: tooltip,
      onPressed: onPressed,
      color: color ?? p.ink,
      disabledColor: p.inkFaint,
      constraints: const BoxConstraints.tightFor(
        width: AppSize.tapTarget,
        height: AppSize.tapTarget,
      ),
      style: IconButton.styleFrom(
        backgroundColor: filled ? p.surfaceSunken : null,
        hoverColor: p.ink.withValues(alpha: 0.06),
        focusColor: p.accent.withValues(alpha: 0.16),
        highlightColor: p.ink.withValues(alpha: 0.1),
      ),
    );
  }
}
