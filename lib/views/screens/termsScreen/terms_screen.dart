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

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  // ignore: library_private_types_in_public_api
  static const List<_TermsSection> sections = [
    _TermsSection(
      number: "01",
      title: "Use of WANPADI",
      body:
          "WANPADI provides a digital platform for requesting, managing, and tracking package deliveries. By using WANPADI, you agree to use the service lawfully, responsibly, and only for permitted delivery purposes.",
    ),
    _TermsSection(
      number: "02",
      title: "Accurate Delivery Information",
      body:
          "You are responsible for providing correct pickup details, drop-off details, receiver information, package description, and any special delivery instructions. WANPADI may not be responsible for delays or failed deliveries caused by incorrect or incomplete information.",
    ),
    _TermsSection(
      number: "03",
      title: "Pickup Code Verification",
      body:
          "The Pickup Code is used to confirm that a rider has physically collected the package from the sender. The sender must only share the Pickup Code after handing over the correct package to the assigned rider.",
    ),
    _TermsSection(
      number: "04",
      title: "Delivery Code Confirmation",
      body:
          "The Delivery Code is used to confirm that the package has been successfully received by the receiver. The receiver must only share the Delivery Code after receiving and confirming the package.",
    ),
    _TermsSection(
      number: "05",
      title: "Code Security",
      body:
          "Users must not share Pickup Codes or Delivery Codes before the correct delivery stage. Sharing a code early may incorrectly confirm pickup or delivery and may affect dispute resolution.",
    ),
    _TermsSection(
      number: "06",
      title: "Prohibited Items",
      body:
          "You must not use WANPADI to send illegal, dangerous, stolen, restricted, hazardous, or prohibited items. WANPADI reserves the right to reject, cancel, or report deliveries that violate safety or legal requirements.",
    ),
    _TermsSection(
      number: "07",
      title: "User Responsibility",
      body:
          "You agree to act honestly when creating delivery requests, communicating with riders, confirming handovers, and reporting delivery issues. Misuse of WANPADI may result in restricted access to the platform.",
    ),
    _TermsSection(
      number: "08",
      title: "Fees and Payments",
      body:
          "Delivery fees, service charges, and applicable costs may be displayed before order confirmation. By confirming a delivery request, you agree to pay the charges shown for that delivery.",
    ),
    _TermsSection(
      number: "09",
      title: "Delivery Issues and Disputes",
      body:
          "If a delivery issue occurs, users should report it through WANPADI’s official support channels as soon as possible. WANPADI may review delivery status, rider activity, pickup confirmation, delivery confirmation, and related information.",
    ),
    _TermsSection(
      number: "10",
      title: "Changes to These Terms",
      body:
          "WANPADI may update these Terms of Use from time to time. Continued use of the platform after updates means you accept the revised terms.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

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
                SizedBox(height: r(22)),
                Text(
                  "Terms of Use",
                  style: GoogleFonts.montserrat(
                    fontSize: r(24),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: r(8)),
                Text(
                  "Please review the conditions that guide the use of WANPADI delivery services.",
                  style: GoogleFonts.montserrat(
                    fontSize: r(13),
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: r(22)),
                _summaryCard(context),
                SizedBox(height: r(26)),
                Text(
                  "Agreement Details",
                  style: GoogleFonts.montserrat(
                    fontSize: r(16),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: r(12)),
                ...sections.map((section) => _TermsTile(section: section)),
                SizedBox(height: r(18)),
                _footerNote(context),
                SizedBox(height: r(28)),
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
            "Legal",
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

  Widget _summaryCard(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(26)),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: r(48),
            width: r(48),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(r(18)),
            ),
            child: Icon(
              Icons.gavel_rounded,
              color: AppColors.brandBlue,
              size: r(23),
            ),
          ),
          SizedBox(width: r(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Service Agreement",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(15),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: r(6)),
                Text(
                  "These terms explain your responsibilities when using WANPADI, including delivery requests, package safety, payments, Pickup Codes, and Delivery Codes.",
                  style: GoogleFonts.montserrat(
                    fontSize: r(12.3),
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

  Widget _footerNote(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(16)),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(r(22)),
      ),
      child: Text(
        "By continuing to use WANPADI, you confirm that you understand and agree to these Terms of Use.",
        style: GoogleFonts.montserrat(
          fontSize: r(12),
          height: 1.55,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TermsSection {
  final String number;
  final String title;
  final String body;

  const _TermsSection({
    required this.number,
    required this.title,
    required this.body,
  });
}

class _TermsTile extends StatelessWidget {
  final _TermsSection section;

  const _TermsTile({required this.section});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      margin: EdgeInsets.only(bottom: r(12)),
      padding: EdgeInsets.all(r(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(22)),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.022),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: r(42),
            width: r(42),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(r(15)),
            ),
            child: Text(
              section.number,
              style: GoogleFonts.montserrat(
                fontSize: r(12),
                fontWeight: FontWeight.w800,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          SizedBox(width: r(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: GoogleFonts.montserrat(
                    fontSize: r(13.8),
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.15,
                  ),
                ),
                SizedBox(height: r(7)),
                Text(
                  section.body,
                  style: GoogleFonts.montserrat(
                    fontSize: r(12.3),
                    height: 1.65,
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
