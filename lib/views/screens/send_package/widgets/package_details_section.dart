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

class PackageItem {
  final String label;
  final IconData icon;

  const PackageItem({required this.label, required this.icon});
}

class PackageDetailsSection extends StatefulWidget {
  final List<PackageItem> packageTypes;
  final String? selectedPackageType;
  final ValueChanged<String> onSelected;

  const PackageDetailsSection({
    super.key,
    required this.packageTypes,
    required this.selectedPackageType,
    required this.onSelected,
  });

  @override
  State<PackageDetailsSection> createState() => _PackageDetailsSectionState();
}

class _PackageDetailsSectionState extends State<PackageDetailsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(r(20), r(20), r(20), r(22)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(r(28)),
            border: Border.all(color: AppColors.inputBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withOpacity(0.035),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.brandBlue.withOpacity(0.035),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: r(4),
                    height: r(36),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(r(999)),
                    ),
                  ),
                  SizedBox(width: r(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Package details',
                          style: GoogleFonts.montserrat(
                            fontSize: r(18),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: r(6)),
                        Text(
                          'Choose the category that best matches what you are sending.',
                          style: GoogleFonts.montserrat(
                            fontSize: r(12),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: r(20)),
              Container(
                height: 1,
                width: double.infinity,
                color: AppColors.inputBorder,
              ),
              SizedBox(height: r(18)),
              Wrap(
                spacing: r(10),
                runSpacing: r(10),
                children: widget.packageTypes.map((item) {
                  final isSelected = widget.selectedPackageType == item.label;

                  return _LuxuryMobilityChip(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => widget.onSelected(item.label),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryMobilityChip extends StatefulWidget {
  final PackageItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _LuxuryMobilityChip({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LuxuryMobilityChip> createState() => _LuxuryMobilityChipState();
}

class _LuxuryMobilityChipState extends State<_LuxuryMobilityChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final scale = _pressed ? 0.985 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(6)),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.textPrimary
                : AppColors.surface,
            borderRadius: BorderRadius.circular(r(18)),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.textPrimary
                  : AppColors.inputBorder,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF101828).withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: r(30),
                height: r(30),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Colors.white.withOpacity(0.12)
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(r(10)),
                ),
                child: Icon(
                  widget.item.icon,
                  size: r(16),
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
              SizedBox(width: r(10)),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: GoogleFonts.montserrat(
                  fontSize: r(12.8),
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                  letterSpacing: -0.15,
                  height: 1,
                ),
                child: Text(widget.item.label),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: widget.isSelected
                    ? Padding(
                        key: const ValueKey('selected'),
                        padding: EdgeInsets.only(left: r(10)),
                        child: Container(
                          width: r(20),
                          height: r(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: r(12),
                            color: AppColors.textPrimary,
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('unselected')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
