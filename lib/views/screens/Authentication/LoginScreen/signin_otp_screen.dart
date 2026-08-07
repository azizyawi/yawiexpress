import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/models/sign_in_start_request.dart';
import 'package:wanmac/models/sign_in_verify_request.dart';
import 'package:wanmac/services/auth_service.dart';
import 'package:wanmac/views/screens/main/main_screen.dart';

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

class SignInOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String session;

  const SignInOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.session,
  });

  @override
  State<SignInOtpScreen> createState() => _SignInOtpScreenState();
}

class _SignInOtpScreenState extends State<SignInOtpScreen>
    with TickerProviderStateMixin {
  static const int _otpLength = 4;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  late final AnimationController _pageController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentOffset;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonOffset;

  Timer? _timer;
  int _secondsLeft = 15;

  bool _isVerifying = false;
  bool _isResending = false;

  String _session = '';

  @override
  void initState() {
    super.initState();

    _session = widget.session;

    _controllers = List.generate(
      _otpLength,
      (_) => TextEditingController(),
    );

    _focusNodes = List.generate(
      _otpLength,
      (_) => FocusNode(),
    );

    for (final node in _focusNodes) {
      node.addListener(_refresh);
    }

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerOpacity = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(
        0.0,
        0.35,
        curve: Curves.easeOut,
      ),
    );

    _headerOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(
          0.0,
          0.42,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _contentOpacity = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(
        0.2,
        0.72,
        curve: Curves.easeOut,
      ),
    );

    _contentOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(
          0.2,
          0.75,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _buttonOpacity = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(
        0.45,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _buttonOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(
          0.45,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _pageController.forward();
    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startCountdown() {
    _timer?.cancel();

    _secondsLeft = 15;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;

        if (_secondsLeft <= 1) {
          timer.cancel();

          setState(() {
            _secondsLeft = 0;
          });
        } else {
          setState(() {
            _secondsLeft--;
          });
        }
      },
    );
  }

  bool get _isOtpComplete {
    return _controllers.every(
      (controller) => controller.text.isNotEmpty,
    );
  }

  String get _otpCode {
    return _controllers.map((e) => e.text).join();
  }

  void _onChanged(String value, int index) {
    if (value.isEmpty) {
      setState(() {});
      return;
    }

    final digits = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) {
      return;
    }

    // Handles pasted OTP.
    //
    // Example:
    // User pastes 4827
    //
    // Result:
    // [4] [8] [2] [7]
    if (digits.length > 1) {
      final availableSlots = _otpLength - index;

      final digitsToInsert = digits.length > availableSlots
          ? digits.substring(0, availableSlots)
          : digits;

      for (int i = 0; i < digitsToInsert.length; i++) {
        final targetIndex = index + i;

        _controllers[targetIndex].text = digitsToInsert[i];

        _controllers[targetIndex].selection =
            TextSelection.fromPosition(
          const TextPosition(offset: 1),
        );
      }

      final nextIndex = index + digitsToInsert.length;

      if (nextIndex < _otpLength) {
        _focusNodes[nextIndex].requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }

      setState(() {});
      return;
    }

    // Normal one-digit typing.
    _controllers[index].text = digits;

    _controllers[index].selection =
        TextSelection.fromPosition(
      const TextPosition(offset: 1),
    );

    if (index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    setState(() {});
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isNotEmpty) {
      _controllers[index].clear();

      setState(() {});
      return;
    }

    if (index > 0) {
      _focusNodes[index - 1].requestFocus();

      _controllers[index - 1].clear();

      setState(() {});
    }
  }

  Future<void> _resendCode() async {
    if (_secondsLeft > 0 || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    final result = await AuthService.signInStart(
      SignInStartRequest(
        phoneNumber: widget.phoneNumber,
      ),
    );

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    if (result['success'] == true) {
      _session = (result['session'] ?? '').toString();

      for (final controller in _controllers) {
        controller.clear();
      }

      FocusScope.of(context).requestFocus(
        _focusNodes.first,
      );

      _startCountdown();

      _showMessage(
        result['message'] ?? 'Code resent successfully',
        type: AppSnackBarType.success,
      );
    } else {
      _showMessage(
        result['message'] ?? 'Failed to resend code',
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();

    if (!_isOtpComplete) {
      _showMessage(
        'Please enter the complete 4-digit code',
        type: AppSnackBarType.warning,
      );

      return;
    }

    if (_isVerifying) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final result =
        await AuthService.verifySignInOtpAndSaveUser(
      SignInVerifyRequest(
        phoneNumber: widget.phoneNumber,
        code: _otpCode,
        session: _session,
      ),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
        (route) => false,
      );

      return;
    }

    final newSession =
        (result['session'] ?? '').toString();

    setState(() {
      _isVerifying = false;

      if (newSession.isNotEmpty) {
        _session = newSession;
      }
    });

    for (final controller in _controllers) {
      controller.clear();
    }

    FocusScope.of(context).requestFocus(
      _focusNodes.first,
    );

    _showMessage(
      result['message'] ?? 'Verification failed',
      type: AppSnackBarType.error,
    );
  }

  void _showMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    AppSnackBar.show(
      context,
      message: message,
      type: type,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node
        ..removeListener(_refresh)
        ..dispose();
    }

    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);

    double r(double value) => value * s;

    final canResend = _secondsLeft == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _maxContentWidth(context),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: r(16),
                right: r(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  SizedBox(height: r(14)),

                  FadeTransition(
                    opacity: _headerOpacity,
                    child: _BackButtonCircle(
                      onTap: _isVerifying
                          ? () {}
                          : () =>
                              Navigator.pop(context),
                    ),
                  ),

                  SizedBox(height: r(42)),

                  Expanded(
                    child: Column(
                      children: [
                        SlideTransition(
                          position: _headerOffset,
                          child: FadeTransition(
                            opacity: _headerOpacity,
                            child: Column(
                              children: [
                                Text(
                                  'Verify your number',
                                  textAlign:
                                      TextAlign.center,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      GoogleFonts.montserrat(
                                    fontSize: r(31),
                                    fontWeight:
                                        FontWeight.w800,
                                    height: 1.12,
                                    color: AppColors
                                        .textPrimary,
                                  ),
                                ),

                                SizedBox(height: r(16)),

                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(
                                    horizontal: r(12),
                                  ),
                                  child: RichText(
                                    textAlign:
                                        TextAlign.center,
                                    text: TextSpan(
                                      style: GoogleFonts
                                          .montserrat(
                                        fontSize: r(16),
                                        fontWeight:
                                            FontWeight.w500,
                                        height: 1.6,
                                        color: AppColors
                                            .textSecondary,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              "We've sent a 4-digit verification code for ",
                                        ),

                                        TextSpan(
                                          text: widget
                                              .phoneNumber,
                                          style: GoogleFonts
                                              .montserrat(
                                            fontSize: r(16),
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            height: 1.6,
                                            color: AppColors
                                                .textPrimary,
                                          ),
                                        ),

                                        const TextSpan(
                                          text: " to your ",
                                        ),

                                        TextSpan(
                                          text:
                                              'email and SMS',
                                          style: GoogleFonts
                                              .montserrat(
                                            fontSize: r(16),
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            height: 1.6,
                                            color: AppColors
                                                .brandBlueDark,
                                          ),
                                        ),

                                        const TextSpan(
                                          text:
                                              '. Enter the code below.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: r(110)),

                        SlideTransition(
                          position: _contentOffset,
                          child: FadeTransition(
                            opacity: _contentOpacity,
                            child: Column(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts
                                        .montserrat(
                                      fontSize: r(16),
                                      fontWeight:
                                          FontWeight.w700,
                                      color:
                                          AppColors.label,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Enter code',
                                      ),
                                      TextSpan(
                                        text: ' *',
                                        style: GoogleFonts
                                            .montserrat(
                                          fontSize: r(16),
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          color:
                                              AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: r(8)),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: List.generate(
                                    _otpLength,
                                    (index) => Padding(
                                      padding:
                                          EdgeInsets.only(
                                        right:
                                            index ==
                                                    _otpLength -
                                                        1
                                                ? 0
                                                : r(8),
                                      ),
                                      child: _OtpDigitField(
                                        controller:
                                            _controllers[
                                                index],
                                        focusNode:
                                            _focusNodes[
                                                index],
                                        isFocused:
                                            _focusNodes[
                                                    index]
                                                .hasFocus,
                                        hasValue:
                                            _controllers[
                                                    index]
                                                .text
                                                .isNotEmpty,
                                        onChanged:
                                            (value) =>
                                                _onChanged(
                                          value,
                                          index,
                                        ),
                                        onBackspace: () =>
                                            _onBackspace(
                                          index,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: r(30)),

                                GestureDetector(
                                  onTap: (canResend &&
                                          !_isResending)
                                      ? _resendCode
                                      : null,
                                  behavior:
                                      HitTestBehavior.opaque,
                                  child:
                                      AnimatedContainer(
                                    duration:
                                        const Duration(
                                      milliseconds: 220,
                                    ),
                                    curve: Curves.easeOut,
                                    height: r(52),
                                    padding:
                                        EdgeInsets.symmetric(
                                      horizontal: r(24),
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: canResend
                                          ? AppColors.infoBg
                                          : AppColors
                                              .inputFill,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        r(28),
                                      ),
                                      border: Border.all(
                                        color: canResend
                                            ? AppColors
                                                .infoBorder
                                            : Colors
                                                .transparent,
                                        width: r(1),
                                      ),
                                    ),
                                    child: Center(
                                      child: _isResending
                                          ? SizedBox(
                                              width: r(18),
                                              height: r(18),
                                              child:
                                                  const CircularProgressIndicator(
                                                strokeWidth:
                                                    2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  AppColors
                                                      .brandBlueDark,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              canResend
                                                  ? 'Resend verification code'
                                                  : 'Resend verification code (${_secondsLeft}s)',
                                              textAlign:
                                                  TextAlign
                                                      .center,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  GoogleFonts
                                                      .montserrat(
                                                fontSize:
                                                    r(14),
                                                fontWeight:
                                                    FontWeight
                                                        .w700,
                                                color: canResend
                                                    ? AppColors
                                                        .brandBlueDark
                                                    : AppColors
                                                        .textHint,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SlideTransition(
                    position: _buttonOffset,
                    child: FadeTransition(
                      opacity: _buttonOpacity,
                      child: SizedBox(
                        width: double.infinity,
                        height: r(60),
                        child: ElevatedButton(
                          onPressed: (_isOtpComplete &&
                                  !_isVerifying)
                              ? _verifyCode
                              : null,
                          style:
                              ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor:
                                AppColors.brandBlueDark,
                            disabledBackgroundColor:
                                AppColors.brandBlueDark
                                    .withOpacity(0.35),
                            foregroundColor: Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                r(16),
                              ),
                            ),
                          ),
                          child: _isVerifying
                              ? SizedBox(
                                  width: r(22),
                                  height: r(22),
                                  child:
                                      const CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Verify',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      GoogleFonts.montserrat(
                                    fontSize: r(18),
                                    fontWeight:
                                        FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: r(32)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpDigitField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool hasValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hasValue,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);

    double r(double value) => value * s;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: r(56),
      height: r(60),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(
          r(16),
        ),
        border: Border.all(
          color: isFocused
              ? AppColors.brandBlueDark
              : hasValue
                  ? AppColors.infoBorder
                  : AppColors.inputBorder,
          width: isFocused ? r(1.5) : r(1),
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.brandBlueDark
                      .withOpacity(0.10),
                  blurRadius: r(18),
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey ==
                    LogicalKeyboardKey.backspace) {
              onBackspace();

              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: controller,
            focusNode: focusNode,

            keyboardType: TextInputType.number,

            // Helps iOS detect SMS OTP codes.
            autofillHints: const [
              AutofillHints.oneTimeCode,
            ],

            textAlign: TextAlign.center,
            cursorColor: Colors.black,

            selectionControls:
                materialTextSelectionControls,

            onChanged: onChanged,

            // IMPORTANT:
            // Do not limit this field to one character.
            // It must temporarily receive the full pasted OTP.
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],

            style: GoogleFonts.montserrat(
              fontSize: r(22),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),

            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButtonCircle extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButtonCircle({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);

    double r(double value) => value * s;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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