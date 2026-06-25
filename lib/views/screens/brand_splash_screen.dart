import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/views/screens/WelcomeScreen/welcome_screen.dart';

class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoWidthAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _bikeOpacityAnimation;
  late Animation<double> _bikeScaleAnimation;
  late Animation<double> _bikeProgressAnimation;

  static const Color splashBlue = Color(0xFF061F70);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _logoWidthAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeInOutCubic),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.50, curve: Curves.easeInOut),
      ),
    );

    _bikeOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.45, curve: Curves.easeIn),
      ),
    );

    _bikeScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _bikeProgressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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

    final double largeLogoWidth = (screenWidth * 0.72).clamp(250.0, 420.0);
    final double smallLogoWidth = (screenWidth * 0.52).clamp(190.0, 300.0);

    final double currentLogoWidth =
        largeLogoWidth -
        ((largeLogoWidth - smallLogoWidth) * _logoWidthAnimation.value);

    final double titleFontSize = _responsiveValue(
      width: screenWidth,
      phone: 24,
      tablet: 28,
      desktop: 30,
    );

    final double bikeWidth = _responsiveValue(
      width: screenWidth,
      phone: shortestSide * 0.44,
      tablet: shortestSide * 0.34,
      desktop: 220,
    ).clamp(145.0, 240.0);

    final double bikeStartX = screenWidth;
    final double bikeEndX = -bikeWidth;

    final double bottomSpacing = _responsiveValue(
      width: screenWidth,
      phone: 85,
      tablet: 110,
      desktop: 130,
    );

    final double bikeY = screenHeight - bikeWidth - bottomSpacing;

    final double roadBottom = _responsiveValue(
      width: screenWidth,
      phone: 125,
      tablet: 155,
      desktop: 175,
    );

    final double textLift = _responsiveValue(
      width: screenWidth,
      phone: 70,
      tablet: 82,
      desktop: 90,
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

              SafeArea(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double bikeX =
                        bikeStartX +
                        ((bikeEndX - bikeStartX) *
                            _bikeProgressAnimation.value);

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/wanmac_logo_white.png',
                                    width: currentLogoWidth,
                                    fit: BoxFit.contain,
                                  ),
                                  Transform.translate(
                                    offset: Offset(0, -textLift),
                                    child: Opacity(
                                      opacity: _textOpacityAnimation.value,
                                      child: Text(
                                        'WANMAC',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                          left: bikeX + (bikeWidth * 0.17),
                          top: bikeY + (bikeWidth * 0.54),
                          child: Opacity(
                            opacity: _bikeOpacityAnimation.value * 0.24,
                            child: Container(
                              width: bikeWidth * 0.54,
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
                            opacity: _bikeOpacityAnimation.value,
                            child: Transform.scale(
                              scale: _bikeScaleAnimation.value,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: Image.asset(
                                  'assets/images/wanmac_bike.png',
                                  width: bikeWidth,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
