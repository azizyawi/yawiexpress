import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/services/auth_service.dart';
import 'package:wanmac/views/screens/profile_detail/delete/delete_account_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  String fullName = '';
  String phone = '';
  String email = '';

  bool _isUpdatingPhone = false;
  bool _isVerifyingOtp = false;

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
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      fullName =
          '${prefs.getString('firstName') ?? ''} ${prefs.getString('lastName') ?? ''}'
              .trim();

      phone = prefs.getString('phoneNumber') ?? '';
      email = prefs.getString('email') ?? '';
    });
  }

  String _toLocalPhone(String value) {
    var digits = value.trim().replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('234')) {
      digits = digits.substring(3);
    }

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return digits;
  }

  String _normalizePhone(String value) {
    var digits = value.trim().replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('234')) {
      digits = digits.substring(3);
    }

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '+234$digits';
  }

  bool _isValidNigerianPhone(String value) {
    final normalized = _normalizePhone(value);
    return RegExp(r'^\+234[789][01]\d{8}$').hasMatch(normalized);
  }

  Future<void> _showUpdatePhoneSheet() async {
    final parentContext = context;
    final controller = TextEditingController(text: _toLocalPhone(phone));

    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = _scale(sheetContext);
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
                  maxWidth: _maxContentWidth(sheetContext),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(r(22), r(18), r(22), r(24)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(r(26)),
                      topRight: Radius.circular(r(26)),
                    ),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetHandle(sheetContext),
                        SizedBox(height: r(18)),
                        _sheetCloseButton(sheetContext),
                        SizedBox(height: r(30)),
                        Text(
                          'Update phone number',
                          style: GoogleFonts.montserrat(
                            fontSize: r(22),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: r(8)),
                        Text(
                          'Enter your new phone number. We will send a verification code.',
                          style: GoogleFonts.montserrat(
                            fontSize: r(13),
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: r(30)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: r(88),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label(sheetContext, 'Country'),
                                  SizedBox(height: r(8)),
                                  Container(
                                    height: r(62),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: r(12),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputFill,
                                      borderRadius: BorderRadius.circular(
                                        r(12),
                                      ),
                                      border: Border.all(
                                        color: AppColors.inputBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '🇳🇬',
                                          style: TextStyle(fontSize: r(20)),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.brandBlue,
                                          size: r(24),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: r(14)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label(sheetContext, 'Phone number'),
                                  SizedBox(height: r(8)),
                                  Container(
                                    constraints: BoxConstraints(
                                      minHeight: r(62),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: r(14),
                                      vertical: r(10),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.infoBg,
                                      borderRadius: BorderRadius.circular(
                                        r(12),
                                      ),
                                      border: Border.all(
                                        color: AppColors.inputBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '+234',
                                          style: GoogleFonts.montserrat(
                                            fontSize: r(14),
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        SizedBox(width: r(8)),
                                        Expanded(
                                          child: TextField(
                                            controller: controller,
                                            keyboardType: TextInputType.phone,
                                            maxLines: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                14,
                                              ),
                                            ],
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isCollapsed: true,
                                              hintText: '8149106125',
                                            ),
                                            style: GoogleFonts.montserrat(
                                              fontSize: r(14),
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
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
                        SizedBox(height: r(28)),
                        SizedBox(
                          width: double.infinity,
                          height: r(60),
                          child: ElevatedButton(
                            onPressed: _isUpdatingPhone
                                ? null
                                : () async {
                                    final rawPhone = controller.text.trim();

                                    if (rawPhone.isEmpty) {
                                      AppSnackBar.show(
                                        parentContext,
                                        message: 'Enter your phone number',
                                        type: AppSnackBarType.warning,
                                      );
                                      return;
                                    }

                                    final normalizedPhone = _normalizePhone(
                                      rawPhone,
                                    );

                                    if (!_isValidNigerianPhone(rawPhone)) {
                                      AppSnackBar.show(
                                        parentContext,
                                        message:
                                            'Enter a valid Nigerian phone number',
                                        type: AppSnackBarType.warning,
                                      );
                                      return;
                                    }

                                    if (normalizedPhone == phone) {
                                      AppSnackBar.show(
                                        parentContext,
                                        message:
                                            'This phone number is already on your account',
                                        type: AppSnackBarType.warning,
                                      );
                                      return;
                                    }

                                    Navigator.of(sheetContext).pop();

                                    if (!mounted) return;

                                    setState(() {
                                      _isUpdatingPhone = true;
                                    });

                                    final result =
                                        await AuthService.requestPhoneUpdate(
                                          normalizedPhone,
                                        );

                                    if (!mounted) return;

                                    setState(() {
                                      _isUpdatingPhone = false;
                                    });

                                    if (result['success'] == true) {
                                      AppSnackBar.show(
                                        parentContext,
                                        message:
                                            result['message'] ??
                                            'Verification code sent',
                                        type: AppSnackBarType.success,
                                      );

                                      await _showConfirmPhoneOtpSheet(
                                        phoneNumber:
                                            result['phoneNumber'] ??
                                            normalizedPhone,
                                      );
                                    } else {
                                      AppSnackBar.show(
                                        parentContext,
                                        message:
                                            result['message'] ??
                                            'Failed to request phone update',
                                        type: AppSnackBarType.error,
                                      );
                                    }
                                  },
                            style: _primaryButtonStyle(sheetContext),
                            child: _isUpdatingPhone
                                ? _buttonLoader(sheetContext)
                                : _buttonText(
                                    sheetContext,
                                    'Update phone number',
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

  Future<void> _showConfirmPhoneOtpSheet({required String phoneNumber}) async {
    final parentContext = context;
    final otpController = TextEditingController();

    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = _scale(sheetContext);
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
                  maxWidth: _maxContentWidth(sheetContext),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(r(22), r(18), r(22), r(24)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(r(26)),
                      topRight: Radius.circular(r(26)),
                    ),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetHandle(sheetContext),
                        SizedBox(height: r(18)),
                        _sheetCloseButton(sheetContext),
                        SizedBox(height: r(30)),
                        Text(
                          'Enter verification code',
                          style: GoogleFonts.montserrat(
                            fontSize: r(22),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: r(8)),
                        Text(
                          'We sent a 4-digit code to $phoneNumber',
                          style: GoogleFonts.montserrat(
                            fontSize: r(13),
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: r(30)),
                        TextField(
                          controller: otpController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: InputDecoration(
                            hintText: '0000',
                            filled: true,
                            fillColor: AppColors.infoBg,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: r(18),
                              vertical: r(18),
                            ),
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
                                width: 1.6,
                              ),
                            ),
                          ),
                          style: GoogleFonts.montserrat(
                            fontSize: r(24),
                            fontWeight: FontWeight.w900,
                            letterSpacing: r(10),
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: r(28)),
                        SizedBox(
                          width: double.infinity,
                          height: r(60),
                          child: ElevatedButton(
                            onPressed: _isVerifyingOtp
                                ? null
                                : () async {
                                    final code = otpController.text.trim();

                                    if (code.length != 4) {
                                      AppSnackBar.show(
                                        parentContext,
                                        message: 'Enter the 4-digit code',
                                        type: AppSnackBarType.warning,
                                      );
                                      return;
                                    }

                                    Navigator.of(sheetContext).pop();

                                    if (!mounted) return;

                                    setState(() {
                                      _isVerifyingOtp = true;
                                    });

                                    final result =
                                        await AuthService.verifyPhoneUpdate(
                                          phoneNumber: phoneNumber,
                                          code: code,
                                        );

                                    if (!mounted) return;

                                    setState(() {
                                      _isVerifyingOtp = false;
                                    });

                                    if (result['success'] == true) {
                                      setState(() {
                                        phone = phoneNumber;
                                      });

                                      AppSnackBar.show(
                                        parentContext,
                                        message:
                                            result['message'] ??
                                            'Phone number updated successfully',
                                        type: AppSnackBarType.success,
                                      );
                                    } else {
                                      AppSnackBar.show(
                                        parentContext,
                                        message:
                                            result['message'] ??
                                            'Failed to verify phone update',
                                        type: AppSnackBarType.error,
                                      );
                                    }
                                  },
                            style: _primaryButtonStyle(sheetContext),
                            child: _isVerifyingOtp
                                ? _buttonLoader(sheetContext)
                                : _buttonText(sheetContext, 'Verify code'),
                          ),
                        ),
                        SizedBox(height: r(14)),
                        Center(
                          child: TextButton(
                            onPressed: _isUpdatingPhone
                                ? null
                                : () async {
                                    setState(() {
                                      _isUpdatingPhone = true;
                                    });

                                    final result =
                                        await AuthService.requestPhoneUpdate(
                                          phoneNumber,
                                        );

                                    if (!mounted) return;

                                    setState(() {
                                      _isUpdatingPhone = false;
                                    });

                                    AppSnackBar.show(
                                      parentContext,
                                      message:
                                          result['message'] ??
                                          'Verification code resent',
                                      type: result['success'] == true
                                          ? AppSnackBarType.success
                                          : AppSnackBarType.error,
                                    );
                                  },
                            child: Text(
                              'Resend code',
                              style: GoogleFonts.montserrat(
                                fontSize: r(14),
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandBlue,
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

    otpController.dispose();
  }

  Widget _sheetHandle(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Align(
      alignment: Alignment.center,
      child: Container(
        height: r(5),
        width: r(48),
        decoration: BoxDecoration(
          color: AppColors.inputBorder,
          borderRadius: BorderRadius.circular(r(100)),
        ),
      ),
    );
  }

  Widget _sheetCloseButton(BuildContext sheetContext) {
    final s = _scale(sheetContext);
    double r(double value) => value * s;

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.of(sheetContext).pop(),
        child: Container(
          height: r(44),
          width: r(44),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: r(23),
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.brandBlue,
      disabledBackgroundColor: AppColors.brandBlue.withOpacity(0.45),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r(12))),
    );
  }

  Widget _buttonLoader(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return SizedBox(
      height: r(22),
      width: r(22),
      child: const CircularProgressIndicator(
        strokeWidth: 2.4,
        color: Colors.white,
      ),
    );
  }

  Widget _buttonText(BuildContext context, String text) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.montserrat(
        fontSize: r(15),
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final s = _scale(context);
    double r(double value) => value * s;

    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.montserrat(
          fontSize: r(13),
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        children: [
          TextSpan(
            text: ' *',
            style: GoogleFonts.montserrat(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: r(20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: r(22),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
            child: ListView(
              padding: EdgeInsets.fromLTRB(r(20), r(14), r(20), r(24)),
              children: [
                _profileTile(
                  context: context,
                  title: 'Account name',
                  value: fullName.isEmpty ? 'User' : fullName,
                  icon: Icons.lock_outline_rounded,
                ),
                SizedBox(height: r(14)),
                _profileTile(
                  context: context,
                  title: 'Phone number',
                  value: phone.isEmpty ? 'Not added' : phone,
                  icon: Icons.verified_rounded,
                  trailingColor: Colors.green,
                  secondaryIcon: Icons.edit_outlined,
                  isLoading: _isUpdatingPhone || _isVerifyingOtp,
                  onTap: (_isUpdatingPhone || _isVerifyingOtp)
                      ? null
                      : _showUpdatePhoneSheet,
                ),
                SizedBox(height: r(14)),
                _profileTile(
                  context: context,
                  title: 'Email',
                  value: email.isEmpty ? 'Not added' : email,
                  icon: Icons.lock_outline_rounded,
                ),
                SizedBox(height: r(40)),
                _actionTile(
                  context: context,
                  title: 'Sign out',
                  icon: Icons.logout_rounded,
                  color: AppColors.textPrimary,
                  onTap: _signOut,
                ),
                SizedBox(height: r(18)),
                _actionTile(
                  context: context,
                  title: 'Delete account',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeleteAccountScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileTile({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    Color? trailingColor,
    IconData? secondaryIcon,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r(18), vertical: r(18)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r(22)),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(14),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: r(6)),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(13),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: r(12)),
            if (isLoading)
              SizedBox(
                height: r(22),
                width: r(22),
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.brandBlue,
                ),
              )
            else if (secondaryIcon != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: r(34),
                    width: r(34),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(r(12)),
                    ),
                    child: Icon(
                      icon,
                      color: trailingColor ?? AppColors.brandBlue,
                      size: r(18),
                    ),
                  ),
                  SizedBox(width: r(10)),
                  Icon(
                    secondaryIcon,
                    color: AppColors.textPrimary,
                    size: r(20),
                  ),
                ],
              )
            else
              Icon(icon, color: AppColors.textPrimary, size: r(22)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: r(6), vertical: r(6)),
        child: Row(
          children: [
            Icon(icon, color: color, size: r(22)),
            SizedBox(width: r(14)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: r(15),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: r(24),
            ),
          ],
        ),
      ),
    );
  }
}
