import 'package:flutter/material.dart';

class DashedRoundedRectPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Color color;
  final List<double> dashPattern;

  DashedRoundedRectPainter({
    required this.radius,
    required this.strokeWidth,
    required this.color,
    this.dashPattern = const [6, 4],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final dashPath = _createDashedPath(path, dashPattern);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, List<double> dashArray) {
    final Path dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      int index = 0;

      while (distance < metric.length) {
        final length = dashArray[index % dashArray.length];
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
        index++;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
