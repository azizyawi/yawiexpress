import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'location_field.dart';

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

class PickupDropoffCard extends StatelessWidget {
  final String pickupAddress;
  final String dropoffAddress;
  final bool isGettingCurrentLocation;
  final VoidCallback onPickupTap;
  final VoidCallback onDropoffTap;

  const PickupDropoffCard({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.isGettingCurrentLocation,
    required this.onPickupTap,
    required this.onDropoffTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final isPickupHint =
        pickupAddress == 'Tap to select pickup location' ||
        pickupAddress == 'Detecting your current location...' ||
        pickupAddress == 'Tap to load pickup location' ||
        pickupAddress == 'Getting your location...';

    final isDropoffHint =
        dropoffAddress == 'Tap to select dropoff location' ||
        dropoffAddress == 'Drop off Address';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(22)),
        border: Border.all(color: AppColors.inputBorder.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: r(7)),
            child: Column(
              children: [
                Container(
                  width: r(12),
                  height: r(12),
                  decoration: const BoxDecoration(
                    color: AppColors.brandBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: r(2),
                  height: r(54),
                  color: AppColors.inputBorder,
                ),
                Container(
                  width: r(12),
                  height: r(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brandBlue, width: 2),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: r(14)),
          Expanded(
            child: Column(
              children: [
                GestureDetector(
                  onTap: onPickupTap,
                  child: LocationField(
                    title: 'Pickup',
                    value: pickupAddress,
                    icon: Icons.location_on_outlined,
                    isHint: isPickupHint,
                  ),
                ),
                SizedBox(height: r(18)),
                GestureDetector(
                  onTap: onDropoffTap,
                  child: LocationField(
                    title: 'Dropoff',
                    value: dropoffAddress,
                    icon: Icons.search,
                    isHint: isDropoffHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
