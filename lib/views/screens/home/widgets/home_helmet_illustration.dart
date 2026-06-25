import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class HomeHelmetIllustration extends StatefulWidget {
  const HomeHelmetIllustration({super.key});

  @override
  State<HomeHelmetIllustration> createState() => _HomeHelmetIllustrationState();
}

class _HomeHelmetIllustrationState extends State<HomeHelmetIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  bool _isShortHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 700;
  }

  double _scale(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    if (isTablet && isLandscape) return 1.35;
    if (isTablet) return 1.22;
    if (isLandscape || isShort) return 0.88;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);

    double s(double value) => value * scale;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        final floatY = math.sin(t * 2 * math.pi) * s(4);
        final shadowScale =
            1 - (0.06 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)));
        final parcelTilt = math.sin((t * 2 * math.pi) + 0.8) * 0.05;
        final shimmerX = math.sin(t * 2 * math.pi) * s(6);

        return SizedBox(
          width: s(102),
          height: s(112),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: s(8),
                left: s(14),
                child: Transform.scale(
                  scale: shadowScale,
                  child: Container(
                    width: s(72),
                    height: s(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: s(20) + floatY,
                left: s(18),
                child: Container(
                  width: s(66),
                  height: s(66),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD95D), Color(0xFFFFB800)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(s(34)),
                  ),
                ),
              ),
              Positioned(
                bottom: s(28) + floatY,
                left: s(27),
                child: Container(
                  width: s(44),
                  height: s(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B4D),
                    borderRadius: BorderRadius.circular(s(14)),
                  ),
                ),
              ),
              Positioned(
                bottom: s(31) + floatY,
                left: s(31),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(s(10)),
                  child: Stack(
                    children: [
                      Container(
                        width: s(36),
                        height: s(17),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.16),
                              Colors.white.withOpacity(0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(shimmerX, 0),
                        child: Container(
                          width: s(8),
                          height: s(17),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.18),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: s(19) + floatY,
                left: s(24),
                child: Container(
                  width: s(50),
                  height: s(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B4D),
                    borderRadius: BorderRadius.circular(s(20)),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: s(30) + floatY,
                child: Transform.rotate(
                  angle: parcelTilt,
                  child: Container(
                    width: s(26),
                    height: s(36),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlueDark.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(s(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
