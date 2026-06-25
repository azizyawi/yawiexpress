import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

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

class SendPackageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SendPackageAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: r(20),
        ),
      ),
      titleSpacing: 0,
      title: Text(
        'Send a package',
        style: GoogleFonts.montserrat(
          fontSize: r(19),
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: r(20)),
          child: Row(
            children: [
              _buildStepDot(context, isActive: true),
              SizedBox(width: r(6)),
              _buildStepDot(context, isActive: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepDot(BuildContext context, {required bool isActive}) {
    final s = _scale(context);
    double r(double value) => value * s;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isActive ? r(20) : r(8),
      height: r(8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.brandBlue
            : AppColors.inputBorder.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(r(20)),
      ),
    );
  }
}
