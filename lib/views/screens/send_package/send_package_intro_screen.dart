// Place in lib/views/screens/send_package/send_package_intro_screen.dart.
// Open SendPackageIntroScreen from your home send-package button.
// Assets must be registered under flutter/assets in pubspec.yaml.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'send_package_screen.dart';

class SendPackageIntroScreen extends StatefulWidget {
  const SendPackageIntroScreen({super.key});

  @override
  State<SendPackageIntroScreen> createState() => _SendPackageIntroScreenState();
}

class _SendPackageIntroScreenState extends State<SendPackageIntroScreen> {
  bool _opening = false;

  void _continue() {
    if (_opening) return;
    setState(() => _opening = true);
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => const SendPackageScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.brandBlueDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.brandBlueDark,
        body: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _RoutePainter())),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(constraints.maxWidth, 600.0);
                  final titleSize = (width * .108).clamp(32.0, 56.0).toDouble();
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/wanmac_logo_white.png',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                ),
                                const SizedBox(width: 6),
                                Text('Wanpadi', style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                )),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(context).maybePop(),
                                  tooltip: 'Close',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.brandBlueDark,
                                    minimumSize: const Size(48, 48),
                                  ),
                                  icon: const Icon(Icons.close_rounded, size: 25),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, body) => SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: body.maxHeight),
                                  child: Column(
                                    children: [
                                      SizedBox(height: (body.maxHeight * .09).clamp(28.0, 64.0).toDouble()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18),
                                        child: Text.rich(
                                          TextSpan(children: const [
                                            TextSpan(text: 'Your package.\nAnywhere in\nBenin. '),
                                            TextSpan(text: 'Sorted.', style: TextStyle(color: Color(0xFFFFD65A))),
                                          ]),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: titleSize,
                                            height: 1.13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -1.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 26),
                                        child: Text(
                                          'Tell us where it’s going. We’ll connect you with a rider, and you can follow every move in the app.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: 15,
                                            height: 1.6,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Image.asset(
                                        'assets/images/welcome_hand.png',
                                        width: width,
                                        height: math.max(width * .67, body.maxHeight * .43),
                                        fit: BoxFit.contain,
                                        excludeFromSemantics: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _opening ? null : _continue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.brandBlueDark,
                                  disabledBackgroundColor: Colors.white,
                                  disabledForegroundColor: AppColors.brandBlueDark,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(58),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'Let’s send your package',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 850);
    final paint = Paint()
      ..color = const Color(0x12FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final routes = [
      Path()..moveTo(95, -30)..lineTo(8, 337)..quadraticBezierTo(0, 362, -24, 376),
      Path()..moveTo(225, -30)..lineTo(143, 307)..quadraticBezierTo(132, 342, 168, 331)..lineTo(427, 258),
      Path()..moveTo(421, 377)..lineTo(218, 432)..quadraticBezierTo(191, 438, 185, 465)..lineTo(98, 861),
      Path()..moveTo(-25, 496)..lineTo(61, 471)..quadraticBezierTo(103, 460, 94, 505)..lineTo(10, 869),
      Path()..moveTo(157, 864)..lineTo(422, 783),
    ];
    for (final route in routes) {
      canvas.drawPath(route, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => false;
}