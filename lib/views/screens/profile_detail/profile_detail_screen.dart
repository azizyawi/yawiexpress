import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/services/auth_service.dart';
import 'package:wanmac/views/screens/profile_detail/delete/delete_account_screen.dart';

double _profileScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

double _profileMaxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  if (size.shortestSide >= 600) {
    return 680;
  }

  return double.infinity;
}

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
          '${prefs.getString('firstName') ?? ''} '
                  '${prefs.getString('lastName') ?? ''}'
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
        final s = _profileScale(sheetContext);

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
                  maxWidth: _profileMaxContentWidth(sheetContext),
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
        final s = _profileScale(sheetContext);

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
                  maxWidth: _profileMaxContentWidth(sheetContext),
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
                                      final prefs =
                                          await SharedPreferences.getInstance();

                                      await prefs.setString(
                                        'phoneNumber',
                                        phoneNumber,
                                      );

                                      if (!mounted) return;

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
    final s = _profileScale(context);

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
    final s = _profileScale(sheetContext);

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
    final s = _profileScale(context);

    double r(double value) => value * s;

    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.brandBlue,
      disabledBackgroundColor: AppColors.brandBlue.withOpacity(0.45),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r(12))),
    );
  }

  Widget _buttonLoader(BuildContext context) {
    final s = _profileScale(context);

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
    final s = _profileScale(context);

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
    final s = _profileScale(context);

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
    final s = _profileScale(context);

    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _profileMaxContentWidth(context),
          ),
          child: ListView(
            padding: EdgeInsets.only(bottom: r(30)),
            children: [
              _ProfileDetailsHeader(
                name: fullName.isEmpty ? 'User' : fullName,
                onBack: () => Navigator.pop(context),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(r(20), r(26), r(20), r(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Personal information'),

                    _profileTile(
                      context: context,
                      title: 'Account name',
                      value: fullName.isEmpty ? 'User' : fullName,
                      icon: Icons.lock_outline_rounded,
                    ),

                    SizedBox(height: r(12)),

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

                    SizedBox(height: r(12)),

                    _profileTile(
                      context: context,
                      title: 'Email',
                      value: email.isEmpty ? 'Not added' : email,
                      icon: Icons.lock_outline_rounded,
                    ),

                    SizedBox(height: r(30)),

                    _sectionTitle(context, 'Account actions'),

                    _actionCard(
                      context: context,
                      title: 'Sign out',
                      subtitle: 'Sign out of your Wanpadi account',
                      icon: Icons.logout_rounded,
                      color: AppColors.textPrimary,
                      iconBackground: AppColors.inputFill,
                      onTap: _signOut,
                    ),

                    SizedBox(height: r(12)),

                    _actionCard(
                      context: context,
                      title: 'Delete account',
                      subtitle: 'Permanently remove your account and data',
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      iconBackground: AppColors.error.withOpacity(0.08),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final s = _profileScale(context);

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
    final s = _profileScale(context);

    double r(double value) => value * s;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(r(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(18)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(17)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r(18)),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Container(
                width: r(44),
                height: r(44),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(r(14)),
                ),
                child: Icon(
                  icon,
                  size: r(21),
                  color: trailingColor ?? AppColors.brandBlueDark,
                ),
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
                        fontSize: r(13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: r(5)),

                    Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(12),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                Container(
                  width: r(38),
                  height: r(38),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(r(12)),
                  ),
                  child: Icon(
                    secondaryIcon,
                    color: AppColors.brandBlueDark,
                    size: r(19),
                  ),
                )
              else
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textHint,
                  size: r(19),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    final s = _profileScale(context);

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
                width: r(44),
                height: r(44),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(r(14)),
                ),
                child: Icon(icon, color: color, size: r(21)),
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
                        fontSize: r(14),
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),

                    SizedBox(height: r(4)),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(11.5),
                        height: 1.35,
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

class _ProfileDetailsHeader extends StatelessWidget {
  final String name;
  final VoidCallback onBack;

  const _ProfileDetailsHeader({required this.name, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = _profileScale(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    double r(double value) => value * s;

    return SizedBox(
      height: topPadding + r(250),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(color: AppColors.brandBlueDark),
              child: CustomPaint(painter: _ProfileHeaderPainter()),
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
                          width: r(46),
                          height: r(46),
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
                        'Profile Details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: r(24),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Row(
                  children: [
                    Container(
                      width: r(78),
                      height: r(78),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile_avata.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withOpacity(0.14),
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: r(38),
                              ),
                            );
                          },
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
                            style: GoogleFonts.montserrat(
                              fontSize: r(19),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),

                          SizedBox(height: r(6)),

                          Text(
                            'Manage your account information',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: r(11.5),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.72),
                            ),
                          ),

                          SizedBox(height: r(10)),

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
                                  Icons.manage_accounts_rounded,
                                  size: r(13),
                                  color: Colors.white,
                                ),

                                SizedBox(width: r(5)),

                                Text(
                                  'Account settings',
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

class _ProfileHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final soft = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final line = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final faint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final wave = Path()
      ..moveTo(width * 0.24, height * 0.92)
      ..cubicTo(
        width * 0.42,
        height * 0.48,
        width * 0.72,
        height * 0.88,
        width * 1.05,
        height * 0.30,
      );

    canvas.drawPath(wave, soft);
    _drawDashed(canvas, wave, line);

    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.69, height * 0.18, width * 0.24, height * 0.30),
      const Radius.circular(18),
    );

    canvas.drawRRect(card, faint);

    canvas.drawCircle(
      Offset(width * 0.75, height * 0.27),
      width * 0.025,
      faint,
    );

    canvas.drawLine(
      Offset(width * 0.79, height * 0.25),
      Offset(width * 0.88, height * 0.25),
      faint,
    );

    canvas.drawLine(
      Offset(width * 0.73, height * 0.36),
      Offset(width * 0.89, height * 0.36),
      faint,
    );

    _node(canvas, Offset(width * 0.40, height * 0.73));

    _node(canvas, Offset(width * 0.73, height * 0.55));

    _node(canvas, Offset(width * 0.92, height * 0.36));

    canvas.drawLine(
      Offset(width * 0.56, height * 0.20),
      Offset(width * 0.56, height * 0.30),
      line,
    );

    canvas.drawLine(
      Offset(width * 0.51, height * 0.25),
      Offset(width * 0.61, height * 0.25),
      line,
    );

    final circle = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(width * 0.88, height * 0.14),
      width * 0.18,
      circle,
    );
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
    final outer = Paint()..color = Colors.white.withOpacity(0.08);

    final inner = Paint()..color = Colors.white.withOpacity(0.25);

    canvas.drawCircle(center, 10, outer);
    canvas.drawCircle(center, 4, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
