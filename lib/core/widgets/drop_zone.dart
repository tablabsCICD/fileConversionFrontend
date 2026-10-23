import 'dart:math' as math;

import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/dashed_rounded_rect_painter.dart';
import 'package:file_convertor/core/widgets/file_glyph.dart';
import 'package:file_convertor/core/widgets/format_badge.dart';
import 'package:flutter/material.dart';

/// The file-selection surface: a dashed, tappable zone with a fanned stack of
/// file glyphs that opens up on hover and keyboard focus.
///
/// The whole zone is a single button. It does not accept drag-and-drop; copy
/// should say "choose", not "drop".
class DropZone extends StatefulWidget {
  const DropZone({
    super.key,
    required this.onTap,
    this.title = 'Choose a file',
    this.caption,
    this.formats = const [],
    this.actionLabel = 'Browse files',
    this.errorText,
    this.compact = false,
  });

  /// Null disables the zone.
  final VoidCallback? onTap;

  final String title;

  /// Supporting line under the title, e.g. accepted categories.
  final String? caption;

  /// Accepted extensions, shown as badges and used to colour the glyphs.
  final List<String> formats;

  final String actionLabel;

  /// Shows the invalid-file state.
  final String? errorText;

  /// Tighter layout for grids and small cards.
  final bool compact;

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _hovered = false;
  bool _focused = false;

  bool get _active => (_hovered || _focused) && widget.onTap != null;

  List<String?> get _glyphFormats {
    final f = widget.formats;
    if (f.isEmpty) return const ['pdf', 'jpg', 'docx'];
    if (f.length == 1) return [null, f.first, null];
    if (f.length == 2) return [f[0], f[1], null];
    return [f[0], f[1], f[2]];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final hasError = widget.errorText != null;
    final enabled = widget.onTap != null;
    final duration = AppMotion.of(context, AppMotion.base);

    final borderColor = hasError
        ? p.danger
        : _active
        ? p.accent
        : p.lineStrong;
    final fill = hasError
        ? Color.alphaBlend(p.danger.withValues(alpha: 0.04), p.surface)
        : _active
        ? Color.alphaBlend(p.accent.withValues(alpha: 0.05), p.surface)
        : p.surface;

    final glyphSize = widget.compact ? 30.0 : 46.0;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      focusable: enabled,
      focused: _focused,
      label: [
        widget.title,
        if (widget.formats.isNotEmpty)
          'Accepts ${widget.formats.map((f) => f.toUpperCase()).join(', ')}',
        ?widget.errorText,
      ].join('. '),
      excludeSemantics: true,
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.card,
            boxShadow: _active
                ? AppShadows.float(Theme.of(context).brightness)
                : const [],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onFocusChange: (v) => setState(() => _focused = v),
              borderRadius: AppRadius.card,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              splashColor: p.accent.withValues(alpha: 0.08),
              highlightColor: p.accent.withValues(alpha: 0.04),
              child: CustomPaint(
                painter: DashedRoundedRectPainter(
                  radius: AppRadius.lg,
                  strokeWidth: _focused ? 2 : 1.4,
                  color: borderColor,
                  dashPattern: const [5, 5],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? AppSpace.md : AppSpace.lg,
                    vertical: widget.compact
                        ? AppSpace.lg - 4
                        : AppSpace.xl + 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: double.infinity),
                      _GlyphFan(
                        formats: _glyphFormats,
                        size: glyphSize,
                        open: _active,
                        duration: duration,
                        error: hasError,
                      ),
                      SizedBox(
                        height: widget.compact ? AppSpace.sm : AppSpace.lg,
                      ),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: widget.compact
                            ? text.titleSmall
                            : text.headlineSmall,
                      ),
                      if (widget.caption != null) ...[
                        const SizedBox(height: AppSpace.xs - 2),
                        Text(
                          widget.caption!,
                          textAlign: TextAlign.center,
                          style: text.bodySmall,
                        ),
                      ],
                      if (hasError) ...[
                        const SizedBox(height: AppSpace.sm),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: p.danger,
                            ),
                            const SizedBox(width: AppSpace.xs - 2),
                            Flexible(
                              child: Text(
                                widget.errorText!,
                                textAlign: TextAlign.center,
                                style: text.bodySmall?.copyWith(
                                  color: p.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!widget.compact && widget.formats.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.md),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpace.xs - 2,
                          runSpacing: AppSpace.xs - 2,
                          children: [
                            for (final f in widget.formats) FormatBadge(f),
                          ],
                        ),
                      ],
                      SizedBox(
                        height: widget.compact ? AppSpace.sm : AppSpace.lg,
                      ),
                      _FauxButton(
                        label: widget.actionLabel,
                        compact: widget.compact,
                        enabled: enabled,
                        active: _active,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three file glyphs that fan out when [open].
class _GlyphFan extends StatelessWidget {
  const _GlyphFan({
    required this.formats,
    required this.size,
    required this.open,
    required this.duration,
    required this.error,
  });

  final List<String?> formats;
  final double size;
  final bool open;
  final Duration duration;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final spread = open ? 1.0 : 0.0;
    final width = size * 2.6;
    final height = size * 1.22 + size * 0.25;

    Widget card(int i, String? ext) {
      // i: -1 left, 0 centre, 1 right.
      final angle = i * (0.12 + 0.1 * spread);
      final dx = i * size * (0.42 + 0.22 * spread);
      final dy = i == 0 ? -size * 0.12 * spread : size * 0.06;
      return AnimatedSlide(
        duration: duration,
        curve: AppMotion.emphasized,
        offset: Offset(dx / size, dy / (size * 1.22)),
        child: AnimatedRotation(
          duration: duration,
          curve: AppMotion.emphasized,
          turns: angle / (2 * math.pi),
          child: FileGlyph(
            extension: ext,
            family: error && i == 0 ? FileFamily.pdf : null,
            icon: i == 0 && ext == null ? Icons.add : null,
            blank: i != 0,
            size: size,
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          card(-1, formats[0]),
          card(1, formats[2]),
          card(0, formats[1]),
        ],
      ),
    );
  }
}

/// Visual-only button inside the zone (the zone itself is the button).
class _FauxButton extends StatelessWidget {
  const _FauxButton({
    required this.label,
    required this.compact,
    required this.enabled,
    required this.active,
  });

  final String label;
  final bool compact;
  final bool enabled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = !enabled
        ? p.surfaceSunken
        : active
        ? p.accent
        : p.ink;
    final fg = !enabled
        ? p.inkMuted
        : active
        ? p.onAccent
        : p.paper;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      height: compact ? AppSize.buttonSm : AppSize.buttonMd - 4,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.sm + 2 : AppSpace.lg - 4,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.control),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.north_east, size: compact ? 14 : 16, color: fg),
          const SizedBox(width: AppSpace.xs - 2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (compact
                          ? Theme.of(context).textTheme.labelMedium
                          : Theme.of(context).textTheme.labelLarge)
                      ?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small helper so callers can describe accepted formats consistently.
String describeFormats(List<String> formats) {
  if (formats.isEmpty) return 'Any file type';
  final families = formats.map(FileFamily.fromExtension).toSet();
  if (families.length == 1 && families.first != FileFamily.other) {
    return '${families.first.label} · ${formats.map((f) => '.$f').join('  ')}';
  }
  return formats.map((f) => '.$f').join('  ');
}
