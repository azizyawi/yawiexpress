import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isTablet = size.shortestSide >= 600;
    final isShort = size.height < 700;

    if (isTablet) return 1.10;
    if (isShort) return 0.92;

    return 1.0;
  }

  Future<String> _getReferralCode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('referralCode') ?? '---';
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    if (code == '---' || code == '...') return;

    await Clipboard.setData(ClipboardData(text: code));

    if (context.mounted) {
      AppSnackBar.show(
        context,
        message: "Referral code copied",
        type: AppSnackBarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);

    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        top: false,

        child: FutureBuilder<String>(
          future: _getReferralCode(),

          builder: (context, snapshot) {
            final code = snapshot.data ?? "...";

            return ListView(
              padding: EdgeInsets.only(bottom: r(30)),

              children: [
                _ReferralHeader(),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r(20)),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      SizedBox(height: r(26)),

                      Text(
                        "Invite friends.\nEarn rewards.",

                        style: GoogleFonts.montserrat(
                          fontSize: r(27),

                          fontWeight: FontWeight.w800,

                          height: 1.15,

                          color: AppColors.textPrimary,
                        ),
                      ),

                      SizedBox(height: r(10)),

                      Text(
                        "Share Wanpadi with your friends and earn when they complete their first delivery.",

                        style: GoogleFonts.montserrat(
                          fontSize: r(13),

                          fontWeight: FontWeight.w500,

                          height: 1.5,

                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: r(28)),

                      Container(
                        width: double.infinity,

                        padding: EdgeInsets.all(r(24)),

                        decoration: BoxDecoration(
                          color: AppColors.surface,

                          borderRadius: BorderRadius.circular(r(24)),

                          border: Border.all(color: AppColors.inputBorder),
                        ),

                        child: Column(
                          children: [
                            Text(
                              "Your referral code",

                              style: GoogleFonts.montserrat(
                                fontSize: r(12),

                                fontWeight: FontWeight.w700,

                                color: AppColors.textSecondary,
                              ),
                            ),

                            SizedBox(height: r(12)),

                            Text(
                              code,

                              style: GoogleFonts.montserrat(
                                fontSize: r(30),

                                fontWeight: FontWeight.w900,

                                letterSpacing: 2,

                                color: AppColors.brandBlueDark,
                              ),
                            ),

                            SizedBox(height: r(10)),

                            Text(
                              "Earn ₦500 for every successful referral",

                              textAlign: TextAlign.center,

                              style: GoogleFonts.montserrat(
                                fontSize: r(12),

                                fontWeight: FontWeight.w600,

                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: r(18)),

                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              title: "Copy",

                              primary: true,

                              onTap: () {
                                _copyCode(context, code);
                              },
                            ),
                          ),

                          SizedBox(width: r(12)),

                          Expanded(
                            child: _ActionButton(
                              title: "Share",

                              primary: false,

                              onTap: () {},
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: r(28)),
                      Container(
                        width: double.infinity,

                        padding: EdgeInsets.all(r(20)),

                        decoration: BoxDecoration(
                          color: AppColors.surface,

                          borderRadius: BorderRadius.circular(r(22)),

                          border: Border.all(color: AppColors.inputBorder),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              "How it works",

                              style: GoogleFonts.montserrat(
                                fontSize: r(15),

                                fontWeight: FontWeight.w800,

                                color: AppColors.textPrimary,
                              ),
                            ),

                            SizedBox(height: r(18)),

                            const _StepItem(
                              number: "1",
                              text: "Share your referral code",
                            ),

                            const _StepItem(
                              number: "2",
                              text:
                                  "Your friend completes their first delivery",
                            ),

                            const _StepItem(
                              number: "3",
                              text: "Your reward is added automatically",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReferralHeader extends StatelessWidget {
  const _ReferralHeader();

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width < 600 ? 1.0 : 1.10;

    double r(double value) => value * s;

    return SizedBox(
      height: r(190),

      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.brandBlueDark,

              child: CustomPaint(painter: _ReferralPainter()),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(r(20), r(40), r(20), r(20)),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Referral",

                  style: GoogleFonts.montserrat(
                    fontSize: r(28),

                    fontWeight: FontWeight.w800,

                    color: Colors.white,
                  ),
                ),

                const Spacer(),

                Row(
                  children: [
                    Container(
                      height: r(48),

                      width: r(48),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.14),

                        borderRadius: BorderRadius.circular(r(16)),
                      ),

                      child: Icon(
                        Icons.card_giftcard_rounded,

                        color: Colors.white,

                        size: r(25),
                      ),
                    ),

                    SizedBox(width: r(14)),

                    Expanded(
                      child: Text(
                        "Invite people and earn rewards",

                        style: GoogleFonts.montserrat(
                          fontSize: r(14),

                          fontWeight: FontWeight.w700,

                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;

    final height = size.height;

    final soft = Paint()
      ..color = Colors.white.withOpacity(.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final line = Paint()
      ..color = Colors.white.withOpacity(.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(width * .20, height * .90)
      ..cubicTo(
        width * .42,
        height * .35,

        width * .70,
        height * .85,

        width * 1.05,
        height * .25,
      );

    canvas.drawPath(path, soft);

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end = (distance + 12).clamp(0.0, metric.length);

        canvas.drawPath(metric.extractPath(distance, end), line);

        distance += 24;
      }
    }

    final circlePaint = Paint()..color = Colors.white.withOpacity(.06);

    canvas.drawCircle(
      Offset(width * .85, height * .25),

      width * .18,

      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActionButton extends StatelessWidget {
  final String title;

  final bool primary;

  final VoidCallback onTap;

  const _ActionButton({
    required this.title,

    required this.primary,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width < 600 ? 1.0 : 1.10;

    double r(double value) => value * s;

    return Material(
      color: primary ? AppColors.brandBlueDark : AppColors.surface,

      borderRadius: BorderRadius.circular(r(16)),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(r(16)),

        child: Container(
          height: r(52),

          alignment: Alignment.center,

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r(16)),

            border: primary ? null : Border.all(color: AppColors.inputBorder),
          ),

          child: Text(
            title,

            style: GoogleFonts.montserrat(
              fontSize: r(13),

              fontWeight: FontWeight.w800,

              color: primary ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;

  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width < 600 ? 1.0 : 1.10;

    double r(double value) => value * s;

    return Padding(
      padding: EdgeInsets.only(bottom: r(14)),

      child: Row(
        children: [
          Container(
            width: r(28),

            height: r(28),

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: AppColors.brandBlueDark.withOpacity(.10),

              shape: BoxShape.circle,
            ),

            child: Text(
              number,

              style: GoogleFonts.montserrat(
                fontSize: r(12),

                fontWeight: FontWeight.w800,

                color: AppColors.brandBlueDark,
              ),
            ),
          ),

          SizedBox(width: r(12)),

          Expanded(
            child: Text(
              text,

              style: GoogleFonts.montserrat(
                fontSize: r(13),

                fontWeight: FontWeight.w500,

                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
