import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class ReceiverInfoSection extends StatefulWidget {
  final SendPackageController controller;

  const ReceiverInfoSection({super.key, required this.controller});

  @override
  State<ReceiverInfoSection> createState() => _ReceiverInfoSectionState();
}

class _ReceiverInfoSectionState extends State<ReceiverInfoSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.controller.receiverName,
    );
    _codeController = TextEditingController(
      text: widget.controller.receiverCode,
    );
    _phoneController = TextEditingController(
      text: widget.controller.receiverPhone,
    );
    _emailController = TextEditingController(
      text: widget.controller.receiverEmail,
    );

    _nameController.addListener(() {
      widget.controller.setReceiverName(_nameController.text);
    });

    _codeController.addListener(() {
      widget.controller.setReceiverCode(_codeController.text);
    });

    _phoneController.addListener(() {
      widget.controller.setReceiverPhone(_phoneController.text);
    });

    _emailController.addListener(() {
      widget.controller.setReceiverEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  TextStyle _text(
    BuildContext context, {
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size * _scale(context),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r(20)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(24)),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: r(6),
                height: r(40),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(r(999)),
                ),
              ),
              SizedBox(width: r(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receiver information',
                      style: _text(
                        context,
                        size: 17,
                        weight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: r(4)),
                    Text(
                      'Recipient details used for contact, delivery, and handoff verification.',
                      style: _text(
                        context,
                        size: 11.8,
                        weight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r(22)),
          AppTextField(
            label: 'Recipient name *',
            hintText: 'Enter receiver name',
            controller: _nameController,
          ),
          SizedBox(height: r(18)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  label: 'Code',
                  hintText: '+234',
                  keyboardType: TextInputType.phone,
                  controller: _codeController,
                ),
              ),
              SizedBox(width: r(12)),
              Expanded(
                flex: 5,
                child: AppTextField(
                  label: 'Phone number *',
                  hintText: '08012345678',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                ),
              ),
            ],
          ),
          SizedBox(height: r(18)),
          AppTextField(
            label: 'Email address (Optional)',
            hintText: 'Enter email address',
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
          ),
        ],
      ),
    );
  }
}
