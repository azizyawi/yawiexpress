import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/services/auth_service.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.4,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
            size: r(24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delete Account',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: r(20),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: EdgeInsets.symmetric(
                      horizontal: r(22),
                      vertical: r(24),
                    ),
                    child: Column(
                      children: [
                        _warningRow(
                          context: context,
                          icon: Icons.delete_outline_rounded,
                          text:
                              'This action will erase your WANPADI account data from our system after the recovery period.',
                        ),
                        SizedBox(height: r(28)),
                        _warningRow(
                          context: context,
                          icon: Icons.restore_rounded,
                          text:
                              'You can still recover your account by logging in again before the recovery period ends.',
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: r(22),
                      vertical: r(16),
                    ),
                    color: AppColors.inputFill,
                    child: Text(
                      'Before you go, you can',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(14),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _optionTile(
                    context: context,
                    icon: Icons.support_agent_rounded,
                    title:
                        'Reach out to our Customer Support for pending issues',
                  ),
                  _optionTile(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Tell us why you are leaving WANPADI',
                  ),
                  SizedBox(height: r(28)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r(22)),
                    child: Container(
                      padding: EdgeInsets.all(r(18)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(r(16)),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: r(54),
                            width: r(54),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlueDark.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              color: AppColors.brandBlueDark,
                              size: r(26),
                            ),
                          ),
                          SizedBox(width: r(14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'We’re sad to see you go',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: r(15),
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: r(6)),
                                Text(
                                  'Your WANPADI account can still be recovered within 30 days by logging back in. After 30 days, your account and data may be permanently deleted.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: r(12),
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: r(30)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r(22)),
                    child: SizedBox(
                      width: double.infinity,
                      height: r(58),
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await AuthService.deleteAccount();

                          if (!context.mounted) return;

                          AppSnackBar.show(
                            context,
                            message: result['message'] ?? '',
                            type: result['success'] == true
                                ? AppSnackBarType.success
                                : AppSnackBarType.error,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandBlueDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r(14)),
                          ),
                        ),
                        child: Text(
                          'Delete My Account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: r(15),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r(16)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.montserrat(
                        fontSize: r(14),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: r(30)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _warningRow({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textPrimary, size: r(22)),
        SizedBox(width: r(16)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: r(13),
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(horizontal: r(22), vertical: r(20)),
      child: Row(
        children: [
          Container(
            height: r(38),
            width: r(38),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(r(12)),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: r(18)),
          ),
          SizedBox(width: r(14)),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: r(13),
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
            size: r(22),
          ),
        ],
      ),
    );
  }
}
