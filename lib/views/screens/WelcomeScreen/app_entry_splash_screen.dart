import 'package:flutter/material.dart';
import 'package:wanmac/views/screens/main/main_screen.dart';

class AppEntrySplashScreen extends StatefulWidget {
  const AppEntrySplashScreen({super.key});

  @override
  State<AppEntrySplashScreen> createState() => _AppEntrySplashScreenState();
}

class _AppEntrySplashScreenState extends State<AppEntrySplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bikeProgress;
  late Animation<double> _bikeOpacity;

  static const Color splashBlue = Color(0xFF061F70);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _bikeProgress = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bikeOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _responsiveValue({
    required double width,
    required double phone,
    required double tablet,
    required double desktop,
  }) {
    if (width >= 1000) return desktop;
    if (width >= 600) return tablet;
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final shortestSide = size.shortestSide;
    final isLandscape = screenWidth > screenHeight;

    final logoWidth = isLandscape
        ? (screenWidth * 0.34).clamp(250.0, 360.0)
        : (screenWidth * 0.72).clamp(250.0, 420.0);

    final bikeWidth = _responsiveValue(
      width: screenWidth,
      phone: shortestSide * 0.44,
      tablet: shortestSide * 0.34,
      desktop: 220,
    ).clamp(145.0, 240.0);

    final bikeStartX = -bikeWidth;
    final bikeEndX = screenWidth;

    final bottomSpacing = isLandscape
        ? 35.0
        : _responsiveValue(
            width: screenWidth,
            phone: 70,
            tablet: 95,
            desktop: 120,
          );

    final bikeY = screenHeight - bikeWidth - bottomSpacing;

    final roadBottom = isLandscape
        ? 42.0
        : _responsiveValue(
            width: screenWidth,
            phone: 95,
            tablet: 125,
            desktop: 145,
          );

    return Scaffold(
      backgroundColor: splashBlue,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF061F70), Color(0xFF0A36B5), Color(0xFF1148D8)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: WanmacRoutePatternPainter()),
              ),

              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final bikeX =
                      bikeStartX +
                      ((bikeEndX - bikeStartX) * _bikeProgress.value);

                  return Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/wanmac_logo_white.png',
                          width: logoWidth,
                          fit: BoxFit.contain,
                        ),
                      ),

                      Positioned(
                        bottom: roadBottom,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: 0.16,
                          child: Container(height: 2, color: Colors.white),
                        ),
                      ),

                      Positioned(
                        left: bikeX + (bikeWidth * 0.22),
                        top: bikeY + (bikeWidth * 0.54),
                        child: Opacity(
                          opacity: _bikeOpacity.value * 0.24,
                          child: Container(
                            width: bikeWidth * 0.53,
                            height: bikeWidth * 0.095,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: bikeX,
                        top: bikeY,
                        child: Opacity(
                          opacity: _bikeOpacity.value,
                          child: Image.asset(
                            'assets/images/wanmac_bike.png',
                            width: bikeWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WanmacRoutePatternPainter extends CustomPainter {
  const WanmacRoutePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.shortestSide / 390).clamp(0.85, 1.35);

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.085)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * scale
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scale);

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;

    final rowHeight = 110 * scale;
    final waveHeight = 24 * scale;

    for (double y = 70 * scale; y < size.height + rowHeight; y += rowHeight) {
      final path = Path()..moveTo(-40 * scale, y);

      for (
        double x = -40 * scale;
        x < size.width + 120 * scale;
        x += 120 * scale
      ) {
        path.cubicTo(
          x + 35 * scale,
          y - waveHeight,
          x + 85 * scale,
          y + waveHeight,
          x + 120 * scale,
          y,
        );
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, wavePaint);

      for (double x = 45 * scale; x < size.width; x += 150 * scale) {
        canvas.drawCircle(Offset(x, y), 4 * scale, dotPaint);
      }

      for (double x = 110 * scale; x < size.width; x += 210 * scale) {
        canvas.drawCircle(Offset(x, y + 32 * scale), 10 * scale, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WanmacRoutePatternPainter oldDelegate) => false;
}
