import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  static const Color brandColor = Color(0xFF1C1A99);

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

  Future<String> _getReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('referralCode') ?? '---';
  }

  void _copyCode(BuildContext context, String code) async {
    if (code == '---' || code == '...') return;

    await Clipboard.setData(ClipboardData(text: code));

    if (context.mounted) {
      AppSnackBar.show(
        context,
        message: 'Referral code copied',
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
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Referral',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: r(15),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: r(18),
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<String>(
        future: _getReferralCode(),
        builder: (context, snapshot) {
          final displayCode = snapshot.data ?? '...';

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _maxContentWidth(context),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(r(22), r(10), r(22), r(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: r(8)),
                      Text(
                        'Invite & earn',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: r(26),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: r(8)),
                      Text(
                        'Share your code and earn when they complete their first delivery.',
                        style: GoogleFonts.montserrat(
                          fontSize: r(13),
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: r(28)),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: r(20),
                          vertical: r(24),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(r(24)),
                          border: Border.all(
                            color: brandColor.withOpacity(0.10),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Your code',
                              style: GoogleFonts.montserrat(
                                fontSize: r(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: r(12)),
                            Text(
                              displayCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: r(28),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: brandColor,
                              ),
                            ),
                            SizedBox(height: r(10)),
                            Text(
                              'Earn ₦500 per successful referral',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: r(12),
                                fontWeight: FontWeight.w500,
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
                            child: _PrimaryButton(
                              label: 'Copy',
                              onTap: () => _copyCode(context, displayCode),
                            ),
                          ),
                          SizedBox(width: r(12)),
                          Expanded(
                            child: _SecondaryButton(
                              label: 'Share',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: r(28)),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(r(18)),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(r(22)),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How it works',
                              style: GoogleFonts.montserrat(
                                fontSize: r(14),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: r(16)),
                            const _StepItem(
                              number: '1',
                              text: 'Share your referral code',
                            ),
                            const _StepItem(
                              number: '2',
                              text: 'They complete their first order',
                            ),
                            const _StepItem(
                              number: '3',
                              text: 'You get rewarded automatically',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isTablet = size.shortestSide >= 600;
    final isShort = size.height < 700;

    if (isTablet) return 1.10;
    if (isShort) return 0.92;

    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Material(
      color: const Color(0xFF1C1A99),
      borderRadius: BorderRadius.circular(r(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(r(16)),
        onTap: onTap,
        child: Container(
          height: r(50),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: r(13),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isTablet = size.shortestSide >= 600;
    final isShort = size.height < 700;

    if (isTablet) return 1.10;
    if (isShort) return 0.92;

    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(r(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(r(16)),
        onTap: onTap,
        child: Container(
          height: r(50),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r(16)),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: r(13),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isTablet = size.shortestSide >= 600;
    final isShort = size.height < 700;

    if (isTablet) return 1.10;
    if (isShort) return 0.92;

    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Padding(
      padding: EdgeInsets.only(bottom: r(14)),
      child: Row(
        children: [
          Container(
            width: r(26),
            height: r(26),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1A99).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.montserrat(
                fontSize: r(11),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1A99),
              ),
            ),
          ),
          SizedBox(width: r(12)),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
