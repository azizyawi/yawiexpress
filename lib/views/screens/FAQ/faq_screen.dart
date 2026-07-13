import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wanmac/core/theme/app_colors.dart';

double _faqScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

double _faqMaxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  if (size.shortestSide >= 600) {
    return 680;
  }

  return double.infinity;
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  static const List<_FAQItem> faqs = [
    _FAQItem(
      category: 'Getting Started',
      icon: Icons.two_wheeler_rounded,
      question: 'What is Wanpadi?',
      answer:
          'Wanpadi is a trusted delivery platform that connects customers with verified riders. You can create a delivery, track its progress, and confirm pickup and delivery securely.',
    ),
    _FAQItem(
      category: 'Getting Started',
      icon: Icons.route_outlined,
      question: 'How does a Wanpadi delivery work?',
      answer:
          'Create a delivery request, enter the pickup and delivery details, review the information, and confirm your request. A nearby rider will accept the delivery, collect the package, and take it to the receiver.',
    ),
    _FAQItem(
      category: 'Getting Started',
      icon: Icons.schedule_rounded,
      question: 'How long does delivery take?',
      answer:
          'Delivery time depends on the pickup location, destination, traffic, weather, and rider availability. You can follow the delivery progress directly from the order screen.',
    ),
    _FAQItem(
      category: 'Security Codes',
      icon: Icons.password_rounded,
      question: 'What is a Pickup Code?',
      answer:
          'A Pickup Code is a unique security code given to the sender. Share it with the rider only after the package has been physically handed over. It confirms that the rider collected the correct package.',
    ),
    _FAQItem(
      category: 'Security Codes',
      icon: Icons.lock_person_outlined,
      question: 'What is a Delivery Code?',
      answer:
          'A Delivery Code is a confirmation code given to the receiver. It should only be shared with the rider after the receiver has received and checked the package.',
    ),
    _FAQItem(
      category: 'Security Codes',
      icon: Icons.verified_user_outlined,
      question: 'Why does Wanpadi use two codes?',
      answer:
          'The Pickup Code protects the sender by confirming package collection. The Delivery Code protects the receiver by confirming final delivery. Together, they provide a safer handover process.',
    ),
    _FAQItem(
      category: 'Security Codes',
      icon: Icons.warning_amber_rounded,
      question: 'Should I share a code before handover?',
      answer:
          'No. Never share a security code early. Share the Pickup Code only after the rider has collected the package, and share the Delivery Code only after the receiver has received it.',
    ),
    _FAQItem(
      category: 'Delivery and Safety',
      icon: Icons.inventory_2_outlined,
      question: 'What items can I send?',
      answer:
          'You can send regular packages, documents, food, groceries, and other permitted personal or business items. Illegal, dangerous, stolen, restricted, or prohibited items are not allowed.',
    ),
    _FAQItem(
      category: 'Delivery and Safety',
      icon: Icons.location_searching_rounded,
      question: 'Can I track my delivery?',
      answer:
          'Yes. Open the order screen to see the current delivery status and follow the rider’s progress from pickup to final delivery.',
    ),
    _FAQItem(
      category: 'Delivery and Safety',
      icon: Icons.person_pin_circle_outlined,
      question: 'Who delivers my package?',
      answer:
          'Your package is delivered by a Wanpadi rider who has completed the platform’s onboarding and approval process.',
    ),
    _FAQItem(
      category: 'Support',
      icon: Icons.support_agent_rounded,
      question: 'What should I do if there is a problem?',
      answer:
          'Open the affected order and contact Wanpadi support with your order ID and a clear explanation of the issue. This helps the support team investigate more quickly.',
    ),
    _FAQItem(
      category: 'Support',
      icon: Icons.receipt_long_outlined,
      question: 'Where can I find my order ID?',
      answer:
          'Open the Orders screen and select the affected delivery. Your order ID will be displayed inside the order details.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _faqScale(context);

    double r(double value) => value * s;

    final groupedFaqs = <String, List<_FAQItem>>{};

    for (final faq in faqs) {
      groupedFaqs.putIfAbsent(faq.category, () => <_FAQItem>[]);

      groupedFaqs[faq.category]!.add(faq);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _faqMaxContentWidth(context)),
          child: ListView(
            padding: EdgeInsets.only(bottom: r(34)),
            children: [
              _FAQHeroHeader(onBack: () => Navigator.pop(context)),

              Padding(
                padding: EdgeInsets.fromLTRB(r(20), r(26), r(20), 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HelpSummaryCard(),

                    SizedBox(height: r(30)),

                    ...groupedFaqs.entries.map((entry) {
                      return _FAQSection(title: entry.key, items: entry.value);
                    }),

                    SizedBox(height: r(8)),
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

class _FAQHeroHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _FAQHeroHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = _faqScale(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    double r(double value) => value * s;

    return SizedBox(
      height: topPadding + r(250),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.brandBlueDark,
              child: CustomPaint(painter: _FAQHeaderPainter()),
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
                        'Help Centre',
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
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.two_wheeler_rounded,
                        size: r(40),
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(width: r(17)),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How can we help?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: r(21),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),

                          SizedBox(height: r(7)),

                          Text(
                            'Find clear answers about deliveries, tracking, security codes and package safety.',
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
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: r(13),
                                ),

                                SizedBox(width: r(5)),

                                Text(
                                  'Quick answers',
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

class _HelpSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = _faqScale(context);

    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(17)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(20)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.lock_outline_rounded,
              title: 'Secure',
              subtitle: 'Code verified',
            ),
          ),

          _VerticalDivider(),

          Expanded(
            child: _SummaryItem(
              icon: Icons.location_searching_rounded,
              title: 'Trackable',
              subtitle: 'Live progress',
            ),
          ),

          _VerticalDivider(),

          Expanded(
            child: _SummaryItem(
              icon: Icons.two_wheeler_rounded,
              title: 'Reliable',
              subtitle: 'Verified riders',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final s = _faqScale(context);

    double r(double value) => value * s;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: r(38),
          width: r(38),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(r(12)),
          ),
          child: Icon(icon, size: r(19), color: AppColors.brandBlueDark),
        ),

        SizedBox(height: r(8)),

        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: r(11.5),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: r(3)),

        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: r(9.5),
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = _faqScale(context);

    double r(double value) => value * s;

    return Container(
      height: r(54),
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: r(5)),
      color: AppColors.inputBorder,
    );
  }
}

class _FAQSection extends StatelessWidget {
  final String title;
  final List<_FAQItem> items;

  const _FAQSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final s = _faqScale(context);

    double r(double value) => value * s;

    return Padding(
      padding: EdgeInsets.only(bottom: r(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: r(2), bottom: r(11)),
            child: Text(
              title,
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
              borderRadius: BorderRadius.circular(r(20)),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              children: List.generate(items.length, (index) {
                return _CleanFAQTile(
                  item: items[index],
                  showDivider: index != items.length - 1,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanFAQTile extends StatelessWidget {
  final _FAQItem item;
  final bool showDivider;

  const _CleanFAQTile({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final s = _faqScale(context);

    double r(double value) => value * s;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Column(
        children: [
          ExpansionTile(
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
                item.icon,
                size: r(20),
                color: AppColors.brandBlueDark,
              ),
            ),
            title: Text(
              item.question,
              style: GoogleFonts.montserrat(
                fontSize: r(13),
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.answer,
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
      ),
    );
  }
}

class _FAQItem {
  final String category;
  final IconData icon;
  final String question;
  final String answer;

  const _FAQItem({
    required this.category,
    required this.icon,
    required this.question,
    required this.answer,
  });
}

class _FAQHeaderPainter extends CustomPainter {
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
      ..moveTo(width * 0.20, height * 0.92)
      ..cubicTo(
        width * 0.34,
        height * 0.56,
        width * 0.66,
        height * 0.84,
        width * 1.04,
        height * 0.30,
      );

    canvas.drawPath(route, softLine);
    _drawDashedPath(canvas, route, dashedLine);

    _drawRouteNode(canvas, Offset(width * 0.34, height * 0.73));

    _drawRouteNode(canvas, Offset(width * 0.67, height * 0.61));

    _drawRouteNode(canvas, Offset(width * 0.92, height * 0.38));

    final helpBubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.72, height * 0.16, width * 0.19, height * 0.24),
      const Radius.circular(18),
    );

    canvas.drawRRect(helpBubble, faintLine);

    canvas.drawCircle(
      Offset(width * 0.815, height * 0.235),
      width * 0.018,
      faintLine,
    );

    canvas.drawLine(
      Offset(width * 0.79, height * 0.30),
      Offset(width * 0.84, height * 0.30),
      faintLine,
    );

    canvas.drawLine(
      Offset(width * 0.53, height * 0.18),
      Offset(width * 0.53, height * 0.29),
      dashedLine,
    );

    canvas.drawLine(
      Offset(width * 0.48, height * 0.235),
      Offset(width * 0.58, height * 0.235),
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
