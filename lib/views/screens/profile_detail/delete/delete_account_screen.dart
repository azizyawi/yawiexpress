import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/services/auth_service.dart';

double _deleteScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

double _deleteMaxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  if (size.shortestSide >= 600) {
    return 680;
  }

  return double.infinity;
}

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;

  Future<void> _showDeleteConfirmation() async {
    if (_isDeleting) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = _deleteScale(sheetContext);

        double r(double value) => value * s;

        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _deleteMaxContentWidth(sheetContext),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(r(22), r(16), r(22), r(24)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(r(28)),
                    topRight: Radius.circular(r(28)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: r(48),
                      height: r(5),
                      decoration: BoxDecoration(
                        color: AppColors.inputBorder,
                        borderRadius: BorderRadius.circular(r(100)),
                      ),
                    ),

                    SizedBox(height: r(24)),

                    Container(
                      height: r(70),
                      width: r(70),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.09),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_forever_rounded,
                        color: AppColors.error,
                        size: r(34),
                      ),
                    ),

                    SizedBox(height: r(18)),

                    Text(
                      'Delete your account?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: r(21),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),

                    SizedBox(height: r(9)),

                    Text(
                      'Your account will enter a 30-day recovery period. You may restore it by signing in again before the recovery period ends.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: r(12.5),
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: r(26)),

                    SizedBox(
                      width: double.infinity,
                      height: r(58),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r(15)),
                          ),
                        ),
                        child: Text(
                          'Yes, delete my account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: r(14),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: r(10)),

                    SizedBox(
                      width: double.infinity,
                      height: r(54),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(false);
                        },
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r(15)),
                          ),
                        ),
                        child: Text(
                          'Keep my account',
                          style: GoogleFonts.montserrat(
                            fontSize: r(14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final result = await AuthService.deleteAccount();

      if (!mounted) return;

      AppSnackBar.show(
        context,
        message:
            result['message'] ??
            (result['success'] == true
                ? 'Account deletion requested'
                : 'Unable to delete your account'),
        type: result['success'] == true
            ? AppSnackBarType.success
            : AppSnackBarType.error,
      );
    } catch (_) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: 'Something went wrong. Please try again.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _deleteScale(context);

    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _deleteMaxContentWidth(context),
          ),
          child: ListView(
            padding: EdgeInsets.only(bottom: r(34)),
            children: [
              _DeleteAccountHero(onBack: () => Navigator.pop(context)),

              Padding(
                padding: EdgeInsets.fromLTRB(r(20), r(26), r(20), 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DeletionSummaryCard(),

                    SizedBox(height: r(30)),

                    _sectionTitle(context, 'What happens next'),

                    const _DeletionStepsCard(),

                    SizedBox(height: r(30)),

                    _sectionTitle(context, 'Need help first?'),

                    _HelpOptionCard(
                      icon: Icons.support_agent_rounded,
                      title: 'Contact customer support',
                      subtitle:
                          'Get help with a pending delivery or an account issue before leaving.',
                      onTap: () {
                        AppSnackBar.show(
                          context,
                          message:
                              'Contact support from the Help Centre in your account.',
                          type: AppSnackBarType.info,
                        );
                      },
                    ),

                    SizedBox(height: r(12)),

                    _HelpOptionCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Share your feedback',
                      subtitle:
                          'Tell us what went wrong so we can improve the Wanpadi experience.',
                      onTap: () {
                        _showFeedbackSheet();
                      },
                    ),

                    SizedBox(height: r(24)),

                    const _RecoveryCard(),

                    SizedBox(height: r(28)),

                    SizedBox(
                      width: double.infinity,
                      height: r(60),
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          disabledBackgroundColor: AppColors.error.withOpacity(
                            0.45,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r(16)),
                          ),
                        ),
                        child: _isDeleting
                            ? SizedBox(
                                height: r(23),
                                width: r(23),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: r(21),
                                  ),

                                  SizedBox(width: r(9)),

                                  Text(
                                    'Delete My Account',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      fontSize: r(14.5),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: r(10)),

                    SizedBox(
                      width: double.infinity,
                      height: r(52),
                      child: TextButton(
                        onPressed: _isDeleting
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.montserrat(
                            fontSize: r(14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
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
    final s = _deleteScale(context);

    double r(double value) => value * s;

    return Padding(
      padding: EdgeInsets.only(left: r(2), bottom: r(10)),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: r(14),
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _showFeedbackSheet() async {
    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = _deleteScale(sheetContext);

        double r(double value) => value * s;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _deleteMaxContentWidth(sheetContext),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(r(22), r(16), r(22), r(24)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(r(28)),
                      topRight: Radius.circular(r(28)),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: r(48),
                            height: r(5),
                            decoration: BoxDecoration(
                              color: AppColors.inputBorder,
                              borderRadius: BorderRadius.circular(r(100)),
                            ),
                          ),
                        ),

                        SizedBox(height: r(24)),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Share your feedback',
                                style: GoogleFonts.montserrat(
                                  fontSize: r(21),
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: r(7)),

                        Text(
                          'Tell us why you are considering deleting your account.',
                          style: GoogleFonts.montserrat(
                            fontSize: r(12.5),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        SizedBox(height: r(22)),

                        TextField(
                          controller: controller,
                          minLines: 4,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Write your feedback here...',
                            filled: true,
                            fillColor: AppColors.inputFill,
                            contentPadding: EdgeInsets.all(r(16)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(r(16)),
                              borderSide: BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(r(16)),
                              borderSide: BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(r(16)),
                              borderSide: BorderSide(
                                color: AppColors.brandBlue,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: GoogleFonts.montserrat(
                            fontSize: r(13),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: r(20)),

                        SizedBox(
                          width: double.infinity,
                          height: r(58),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);

                              AppSnackBar.show(
                                context,
                                message: 'Thank you for your feedback.',
                                type: AppSnackBarType.success,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandBlueDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(r(15)),
                              ),
                            ),
                            child: Text(
                              'Submit feedback',
                              style: GoogleFonts.montserrat(
                                fontSize: r(14),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();
  }
}

class _DeleteAccountHero extends StatelessWidget {
  final VoidCallback onBack;

  const _DeleteAccountHero({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = _deleteScale(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    double r(double value) => value * s;

    return SizedBox(
      height: topPadding + r(252),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.brandBlueDark,
              child: CustomPaint(painter: _DeleteHeaderPainter()),
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
                        'Delete Account',
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
                        Icons.delete_forever_rounded,
                        size: r(39),
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(width: r(17)),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Before you leave',
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
                            'Review what happens to your account and how the recovery period works.',
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
                                  Icons.shield_outlined,
                                  color: Colors.white,
                                  size: r(13),
                                ),

                                SizedBox(width: r(5)),

                                Flexible(
                                  child: Text(
                                    '30-day recovery period',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      fontSize: r(10.5),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
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

class _DeletionSummaryCard extends StatelessWidget {
  const _DeletionSummaryCard();

  @override
  Widget build(BuildContext context) {
    final s = _deleteScale(context);

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
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(r(16)),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: r(24),
            ),
          ),

          SizedBox(width: r(14)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account deletion is a serious action',
                  style: GoogleFonts.montserrat(
                    fontSize: r(14.5),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),

                SizedBox(height: r(7)),

                Text(
                  'Your Wanpadi account will become inactive after deletion is requested. It may later be permanently removed when the recovery period ends.',
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

class _DeletionStepsCard extends StatelessWidget {
  const _DeletionStepsCard();

  @override
  Widget build(BuildContext context) {
    final s = _deleteScale(context);

    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r(17), vertical: r(6)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(22)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: const [
          _DeletionStep(
            icon: Icons.person_off_outlined,
            title: 'Your account becomes inactive',
            subtitle:
                'You may temporarily lose access to your account and services.',
          ),
          _DeletionStepDivider(),
          _DeletionStep(
            icon: Icons.restore_rounded,
            title: 'You have 30 days to recover it',
            subtitle:
                'Sign in again before the recovery period ends to restore your account.',
          ),
          _DeletionStepDivider(),
          _DeletionStep(
            icon: Icons.delete_sweep_outlined,
            title: 'Your data may be permanently removed',
            subtitle:
                'After the recovery period, your account and associated data may be deleted.',
          ),
        ],
      ),
    );
  }
}

class _DeletionStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DeletionStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final s = _deleteScale(context);

    double r(double value) => value * s;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: r(15)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: r(40),
            width: r(40),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(r(13)),
            ),
            child: Icon(icon, size: r(20), color: AppColors.brandBlueDark),
          ),

          SizedBox(width: r(13)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: r(13),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: r(5)),

                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: r(11.5),
                    height: 1.5,
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

class _DeletionStepDivider extends StatelessWidget {
  const _DeletionStepDivider();

  @override
  Widget build(BuildContext context) {
    final s = _deleteScale(context);

    double r(double value) => value * s;

    return Padding(
      padding: EdgeInsets.only(left: r(53)),
      child: Divider(height: 1, thickness: 1, color: AppColors.inputBorder),
    );
  }
}

class _HelpOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = _deleteScale(context);

    double r(double value) => value * s;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(r(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(18)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r(18)),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Container(
                height: r(44),
                width: r(44),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(r(14)),
                ),
                child: Icon(icon, color: AppColors.brandBlueDark, size: r(21)),
              ),

              SizedBox(width: r(14)),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(13.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: r(5)),

                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(11),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: r(10)),

              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: r(24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard();

  @override
  Widget build(BuildContext context) {
    final s = _deleteScale(context);

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
            height: r(40),
            width: r(40),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(r(13)),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: AppColors.brandBlueDark,
              size: r(21),
            ),
          ),

          SizedBox(width: r(13)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account recovery',
                  style: GoogleFonts.montserrat(
                    fontSize: r(13.5),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: r(6)),

                Text(
                  'You can recover your account within 30 days by signing in again. After that period, your account and data may be permanently deleted.',
                  style: GoogleFonts.montserrat(
                    fontSize: r(11.5),
                    height: 1.55,
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

class _DeleteHeaderPainter extends CustomPainter {
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
        height * 0.56,
        width * 0.68,
        height * 0.85,
        width * 1.04,
        height * 0.29,
      );

    canvas.drawPath(route, softLine);
    _drawDashedPath(canvas, route, dashedLine);

    _drawNode(canvas, Offset(width * 0.34, height * 0.74));

    _drawNode(canvas, Offset(width * 0.68, height * 0.60));

    _drawNode(canvas, Offset(width * 0.92, height * 0.37));

    final shield = Path()
      ..moveTo(width * 0.80, height * 0.15)
      ..lineTo(width * 0.91, height * 0.20)
      ..lineTo(width * 0.90, height * 0.36)
      ..quadraticBezierTo(
        width * 0.86,
        height * 0.43,
        width * 0.80,
        height * 0.47,
      )
      ..quadraticBezierTo(
        width * 0.74,
        height * 0.43,
        width * 0.70,
        height * 0.36,
      )
      ..lineTo(width * 0.69, height * 0.20)
      ..close();

    canvas.drawPath(shield, faintLine);

    canvas.drawLine(
      Offset(width * 0.77, height * 0.30),
      Offset(width * 0.80, height * 0.34),
      dashedLine,
    );

    canvas.drawLine(
      Offset(width * 0.80, height * 0.34),
      Offset(width * 0.85, height * 0.26),
      dashedLine,
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

  void _drawNode(Canvas canvas, Offset center) {
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
