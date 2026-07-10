import 'package:flutter/material.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class HomeHeroBackgroundPainter extends CustomPainter {
  final double progress;

  const HomeHeroBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height < 160 ? 0.82 : 1.0;
    final brand = AppColors.brandBlueDark;

    canvas.drawRect(Offset.zero & size, Paint()..color = brand);

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 * scale
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = Colors.white.withOpacity(.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round;

    final artPaint = Paint()
      ..color = Colors.white.withOpacity(.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softFill = Paint()
      ..color = Colors.white.withOpacity(.055)
      ..style = PaintingStyle.fill;

    final route = Path()
      ..moveTo(size.width * .23, size.height * .63)
      ..cubicTo(
        size.width * .38,
        size.height * .46,
        size.width * .55,
        size.height * .70,
        size.width * .73,
        size.height * .52,
      )
      ..cubicTo(
        size.width * .80,
        size.height * .45,
        size.width * .85,
        size.height * .43,
        size.width * .91,
        size.height * .47,
      );

    canvas.drawPath(route, glowPaint);
    _drawAnimatedDashedPath(canvas, route, routePaint, scale);

    _drawLocationPin(
      canvas,
      Offset(size.width * .23, size.height * .60),
      scale,
      artPaint,
      softFill,
    );

    _drawPackage(
      canvas,
      Offset(size.width * .70, size.height * .34),
      scale,
      artPaint,
      softFill,
    );

    _drawMiniBike(
      canvas,
      Offset(size.width * .20, size.height * .80),
      scale,
      artPaint,
    );

    _drawHelmetShadow(
      canvas,
      Offset(size.width * .82, size.height * .78),
      scale,
    );

    _drawSoftCircle(
      canvas,
      Offset(size.width * .86, size.height * .34),
      5 * scale,
      Colors.white.withOpacity(.18),
    );

    _drawPlus(
      canvas,
      Offset(size.width * .62, size.height * .30),
      7 * scale,
      Colors.white.withOpacity(.18),
      scale,
    );
  }

  void _drawPackage(
    Canvas canvas,
    Offset center,
    double scale,
    Paint stroke,
    Paint fill,
  ) {
    final w = 38 * scale;
    final h = 32 * scale;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      Radius.circular(7 * scale),
    );

    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, stroke);

    canvas.drawLine(
      Offset(center.dx - w * .48, center.dy - h * .12),
      Offset(center.dx + w * .48, center.dy - h * .12),
      stroke,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - h * .48),
      Offset(center.dx, center.dy + h * .48),
      stroke,
    );
  }

  void _drawLocationPin(
    Canvas canvas,
    Offset center,
    double scale,
    Paint stroke,
    Paint fill,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy + 18 * scale)
      ..cubicTo(
        center.dx - 15 * scale,
        center.dy + 2 * scale,
        center.dx - 12 * scale,
        center.dy - 18 * scale,
        center.dx,
        center.dy - 18 * scale,
      )
      ..cubicTo(
        center.dx + 12 * scale,
        center.dy - 18 * scale,
        center.dx + 15 * scale,
        center.dy + 2 * scale,
        center.dx,
        center.dy + 18 * scale,
      )
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(center.translate(0, -5 * scale), 4 * scale, stroke);
  }

  void _drawMiniBike(Canvas canvas, Offset center, double scale, Paint paint) {
    final wheel = 10 * scale;

    canvas.drawCircle(center, wheel, paint);
    canvas.drawCircle(center.translate(44 * scale, 0), wheel, paint);

    canvas.drawLine(center, center.translate(18 * scale, -18 * scale), paint);
    canvas.drawLine(
      center.translate(18 * scale, -18 * scale),
      center.translate(44 * scale, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(18 * scale, -18 * scale),
      center.translate(34 * scale, -22 * scale),
      paint,
    );
    canvas.drawLine(
      center.translate(34 * scale, -22 * scale),
      center.translate(48 * scale, -17 * scale),
      paint,
    );
  }

  void _drawHelmetShadow(Canvas canvas, Offset center, double scale) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(.10)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 78 * scale, height: 11 * scale),
        Radius.circular(20 * scale),
      ),
      paint,
    );
  }

  void _drawPlus(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    double scale,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7 * scale
      ..strokeCap = StrokeCap.round;

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

  void _drawSoftCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  void _drawAnimatedDashedPath(
    Canvas canvas,
    Path source,
    Paint paint,
    double scale,
  ) {
    final dashWidth = 9.0 * scale;
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

  @override
  bool shouldRepaint(covariant HomeHeroBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
