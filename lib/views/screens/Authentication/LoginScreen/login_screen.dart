import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/services/auth_service.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/models/sign_in_start_request.dart';
import 'package:wanmac/views/screens/Authentication/LoginScreen/signin_otp_screen.dart';
import 'package:wanmac/views/screens/Authentication/create_account_screen.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();

  bool isFocused = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    phoneFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          isFocused = phoneFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    phoneFocusNode.dispose();
    super.dispose();
  }

  String formatNigerianPhone(String input) {
    final value = input.replaceAll(RegExp(r'\s+'), '');

    if (value.startsWith('+234')) return value;
    if (value.startsWith('234')) return '+$value';
    if (value.startsWith('0')) return '+234${value.substring(1)}';

    return '+234$value';
  }

  void _showMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    AppSnackBar.show(context, message: message, type: type);
  }

  Future<void> handleContinue() async {
    final rawPhone = phoneController.text.trim();

    if (rawPhone.isEmpty) {
      _showMessage(
        'Please enter your phone number',
        type: AppSnackBarType.warning,
      );
      return;
    }

    if (rawPhone.length < 10) {
      _showMessage(
        'Please enter a valid phone number',
        type: AppSnackBarType.warning,
      );
      return;
    }

    final phoneNumber = formatNigerianPhone(rawPhone);

    setState(() {
      isLoading = true;
    });

    final result = await AuthService.signInStart(
      SignInStartRequest(phoneNumber: phoneNumber),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final session = result['session'];

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SignInOtpScreen(phoneNumber: phoneNumber, session: session),
        ),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });

      String message;

      switch (result['reason']) {
        case 'USER_NOT_FOUND':
          message = 'No account found with that phone number';
          break;
        case 'INVALID_USER_STATE':
          message = 'We couldn’t sign you in. Please try again.';
          break;
        case 'NO_ACTIVE_OTP':
          message = 'Something went wrong. Please try again.';
          break;
        default:
          message =
              'We couldn’t sign you in. Please check your number and try again.';
      }

      _showMessage(message, type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: r(16),
                right: r(24),
                top: r(14),
                bottom: r(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButtonCircle(onTap: () => Navigator.pop(context)),
                  SizedBox(height: r(48)),
                  Center(
                    child: Text(
                      'Welcome again',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(32),
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: r(14)),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: r(310)),
                      child: Text(
                        'Enter your phone number to continue with your Wanpadi account.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: r(15),
                          fontWeight: FontWeight.w500,
                          height: 1.65,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r(72)),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.montserrat(
                        fontSize: r(14),
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                      ),
                      children: [
                        const TextSpan(text: 'Phone number'),
                        TextSpan(
                          text: ' *',
                          style: GoogleFonts.montserrat(
                            fontSize: r(14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: r(10)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: r(58),
                    padding: EdgeInsets.symmetric(horizontal: r(16)),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(r(16)),
                      border: Border.all(
                        color: isFocused ? Colors.black : AppColors.inputBorder,
                        width: isFocused ? r(1.4) : r(1),
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: const Color(0x14004BFF),
                                blurRadius: r(12),
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '+234',
                          style: GoogleFonts.montserrat(
                            fontSize: r(14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: r(8)),
                        Container(
                          width: r(1),
                          height: r(20),
                          color: AppColors.inputBorder,
                        ),
                        SizedBox(width: r(10)),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            focusNode: phoneFocusNode,
                            cursorColor: Colors.black,
                            selectionControls: materialTextSelectionControls,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.montserrat(
                              fontSize: r(14),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: '08000000000',
                              hintStyle: GoogleFonts.montserrat(
                                fontSize: r(14),
                                fontWeight: FontWeight.w500,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: r(280)),
                  SizedBox(
                    width: double.infinity,
                    height: r(58),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleContinue,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.brandBlueDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r(18)),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: r(22),
                              height: r(22),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Continue',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: r(17),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: r(20)),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const CreateAccountScreen();
                            },
                          ),
                        );
                      },
                      child: Text(
                        'Create a new account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: r(15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandBlueDark,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.brandBlueDark,
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
    );
  }
}

class _BackButtonCircle extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButtonCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: r(46),
        height: r(46),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F4F8),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            'assets/images/arrow-left.png',
            width: r(18),
            height: r(18),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
