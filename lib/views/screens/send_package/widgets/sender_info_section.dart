import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/controllers/send_package_controller.dart';

import '../../../../core/theme/app_colors.dart';
import 'app_text_field.dart';

double _scale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isLandscape =
      MediaQuery.orientationOf(context) == Orientation.landscape;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isLandscape || isShort) return 0.92;

  return 1.0;
}

class SenderInfoSection extends StatefulWidget {
  final bool initiallyExpanded;
  final SendPackageController controller;

  const SenderInfoSection({
    super.key,
    this.initiallyExpanded = false,
    required this.controller,
  });

  @override
  State<SenderInfoSection> createState() => _SenderInfoSectionState();
}

class _SenderInfoSectionState extends State<SenderInfoSection> {
  late bool _isExpanded;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _isExpanded = widget.initiallyExpanded;
    _codeController.text = '+234';

    _nameController.addListener(_syncToMainController);
    _codeController.addListener(_syncToMainController);
    _phoneController.addListener(_syncToMainController);
    _emailController.addListener(_syncToMainController);

    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();

    final firstName = prefs.getString('firstName') ?? '';
    final lastName = prefs.getString('lastName') ?? '';
    final email = prefs.getString('email') ?? '';
    final phoneNumber = prefs.getString('phoneNumber') ?? '';
    final userId = prefs.getString('userId') ?? '';

    final fullName = '$firstName $lastName'.trim();
    final localPhone = _extractLocalPhone(phoneNumber);
    final countryCode = _extractCountryCode(phoneNumber);

    if (!mounted) return;

    setState(() {
      _nameController.text = fullName;
      _emailController.text = email;
      _phoneController.text = localPhone;
      _codeController.text = countryCode;
    });

    widget.controller.setSenderName(fullName);
    widget.controller.setSenderEmail(email);
    widget.controller.setSenderPhone(localPhone);
    widget.controller.setSenderCode(countryCode);
    widget.controller.setCurrentUserId(userId);
  }

  void _syncToMainController() {
    widget.controller.setSenderName(_nameController.text.trim());
    widget.controller.setSenderCode(_codeController.text.trim());
    widget.controller.setSenderPhone(_phoneController.text.trim());
    widget.controller.setSenderEmail(_emailController.text.trim());
  }

  String _extractCountryCode(String phone) {
    if (phone.startsWith('+234')) return '+234';

    if (phone.startsWith('+')) {
      final match = RegExp(r'^(\+\d{1,4})').firstMatch(phone);
      return match?.group(1) ?? '+234';
    }

    return '+234';
  }

  String _extractLocalPhone(String phone) {
    if (phone.startsWith('+234')) {
      return '0${phone.substring(4)}';
    }

    return phone;
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncToMainController);
    _codeController.removeListener(_syncToMainController);
    _phoneController.removeListener(_syncToMainController);
    _emailController.removeListener(_syncToMainController);

    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(24)),
        border: Border.all(color: AppColors.inputBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(r(24)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r(18), vertical: r(18)),
              child: Row(
                children: [
                  Container(
                    width: r(40),
                    height: r(40),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(r(12)),
                      border: Border.all(color: AppColors.infoBorder),
                    ),
                    child: Image.asset('assets/icons/profile.png'),
                  ),
                  SizedBox(width: r(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sender details',
                          style: GoogleFonts.montserrat(
                            fontSize: r(15),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: r(4)),
                        Text(
                          'Contact information used for this shipment',
                          style: GoogleFonts.montserrat(
                            fontSize: r(11.5),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: r(34),
                    height: r(34),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: r(20),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.inputBorder,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          r(18),
                          r(16),
                          r(18),
                          r(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: r(14),
                                vertical: r(12),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(r(14)),
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: r(16),
                                    color: AppColors.brandBlue,
                                  ),
                                  SizedBox(width: r(10)),
                                  Expanded(
                                    child: Text(
                                      'Your saved account details have been prefilled for speed and accuracy.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: r(11.5),
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.label,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: r(18)),
                            const _SectionLabel('Full name'),
                            SizedBox(height: r(8)),
                            AppTextField(
                              controller: _nameController,
                              label: 'Name *',
                              hintText: 'Enter sender name',
                            ),
                            SizedBox(height: r(16)),
                            const _SectionLabel('Phone details'),
                            SizedBox(height: r(8)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    controller: _codeController,
                                    label: 'Code',
                                    hintText: '+234',
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                SizedBox(width: r(12)),
                                Expanded(
                                  flex: 5,
                                  child: AppTextField(
                                    controller: _phoneController,
                                    label: 'Phone number *',
                                    hintText: '08012345678',
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: r(16)),
                            const _SectionLabel('Email address'),
                            SizedBox(height: r(8)),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              hintText: 'Enter email address',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: r(12),
        fontWeight: FontWeight.w600,
        color: AppColors.label,
        letterSpacing: 0.1,
      ),
    );
  }
}
