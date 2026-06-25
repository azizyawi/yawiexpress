import 'package:flutter/material.dart';

class HomeHeroBackgroundPainter extends CustomPainter {
  final double progress;

  const HomeHeroBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final isCompact = size.height < 160;
    final scale = isCompact ? 0.82 : 1.0;

    final softLine = Paint()
      ..color = Colors.white.withOpacity(0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * scale
      ..strokeCap = StrokeCap.round;

    final dashed = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;

    final p1 = Path()
      ..moveTo(-20, size.height * .72)
      ..quadraticBezierTo(
        size.width * .28,
        size.height * .58,
        size.width * .50,
        size.height * .68,
      )
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .78,
        size.width + 20,
        size.height * .56,
      );

    final p2 = Path()
      ..moveTo(size.width * .24, size.height * .42)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .32,
        size.width * .58,
        size.height * .40,
      )
      ..quadraticBezierTo(
        size.width * .70,
        size.height * .46,
        size.width * .82,
        size.height * .36,
      );

    canvas.drawPath(p1, softLine);
    _drawAnimatedDashedPath(canvas, p2, dashed, scale);

    final dotPaint = Paint()..color = Colors.white.withOpacity(0.7);

    canvas.drawCircle(
      Offset(size.width * .72, size.height * .33),
      4 * scale,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * .58, size.height * .58),
      4 * scale,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * .24, size.height * .77),
      4 * scale,
      dotPaint,
    );

    final accentPaint = Paint()
      ..color = const Color(0xFFFFD166).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale
      ..strokeCap = StrokeCap.round;

    _drawSpark(
      canvas,
      Offset(size.width * .70, size.height * .18),
      6 * scale,
      accentPaint,
    );
    _drawSpark(
      canvas,
      Offset(size.width * .78, size.height * .23),
      4 * scale,
      accentPaint,
    );
  }

  void _drawAnimatedDashedPath(
    Canvas canvas,
    Path source,
    Paint paint,
    double scale,
  ) {
    final dashWidth = 8.0 * scale;
    final dashSpace = 8.0 * scale;
    final cycle = dashWidth + dashSpace;
    final dashOffset = progress * cycle;

    for (final metric in source.computeMetrics()) {
      double distance = -dashOffset;

      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + dashWidth).clamp(0.0, metric.length);

        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }

        distance += cycle;
      }
    }
  }

  void _drawSpark(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant HomeHeroBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
