import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/models/sign_up_request.dart';
import 'package:wanmac/services/auth_service.dart';
import 'package:wanmac/views/screens/Authentication/OtpScreen/otp_verification_screen.dart';
import 'package:wanmac/views/screens/termsScreen/terms_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final referralController = TextEditingController();

  bool agreeToTerms = false;
  bool isLoading = false;
  int currentStep = 0;

  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();

    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TermsScreen()),
        );
      };
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    referralController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  bool _isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  bool _isShortHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 700;
  }

  double _contentMaxWidth(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

    if (isTablet && isLandscape) return 1040;
    if (isLandscape) return 900;
    if (isTablet) return 600;
    return double.infinity;
  }

  EdgeInsets _pagePadding(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return EdgeInsets.fromLTRB(
      isTablet ? 32 : 20,
      isShort ? 12 : 18,
      isTablet ? 32 : 20,
      isLandscape ? 24 : 32,
    );
  }

  String _formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.startsWith('234')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+234${cleaned.substring(1)}';
    return '+234$cleaned';
  }

  String? _validatePhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Phone number is required';

    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 10 || cleaned.length > 13) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email address is required';

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return '$fieldName is required';
    if (input.length < 2) return '$fieldName is too short';
    return null;
  }

  void _showMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    AppSnackBar.show(context, message: message, type: type);
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        final phoneError = _validatePhone(phoneController.text);
        final emailError = _validateEmail(emailController.text);

        if (phoneError != null || emailError != null) {
          _formKey.currentState?.validate();
          return false;
        }
        return true;

      case 1:
        final firstNameError = _validateName(
          firstNameController.text,
          'First name',
        );
        final lastNameError = _validateName(
          lastNameController.text,
          'Last name',
        );

        if (firstNameError != null || lastNameError != null) {
          _formKey.currentState?.validate();
          return false;
        }
        return true;

      case 2:
        if (!agreeToTerms) {
          _showMessage(
            'Please agree to the Terms & Conditions',
            type: AppSnackBarType.warning,
          );
          return false;
        }
        return true;

      case 3:
        return true;

      default:
        return true;
    }
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();

    if (!_validateCurrentStep()) return;

    if (currentStep < 3) {
      setState(() => currentStep++);
    } else {
      _handleSignUp();
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();

    if (currentStep > 0) {
      setState(() => currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    if (isLoading) return;

    final formattedPhone = _formatPhoneNumber(phoneController.text.trim());

    final request = SignUpRequest(
      phoneNumber: formattedPhone,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      promoCode: referralController.text.trim().isEmpty
          ? null
          : referralController.text.trim().toUpperCase(),
    );

    setState(() => isLoading = true);

    final result = await AuthService.signUp(request);

    if (!mounted) return;

    if (result['success'] == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(phoneNumber: formattedPhone),
        ),
      );

      if (!mounted) return;
      setState(() => isLoading = false);
    } else {
      setState(() => isLoading = false);

      _showMessage(
        result['message'] ?? 'Signup failed',
        type: AppSnackBarType.error,
      );
    }
  }

  List<String> get _stepTitles => const [
    'Create your account',
    'Personal information',
    'Terms and referral',
    'Confirm your details',
  ];

  List<String> get _stepSubtitles => const [
    'Use an active number for delivery calls and updates.',
    'Provide your name exactly as it should appear on your profile.',
    'Accept the terms to continue. Referral code is optional.',
    'Review your details carefully before we send your verification code.',
  ];

  String get _buttonText =>
      currentStep == 3 ? 'Continue to verification' : 'Continue';

  Widget _buildHeader() {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    final titleSize = isTablet ? 34.0 : (isLandscape || isShort ? 27.0 : 31.0);
    final subtitleMaxWidth = isLandscape ? 420.0 : 360.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BackButtonCircle(onTap: _previousStep),
            const Spacer(),
            Text(
              '${currentStep + 1}/4',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        SizedBox(height: isShort ? 22 : 28),
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                height: 4,
                decoration: BoxDecoration(
                  color: index <= currentStep
                      ? AppColors.brandBlueDark
                      : AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isShort ? 24 : 34),
        Text(
          _stepTitles[currentStep],
          style: GoogleFonts.montserrat(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 1.08,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: subtitleMaxWidth),
          child: Text(
            _stepSubtitles[currentStep],
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.72,
              color: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsentBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => agreeToTerms = !agreeToTerms),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: agreeToTerms ? AppColors.brandBlueDark : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: agreeToTerms
                      ? AppColors.brandBlueDark
                      : AppColors.inputBorder,
                  width: 1.4,
                ),
              ),
              child: agreeToTerms
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.75,
                  color: AppColors.textPrimary,
                ),
                children: [
                  const TextSpan(
                    text: 'By continuing, you agree to Wanpadi’s ',
                  ),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.75,
                      color: AppColors.brandBlueDark,
                    ),
                    recognizer: _termsRecognizer,
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({required Widget child}) {
    final isTablet = _isTablet(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 26 : 22,
        26,
        isTablet ? 26 : 22,
        26,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF0F2F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildReviewCard() {
    final fullName =
        '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
            .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryMessage(
          message:
              'Here’s your account summary. Please confirm everything looks correct before verification.',
          isMain: true,
        ),
        const SizedBox(height: 16),
        _summaryGroup(
          title: 'Contact summary',
          onEdit: () => setState(() => currentStep = 0),
          children: [
            _summaryBubble(
              label: 'Phone number',
              value: _formatPhoneNumber(phoneController.text.trim()),
            ),
            _summaryBubble(
              label: 'Email address',
              value: emailController.text.trim(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _summaryGroup(
          title: 'Profile summary',
          onEdit: () => setState(() => currentStep = 1),
          children: [
            _summaryBubble(label: 'Full name', value: fullName),
            _summaryBubble(
              label: 'Referral code',
              value: referralController.text.trim().isEmpty
                  ? 'Not added'
                  : referralController.text.trim().toUpperCase(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _summaryMessage(
          message:
              'Next, Wanpadi will send a secure verification code to your phone number.',
        ),
      ],
    );
  }

  Widget _summaryMessage({required String message, bool isMain = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isMain ? AppColors.brandBlueDark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomRight: Radius.circular(22),
            bottomLeft: Radius.circular(7),
          ),
          border: isMain ? null : Border.all(color: const Color(0xFFECEFF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          message,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.58,
            color: isMain ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _summaryGroup({
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 9),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlueDark.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlueDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _summaryBubble({required String label, required String value}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 9, left: 28),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(21),
            topRight: Radius.circular(21),
            bottomLeft: Radius.circular(21),
            bottomRight: Radius.circular(7),
          ),
          border: Border.all(color: const Color(0xFFEAEFF6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 2,
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildStepCard(
          child: Column(
            children: [
              _FormFieldBlock(
                label: 'Phone number',
                requiredField: true,
                child: _WanmacTextField(
                  controller: phoneController,
                  hintText: '08000000000',
                  prefixText: '+234',
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
              ),
              const SizedBox(height: 24),
              _FormFieldBlock(
                label: 'Email address',
                requiredField: true,
                child: _WanmacTextField(
                  controller: emailController,
                  hintText: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
              ),
            ],
          ),
        );

      case 1:
        return _buildStepCard(
          child: Column(
            children: [
              _FormFieldBlock(
                label: 'First name',
                requiredField: true,
                child: _WanmacTextField(
                  controller: firstNameController,
                  hintText: 'John',
                  keyboardType: TextInputType.name,
                  validator: (value) => _validateName(value, 'First name'),
                ),
              ),
              const SizedBox(height: 24),
              _FormFieldBlock(
                label: 'Last name',
                requiredField: true,
                child: _WanmacTextField(
                  controller: lastNameController,
                  hintText: 'Doe',
                  keyboardType: TextInputType.name,
                  validator: (value) => _validateName(value, 'Last name'),
                ),
              ),
            ],
          ),
        );

      case 2:
        return _buildStepCard(
          child: Column(
            children: [
              _FormFieldBlock(
                label: 'Referral code',
                child: _WanmacTextField(
                  controller: referralController,
                  hintText: 'Optional',
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(height: 30),
              _buildConsentBlock(),
            ],
          ),
        );

      case 3:
        return _buildReviewCard();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPortraitContent() {
    final isShort = _isShortHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: isShort ? 28 : 40),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: SizedBox(
            key: ValueKey(currentStep),
            width: double.infinity,
            child: _buildStepContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeContent() {
    final isTablet = _isTablet(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: isTablet ? 5 : 4, child: _buildHeader()),
        SizedBox(width: isTablet ? 46 : 30),
        Expanded(
          flex: isTablet ? 6 : 5,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: SizedBox(
              key: ValueKey(currentStep),
              width: double.infinity,
              child: _buildStepContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 32 : 20,
        14,
        isTablet ? 32 : 20,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.inputBorder.withOpacity(0.85),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLandscape || isTablet ? 620 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.brandBlueDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.brandBlueDark
                          .withOpacity(0.45),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _buttonText,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentStep == 3
                      ? 'Next: verify phone number'
                      : 'Secure account onboarding',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = _isLandscape(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: _pagePadding(context),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: _contentMaxWidth(context),
                        ),
                        child: Form(
                          key: _formKey,
                          child: isLandscape
                              ? _buildLandscapeContent()
                              : _buildPortraitContent(),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            );
          },
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/images/arrow-left.png',
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _FormFieldBlock extends StatelessWidget {
  final String label;
  final bool requiredField;
  final Widget child;

  const _FormFieldBlock({
    required this.label,
    required this.child,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
            children: [
              TextSpan(text: label),
              if (requiredField)
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _WanmacTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? prefixText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _WanmacTextField({
    required this.controller,
    required this.hintText,
    this.prefixText,
    this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<_WanmacTextField> createState() => _WanmacTextFieldState();
}

class _WanmacTextFieldState extends State<_WanmacTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      textCapitalization: widget.textCapitalization,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: widget.hintText,
        prefixIcon: widget.prefixText != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.prefixText!,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 20,
                      color: AppColors.inputBorder,
                    ),
                  ],
                ),
              )
            : null,
        prefixIconConstraints: widget.prefixText != null
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.black,
            width: isFocused ? 1.5 : 1.3,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.error, width: 1.3),
        ),
        errorStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      ),
    );
  }
}
