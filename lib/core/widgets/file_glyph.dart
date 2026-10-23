import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:flutter/material.dart';

/// A drawn sheet of paper with a folded corner, tinted by file family.
///
/// Shows the extension in mono type when there is room, otherwise the family
/// icon. Purely decorative: wrap the parent in [Semantics] if it needs a name.
class FileGlyph extends StatelessWidget {
  const FileGlyph({
    super.key,
    this.extension,
    this.family,
    this.size = 44,
    this.icon,
    this.blank = false,
  });

  /// e.g. `pdf`. Optional; drives the label and (if [family] is null) colour.
  final String? extension;

  final FileFamily? family;

  /// Width in logical pixels. Height is `size * 1.22`.
  final double size;

  /// Forces an icon instead of the extension label.
  final IconData? icon;

  /// Draws the sheet only, with no label or icon.
  final bool blank;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fam = family ?? FileFamily.fromExtension(extension);
    final color = p.family(fam);
    final label = extension?.toUpperCase();
    final showLabel =
        icon == null && label != null && label.length <= 4 && size >= 34;

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size * 1.22,
        child: CustomPaint(
          painter: _SheetPainter(
            fill: Color.alphaBlend(color.withValues(alpha: 0.11), p.surface),
            stroke: color.withValues(alpha: 0.55),
            fold: Color.alphaBlend(color.withValues(alpha: 0.32), p.surface),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              size * 0.14,
              size * 0.34,
              size * 0.1,
              size * 0.16,
            ),
            child: blank
                ? null
                : Align(
                    alignment: showLabel
                        ? Alignment.bottomLeft
                        : Alignment.center,
                    child: showLabel
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              style: AppType.mono.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: size * 0.24,
                                letterSpacing: 0.2,
                                height: 1,
                              ),
                            ),
                          )
                        : Icon(
                            icon ?? fam.icon,
                            color: color,
                            size: size * 0.44,
                          ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SheetPainter extends CustomPainter {
  _SheetPainter({required this.fill, required this.stroke, required this.fold});

  final Color fill;
  final Color stroke;
  final Color fold;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.14; // corner radius
    final f = w * 0.3; // fold size

    final sheet = Path()
      ..moveTo(r, 0)
      ..lineTo(w - f, 0)
      ..lineTo(w, f)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();

    final corner = Path()
      ..moveTo(w - f, 0)
      ..lineTo(w - f, f - r * 0.6)
      ..quadraticBezierTo(w - f, f, w - f + r * 0.6, f)
      ..lineTo(w, f)
      ..close();

    canvas.drawPath(sheet, Paint()..color = fill);
    canvas.drawPath(corner, Paint()..color = fold);
    canvas.drawPath(
      sheet,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SheetPainter old) =>
      old.fill != fill || old.stroke != stroke || old.fold != fold;
}
