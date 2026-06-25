import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

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
  final isTablet = size.shortestSide >= 600;

  if (isTablet) return 680;

  return double.infinity;
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  static const List<_FAQItem> faqs = [
    _FAQItem(
      category: "Getting Started",
      icon: Icons.local_shipping_outlined,
      question: "What is WANPADI?",
      answer:
          "WANPADI is a trusted package delivery platform built to help users send items safely, quickly, and conveniently. Our process is designed around clear delivery tracking, verified handover, and secure confirmation.",
    ),
    _FAQItem(
      category: "Getting Started",
      icon: Icons.route_outlined,
      question: "How does WANPADI delivery work?",
      answer:
          "Create a delivery request, enter the pickup and drop-off details, review your delivery information, and confirm the request. A rider is then assigned to collect the package and deliver it to the receiver.",
    ),
    _FAQItem(
      category: "Security Codes",
      icon: Icons.verified_user_outlined,
      question: "What is a Pickup Code?",
      answer:
          "A Pickup Code is a unique security code given to the sender. It should only be shared with the rider after the package has been physically handed over. This confirms that the rider has collected the correct package.",
    ),
    _FAQItem(
      category: "Security Codes",
      icon: Icons.lock_person_outlined,
      question: "What is a Delivery Code?",
      answer:
          "A Delivery Code is a unique confirmation code given to the receiver. It should only be shared with the rider after the receiver has received the package. This confirms successful delivery.",
    ),
    _FAQItem(
      category: "Security Codes",
      icon: Icons.security_outlined,
      question: "Why does WANPADI use two different codes?",
      answer:
          "WANPADI uses a Pickup Code and a Delivery Code to protect both sender and receiver. The Pickup Code confirms collection from the sender, while the Delivery Code confirms final handover to the receiver.",
    ),
    _FAQItem(
      category: "Security Codes",
      icon: Icons.warning_amber_rounded,
      question: "Should I give the codes before pickup or delivery?",
      answer:
          "No. Never share a code early. The Pickup Code should only be shared after the rider has collected the package. The Delivery Code should only be shared after the receiver has received the package.",
    ),
    _FAQItem(
      category: "Delivery Safety",
      icon: Icons.inventory_2_outlined,
      question: "What items can I send with WANPADI?",
      answer:
          "You can send regular packages, documents, and personal items. Illegal, dangerous, restricted, stolen, or prohibited items are not allowed on WANPADI.",
    ),
    _FAQItem(
      category: "Delivery Safety",
      icon: Icons.track_changes_outlined,
      question: "Can I track my delivery?",
      answer:
          "Yes. WANPADI allows users to follow the progress of their delivery from pickup to final drop-off.",
    ),
    _FAQItem(
      category: "Support",
      icon: Icons.report_problem_outlined,
      question: "What should I do if there is a delivery issue?",
      answer:
          "If you notice any issue with your delivery, contact support immediately through the official support channels in the app.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final groupedFaqs = <String, List<_FAQItem>>{};

    for (final faq in faqs) {
      groupedFaqs.putIfAbsent(faq.category, () => []).add(faq);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: r(20), vertical: r(14)),
              children: [
                _topBar(context),
                SizedBox(height: r(18)),
                Text(
                  "Frequently Asked Questions",
                  style: GoogleFonts.montserrat(
                    fontSize: r(20),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: r(6)),
                Text(
                  "Clear answers about deliveries, security codes, and package handling on WANPADI.",
                  style: GoogleFonts.montserrat(
                    fontSize: r(12.5),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: r(20)),
                _trustStrip(context),
                SizedBox(height: r(26)),
                ...groupedFaqs.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, entry.key),
                      SizedBox(height: r(10)),
                      ...entry.value.map((faq) => _PremiumFAQTile(item: faq)),
                      SizedBox(height: r(18)),
                    ],
                  );
                }),
                SizedBox(height: r(18)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(r(16)),
          child: Container(
            height: r(46),
            width: r(46),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(r(16)),
              border: Border.all(color: AppColors.inputBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: r(18),
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: r(14)),
        Expanded(
          child: Text(
            "FAQs",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: r(25),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _trustStrip(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Row(
      children: [
        Expanded(
          child: _trustItem(
            context,
            icon: Icons.lock_outline_rounded,
            title: "Secure",
            subtitle: "Code verified",
          ),
        ),
        SizedBox(width: r(10)),
        Expanded(
          child: _trustItem(
            context,
            icon: Icons.route_outlined,
            title: "Trackable",
            subtitle: "Live progress",
          ),
        ),
        SizedBox(width: r(10)),
        Expanded(
          child: _trustItem(
            context,
            icon: Icons.verified_rounded,
            title: "Verified",
            subtitle: "Safe handover",
          ),
        ),
      ],
    );
  }

  Widget _trustItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r(10), vertical: r(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(20)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brandBlue, size: r(22)),
          SizedBox(height: r(8)),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: r(12.5),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: r(3)),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: r(10.5),
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Padding(
      padding: EdgeInsets.only(left: r(4)),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: r(15.5),
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
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

class _PremiumFAQTile extends StatelessWidget {
  final _FAQItem item;

  const _PremiumFAQTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      margin: EdgeInsets.only(bottom: r(12)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(22)),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(8)),
          childrenPadding: EdgeInsets.fromLTRB(r(16), 0, r(16), r(18)),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.brandBlue,
          collapsedIconColor: AppColors.textHint,
          leading: Container(
            height: r(42),
            width: r(42),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(r(15)),
            ),
            child: Icon(item.icon, color: AppColors.brandBlue, size: r(21)),
          ),
          title: Text(
            item.question,
            style: GoogleFonts.montserrat(
              fontSize: r(13.5),
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.15,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.only(left: r(56), right: r(4)),
              child: Text(
                item.answer,
                style: GoogleFonts.montserrat(
                  fontSize: r(12.4),
                  height: 1.65,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
