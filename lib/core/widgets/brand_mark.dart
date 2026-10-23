import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// The app's mark: two overlapping sheets (before → after) and, optionally,
/// the serif wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(back: p.ink, front: p.accent, paper: p.paper),
      ),
    );

    if (!showWordmark) {
      return Semantics(label: 'File Convertor', child: mark);
    }

    return Semantics(
      label: 'File Convertor',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.36),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'File '),
                const TextSpan(
                  text: 'Convertor',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            style: TextStyle(
              fontFamily: AppFonts.serif,
              fontSize: size * 0.86,
              height: 1,
              color: p.ink,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.back, required this.front, required this.paper});

  final Color back;
  final Color front;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final w = s * 0.62;
    final h = s * 0.78;
    final r = Radius.circular(s * 0.1);

    // Back sheet (source), tilted left.
    canvas.save();
    canvas.translate(s * 0.34, s * 0.52);
    canvas.rotate(-0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        r,
      ),
      Paint()..color = back,
    );
    canvas.restore();

    // Front sheet (result), with a folded corner.
    canvas.save();
    canvas.translate(s * 0.62, s * 0.5);
    canvas.rotate(0.1);
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final fold = w * 0.32;
    final path = Path()
      ..moveTo(rect.left + r.x, rect.top)
      ..lineTo(rect.right - fold, rect.top)
      ..lineTo(rect.right, rect.top + fold)
      ..lineTo(rect.right, rect.bottom - r.x)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right - r.x,
        rect.bottom,
      )
      ..lineTo(rect.left + r.x, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - r.x)
      ..lineTo(rect.left, rect.top + r.x)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + r.x, rect.top)
      ..close();
    // Paper-coloured halo separates the sheets at any size.
    canvas.drawPath(
      path,
      Paint()
        ..color = paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07,
    );
    canvas.drawPath(path, Paint()..color = front);
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - fold, rect.top)
        ..lineTo(rect.right - fold, rect.top + fold)
        ..lineTo(rect.right, rect.top + fold)
        ..close(),
      Paint()..color = paper.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.back != back || old.front != front || old.paper != paper;
}
