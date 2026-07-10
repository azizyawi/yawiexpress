import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class HomeServicesOverlay extends StatelessWidget {
  final VoidCallback onSendTap;
  final VoidCallback onFoodTap;
  final VoidCallback onBillsTap;

  const HomeServicesOverlay({
    super.key,
    required this.onSendTap,
    required this.onFoodTap,
    required this.onBillsTap,
  });

  bool _isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  bool _isShortHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 700;
  }

  double _cardHeight(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    if (isTablet) return 92;
    if (isLandscape || isShort) return 72;
    return 80;
  }

  double _iconBoxSize(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    if (isTablet) return 40;
    if (isLandscape || isShort) return 30;
    return 34;
  }

  double _iconSize(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    if (isTablet) return 21;
    if (isLandscape || isShort) return 16;
    return 18;
  }

  TextStyle _sf({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 12 : 10,
        isLandscape || isShort ? 7 : 8,
        isTablet ? 12 : 10,
        isLandscape || isShort ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _serviceCard(
              context: context,
              icon: Icons.near_me_rounded,
              label: 'Send',
              iconColor: AppColors.brandBlueDark,
              iconBg: AppColors.brandBlueDark.withOpacity(0.10),
              isSoon: false,
              onTap: onSendTap,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: _serviceCard(
              context: context,
              icon: Icons.restaurant_rounded,
              label: 'Food',
              iconColor: const Color(0xFFEA580C),
              iconBg: const Color(0xFFEA580C).withOpacity(0.10),
              isSoon: true,
              onTap: onFoodTap,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: _serviceCard(
              context: context,
              icon: Icons.receipt_long_rounded,
              label: 'Bills',
              iconColor: const Color(0xFF0F766E),
              iconBg: const Color(0xFF0F766E).withOpacity(0.10),
              isSoon: true,
              onTap: onBillsTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBg,
    required bool isSoon,
    required VoidCallback onTap,
  }) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: _cardHeight(context),
        padding: EdgeInsets.fromLTRB(
          isTablet ? 10 : 8,
          isLandscape || isShort ? 5 : 6,
          isTablet ? 10 : 8,
          isLandscape || isShort ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.inputBorder.withOpacity(0.85)),
        ),
        child: Column(
          children: [
            SizedBox(
              height: isLandscape || isShort ? 12 : 14,
              child: Align(
                alignment: Alignment.topRight,
                child: isSoon
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 8 : 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Soon',
                          style: _sf(
                            size: isTablet ? 8 : 7,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: _iconBoxSize(context),
                  height: _iconBoxSize(context),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: _iconSize(context)),
                ),
              ),
            ),
            SizedBox(height: isLandscape || isShort ? 1 : 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: _sf(
                size: isTablet ? 12 : 11,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
