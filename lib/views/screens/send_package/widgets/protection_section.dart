import 'package:flutter/material.dart';

import 'check_row_modern.dart';
import 'fee_tile.dart';
import 'soft_section.dart';

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

class ProtectionSection extends StatelessWidget {
  final bool applyProtection;
  final VoidCallback onToggle;

  const ProtectionSection({
    super.key,
    required this.applyProtection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return SoftSection(
      title: 'Package Protection',
      child: Column(
        children: [
          CheckRowModern(
            title: 'Apply package protection',
            subtitle:
                'Add insurance to help protect your package against unexpected incidents during delivery.',
            value: applyProtection,
            onChanged: onToggle,
          ),
          SizedBox(height: r(16)),
          const FeeTile(label: 'Protection fee:', amount: '₦0'),
        ],
      ),
    );
  }
}
