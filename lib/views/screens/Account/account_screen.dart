import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/views/screens/FAQ/faq_screen.dart';
import 'package:wanmac/views/screens/profile_detail/profile_detail_screen.dart';
import 'package:wanmac/views/screens/referralScreen/referral_screen.dart';
import 'package:wanmac/views/screens/termsScreen/terms_screen.dart';

double _scale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

double _maxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  if (size.shortestSide >= 600) {
    return 680;
  }

  return double.infinity;
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String firstName = '';
  String lastName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      firstName = prefs.getString('firstName') ?? '';
      lastName = prefs.getString('lastName') ?? '';
    });
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) {
      return "User";
    }

    return "$firstName $lastName".trim();
  }

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse("https://www.wanpadi.com/privacy");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);

    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,

      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),

          child: ListView(
            padding: EdgeInsets.only(bottom: r(30)),

            children: [
              _AccountHeader(name: fullName),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: r(20)),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    SizedBox(height: r(24)),

                    _sectionTitle(context, "Personal"),

                    _AccountTile(
                      icon: Icons.person_outline_rounded,
                      title: "Profile Details",

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileDetailsScreen(),
                          ),
                        );
                      },
                    ),

                    _AccountTile(
                      icon: Icons.people_outline_rounded,
                      title: "Referral Program",

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReferralScreen(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: r(22)),

                    _sectionTitle(context, "Explore"),

                    _AccountTile(
                      icon: Icons.help_outline_rounded,
                      title: "FAQs",

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FAQScreen()),
                        );
                      },
                    ),

                    _AccountTile(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",

                      onTap: _openPrivacyPolicy,
                    ),

                    _AccountTile(
                      icon: Icons.description_outlined,
                      title: "Terms of Use",

                      showDivider: false,

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Text(
        title,

        style: _T.text(context, 15, FontWeight.w700, AppColors.textSecondary),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final String name;

  const _AccountHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return SizedBox(
      height: r(220),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(color: AppColors.brandBlueDark),
              child: CustomPaint(painter: _AccountHeaderPainter()),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(r(20), r(32), r(20), r(20)),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Account",
                  style: _T.text(context, 28, FontWeight.w800, Colors.white),
                ),

                const Spacer(),

                Row(
                  children: [
                    Container(
                      width: r(86),
                      height: r(86),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        border: Border.all(
                          color: Colors.white.withOpacity(.9),
                          width: 3,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/profile_avata.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    SizedBox(width: r(16)),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            name,

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: _T.text(
                              context,
                              20,
                              FontWeight.w800,
                              Colors.white,
                            ),
                          ),

                          SizedBox(height: r(8)),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r(12),
                              vertical: r(6),
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.14),

                              borderRadius: BorderRadius.circular(50),

                              border: Border.all(
                                color: Colors.white.withOpacity(.18),
                              ),
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: r(13),
                                  color: Colors.white,
                                ),

                                SizedBox(width: r(5)),

                                Text(
                                  "Verified customer",

                                  style: _T.text(
                                    context,
                                    11,
                                    FontWeight.w700,
                                    Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _AccountHeaderPainter extends CustomPainter {
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
      ..color = Colors.white.withOpacity(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final faint = Paint()
      ..color = Colors.white.withOpacity(.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // large abstract wave

    final wave = Path()
      ..moveTo(width * .28, height * .88)
      ..cubicTo(
        width * .42,
        height * .45,

        width * .72,
        height * .85,

        width * 1.05,
        height * .30,
      );

    canvas.drawPath(wave, soft);

    _drawDashed(canvas, wave, line);

    // abstract floating account card

    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * .68, height * .20, width * .25, height * .32),

      const Radius.circular(18),
    );

    canvas.drawRRect(card, faint);

    // small lines inside card

    canvas.drawLine(
      Offset(width * .72, height * .30),

      Offset(width * .86, height * .30),

      faint,
    );

    canvas.drawLine(
      Offset(width * .72, height * .37),

      Offset(width * .90, height * .37),

      faint,
    );

    // route nodes

    _node(canvas, Offset(width * .40, height * .70));

    _node(canvas, Offset(width * .75, height * .53));

    _node(canvas, Offset(width * .92, height * .36));

    // small plus

    canvas.drawLine(
      Offset(width * .55, height * .25),
      Offset(width * .55, height * .35),
      line,
    );

    canvas.drawLine(
      Offset(width * .50, height * .30),
      Offset(width * .60, height * .30),
      line,
    );

    // background circle

    final circle = Paint()
      ..color = Colors.white.withOpacity(.035)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(width * .88, height * .15), width * .18, circle);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end = (distance + 12).clamp(0.0, metric.length);

        canvas.drawPath(metric.extractPath(distance, end), paint);

        distance += 24;
      }
    }
  }

  void _node(Canvas canvas, Offset center) {
    final outer = Paint()..color = Colors.white.withOpacity(.08);

    final inner = Paint()..color = Colors.white.withOpacity(.25);

    canvas.drawCircle(center, 10, outer);

    canvas.drawCircle(center, 4, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool showDivider;

  const _AccountTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);

    double r(double value) => value * s;

    return Container(
      margin: EdgeInsets.only(bottom: r(2)),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(r(16)),
      ),

      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(r(16)),

            onTap: onTap,

            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(16)),

              child: Row(
                children: [
                  Container(
                    width: r(42),

                    height: r(42),

                    decoration: BoxDecoration(
                      color: AppColors.inputFill,

                      borderRadius: BorderRadius.circular(r(13)),
                    ),

                    child: Icon(
                      icon,

                      size: r(22),

                      color: AppColors.brandBlueDark,
                    ),
                  ),

                  SizedBox(width: r(14)),

                  Expanded(
                    child: Text(
                      title,

                      style: _T.text(
                        context,

                        15,

                        FontWeight.w600,

                        AppColors.textPrimary,
                      ),
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,

                    size: r(22),

                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),

          if (showDivider)
            Padding(
              padding: EdgeInsets.only(left: r(70)),

              child: Divider(
                height: 1,

                thickness: 1,

                color: AppColors.inputBorder,
              ),
            ),
        ],
      ),
    );
  }
}

class _T {
  static TextStyle text(
    BuildContext context,

    double size,

    FontWeight weight,

    Color color, {

    double? height,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size * _scale(context),

      fontWeight: weight,

      color: color,

      height: height,

      letterSpacing: -0.08,
    );
  }
}
