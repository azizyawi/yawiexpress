import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wanmac/core/theme/app_colors.dart';

double _termsScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

double _termsMaxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  if (size.shortestSide >= 600) {
    return 680;
  }

  return double.infinity;
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const List<_TermsSection> sections = [
    _TermsSection(
      number: '01',
      icon: Icons.description_outlined,
      title: 'Use of Wanpadi',
      body:
          'Wanpadi provides a digital platform for requesting, managing, and tracking package deliveries. By using Wanpadi, you agree to use the service lawfully, responsibly, and only for permitted delivery purposes.',
    ),
    _TermsSection(
      number: '02',
      icon: Icons.location_on_outlined,
      title: 'Accurate Delivery Information',
      body:
          'You are responsible for providing correct pickup details, delivery details, receiver information, package descriptions, and any special delivery instructions. Wanpadi may not be responsible for delays or failed deliveries caused by incorrect or incomplete information.',
    ),
    _TermsSection(
      number: '03',
      icon: Icons.password_rounded,
      title: 'Pickup Code Verification',
      body:
          'The Pickup Code confirms that the assigned rider has physically collected the package from the sender. The sender must only share the Pickup Code after handing the correct package to the rider.',
    ),
    _TermsSection(
      number: '04',
      icon: Icons.lock_person_outlined,
      title: 'Delivery Code Confirmation',
      body:
          'The Delivery Code confirms that the package has been received successfully. The receiver must only share the Delivery Code after receiving and confirming the package.',
    ),
    _TermsSection(
      number: '05',
      icon: Icons.security_rounded,
      title: 'Code Security',
      body:
          'Users must not share Pickup Codes or Delivery Codes before the correct delivery stage. Sharing a code early may incorrectly confirm pickup or delivery and may affect the investigation of a dispute.',
    ),
    _TermsSection(
      number: '06',
      icon: Icons.block_rounded,
      title: 'Prohibited Items',
      body:
          'You must not use Wanpadi to send illegal, dangerous, stolen, restricted, hazardous, or prohibited items. Wanpadi may reject, cancel, or report deliveries that violate safety or legal requirements.',
    ),
    _TermsSection(
      number: '07',
      icon: Icons.person_outline_rounded,
      title: 'User Responsibility',
      body:
          'You agree to act honestly when creating delivery requests, communicating with riders, confirming handovers, and reporting delivery issues. Misuse of Wanpadi may result in restricted access to the platform.',
    ),
    _TermsSection(
      number: '08',
      icon: Icons.payments_outlined,
      title: 'Fees and Payments',
      body:
          'Delivery fees, service charges, and applicable costs may be displayed before order confirmation. By confirming a delivery request, you agree to pay the charges shown for that delivery.',
    ),
    _TermsSection(
      number: '09',
      icon: Icons.support_agent_rounded,
      title: 'Delivery Issues and Disputes',
      body:
          'If a delivery issue occurs, report it through Wanpadi’s official support channels as soon as possible. Wanpadi may review the order status, rider activity, pickup confirmation, delivery confirmation, and related information.',
    ),
    _TermsSection(
      number: '10',
      icon: Icons.update_rounded,
      title: 'Changes to These Terms',
      body:
          'Wanpadi may update these Terms of Use from time to time. Continued use of the platform after an update means that you accept the revised terms.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _termsScale(context);

    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _termsMaxContentWidth(context)),
          child: ListView(
            padding: EdgeInsets.only(bottom: r(34)),
            children: [
              _TermsHeroHeader(onBack: () => Navigator.pop(context)),

              Padding(
                padding: EdgeInsets.fromLTRB(r(20), r(26), r(20), 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AgreementSummaryCard(),

                    SizedBox(height: r(30)),

                    Padding(
                      padding: EdgeInsets.only(left: r(2), bottom: r(11)),
                      child: Text(
                        'Agreement details',
                        style: GoogleFonts.montserrat(
                          fontSize: r(14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(r(22)),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Column(
                        children: List.generate(sections.length, (index) {
                          return _TermsTile(
                            section: sections[index],
                            showDivider: index != sections.length - 1,
                          );
                        }),
                      ),
                    ),

                    SizedBox(height: r(22)),

                    const _AcceptanceNote(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsHeroHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _TermsHeroHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = _termsScale(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    double r(double value) => value * s;

    return SizedBox(
      height: topPadding + r(250),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.brandBlueDark,
              child: CustomPaint(painter: _TermsHeaderPainter()),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              r(20),
              topPadding + r(14),
              r(20),
              r(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withOpacity(0.14),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onBack,
                        customBorder: const CircleBorder(),
                        child: Container(
                          height: r(46),
                          width: r(46),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: r(18),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: r(14)),

                    Expanded(
                      child: Text(
                        'Terms of Use',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: r(24),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: r(78),
                      width: r(78),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(r(24)),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.gavel_rounded,
                        size: r(38),
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(width: r(17)),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service agreement',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: r(20),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),

                          SizedBox(height: r(7)),

                          Text(
                            'Understand the rules and responsibilities that guide your use of Wanpadi.',
                            style: GoogleFonts.montserrat(
                              fontSize: r(11.5),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.76),
                            ),
                          ),

                          SizedBox(height: r(11)),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r(11),
                              vertical: r(6),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(r(50)),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  color: Colors.white,
                                  size: r(13),
                                ),

                                SizedBox(width: r(5)),

                                Text(
                                  'Clear and transparent',
                                  style: GoogleFonts.montserrat(
                                    fontSize: r(10.5),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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

class _AgreementSummaryCard extends StatelessWidget {
  const _AgreementSummaryCard();

  @override
  Widget build(BuildContext context) {
    final s = _termsScale(context);

    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(22)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: r(48),
            width: r(48),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(r(16)),
            ),
            child: Icon(
              Icons.article_outlined,
              color: AppColors.brandBlueDark,
              size: r(24),
            ),
          ),

          SizedBox(width: r(14)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before using Wanpadi',
                  style: GoogleFonts.montserrat(
                    fontSize: r(14.5),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),

                SizedBox(height: r(6)),

                Text(
                  'These terms explain your responsibilities when creating deliveries, handling packages, making payments, and sharing Pickup or Delivery Codes.',
                  style: GoogleFonts.montserrat(
                    fontSize: r(12),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsTile extends StatelessWidget {
  final _TermsSection section;
  final bool showDivider;

  const _TermsTile({required this.section, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final s = _termsScale(context);

    double r(double value) => value * s;

    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.fromLTRB(r(14), r(7), r(12), r(7)),
            childrenPadding: EdgeInsets.fromLTRB(r(68), 0, r(18), r(19)),
            iconColor: AppColors.brandBlueDark,
            collapsedIconColor: AppColors.textHint,
            leading: Container(
              height: r(40),
              width: r(40),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(r(13)),
              ),
              child: Icon(
                section.icon,
                size: r(20),
                color: AppColors.brandBlueDark,
              ),
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: r(1)),
                  child: Text(
                    section.number,
                    style: GoogleFonts.montserrat(
                      fontSize: r(10.5),
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),

                SizedBox(width: r(9)),

                Expanded(
                  child: Text(
                    section.title,
                    style: GoogleFonts.montserrat(
                      fontSize: r(13),
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  section.body,
                  style: GoogleFonts.montserrat(
                    fontSize: r(12),
                    height: 1.65,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: r(68)),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.inputBorder,
            ),
          ),
      ],
    );
  }
}

class _AcceptanceNote extends StatelessWidget {
  const _AcceptanceNote();

  @override
  Widget build(BuildContext context) {
    final s = _termsScale(context);

    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(17)),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(r(20)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: r(38),
            width: r(38),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(r(12)),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: r(20),
              color: AppColors.brandBlueDark,
            ),
          ),

          SizedBox(width: r(13)),

          Expanded(
            child: Text(
              'By continuing to use Wanpadi, you confirm that you understand and agree to these Terms of Use.',
              style: GoogleFonts.montserrat(
                fontSize: r(11.8),
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection {
  final String number;
  final IconData icon;
  final String title;
  final String body;

  const _TermsSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _TermsHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final softLine = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    final dashedLine = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final faintLine = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final route = Path()
      ..moveTo(width * 0.18, height * 0.94)
      ..cubicTo(
        width * 0.34,
        height * 0.55,
        width * 0.68,
        height * 0.85,
        width * 1.04,
        height * 0.29,
      );

    canvas.drawPath(route, softLine);
    _drawDashedPath(canvas, route, dashedLine);

    _drawRouteNode(canvas, Offset(width * 0.34, height * 0.73));

    _drawRouteNode(canvas, Offset(width * 0.68, height * 0.60));

    _drawRouteNode(canvas, Offset(width * 0.92, height * 0.37));

    final document = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.71, height * 0.15, width * 0.21, height * 0.28),
      const Radius.circular(18),
    );

    canvas.drawRRect(document, faintLine);

    canvas.drawLine(
      Offset(width * 0.75, height * 0.24),
      Offset(width * 0.87, height * 0.24),
      faintLine,
    );

    canvas.drawLine(
      Offset(width * 0.75, height * 0.31),
      Offset(width * 0.88, height * 0.31),
      faintLine,
    );

    canvas.drawLine(
      Offset(width * 0.75, height * 0.37),
      Offset(width * 0.84, height * 0.37),
      faintLine,
    );

    canvas.drawLine(
      Offset(width * 0.52, height * 0.18),
      Offset(width * 0.52, height * 0.29),
      dashedLine,
    );

    canvas.drawLine(
      Offset(width * 0.47, height * 0.235),
      Offset(width * 0.57, height * 0.235),
      dashedLine,
    );

    final backgroundCircle = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(width * 0.90, height * 0.13),
      width * 0.19,
      backgroundCircle,
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end = (distance + 12).clamp(0.0, metric.length);

        canvas.drawPath(metric.extractPath(distance, end), paint);

        distance += 24;
      }
    }
  }

  void _drawRouteNode(Canvas canvas, Offset center) {
    final outer = Paint()..color = Colors.white.withOpacity(0.08);

    final inner = Paint()..color = Colors.white.withOpacity(0.28);

    canvas.drawCircle(center, 10, outer);
    canvas.drawCircle(center, 4, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
