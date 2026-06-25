import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/models/recent_activity_model.dart';
import 'package:wanmac/views/screens/home/widgets/home_text_style.dart';

class HomeTransactionTile extends StatelessWidget {
  final RecentActivityModel activity;

  const HomeTransactionTile({super.key, required this.activity});

  String _formatTime(String value) {
    try {
      final dateTime = DateTime.parse(value).toLocal();
      return DateFormat('dd MMM').format(dateTime);
    } catch (_) {
      return '';
    }
  }

  String _formatHour(String value) {
    try {
      final dateTime = DateTime.parse(value).toLocal();
      return DateFormat('h:mm a').format(dateTime);
    } catch (_) {
      return '';
    }
  }

  String _statusLabel(String type) {
    switch (type) {
      case 'order_created':
        return 'Created';
      case 'order_accepted':
        return 'Accepted';
      case 'order_completed':
        return 'Completed';
      default:
        return 'Update';
    }
  }

  Color _statusBg(String type) {
    switch (type) {
      case 'order_created':
        return const Color(0xEEF1F5FF);
      case 'order_accepted':
        return const Color(0xFFFFF3E8);
      case 'order_completed':
        return const Color(0xFFEAF8EE);
      default:
        return const Color(0xFFF3F5F7);
    }
  }

  Color _statusColor(String type) {
    switch (type) {
      case 'order_created':
        return const Color(0xFF3559E6);
      case 'order_accepted':
        return const Color(0xFFE38B22);
      case 'order_completed':
        return const Color(0xFF1F9D55);
      default:
        return AppColors.textSecondary;
    }
  }

  Color _iconSurface(String type) {
    switch (type) {
      case 'order_created':
        return const Color(0xFFF3F6FF);
      case 'order_accepted':
        return const Color(0xFFFFF7EE);
      case 'order_completed':
        return const Color(0xFFF0FBF4);
      default:
        return const Color(0xFFF5F6F8);
    }
  }

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isShort = size.height < 700;

    if (isTablet) return 1.12;
    if (isLandscape || isShort) return 0.94;
    return 1.0;
  }

  Widget _leadingIcon(BuildContext context) {
    final scale = _scale(context);
    double r(double value) => value * scale;

    if (activity.type == 'order_created') {
      return Container(
        width: r(52),
        height: r(52),
        decoration: BoxDecoration(
          color: const Color(0xFFE7EEFF),
          borderRadius: BorderRadius.circular(r(18)),
          border: Border.all(color: const Color(0xFFD9E3FF), width: 1),
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/cube.png',
            width: r(24),
            height: r(24),
            fit: BoxFit.contain,
            color: AppColors.brandBlueDark,
          ),
        ),
      );
    }

    if (activity.type == 'order_accepted') {
      return Container(
        width: r(52),
        height: r(52),
        decoration: BoxDecoration(
          color: _iconSurface(activity.type),
          borderRadius: BorderRadius.circular(r(18)),
          border: Border.all(color: const Color(0xFFE8ECF4), width: 1),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/wanmac_bike.png',
            width: r(40),
            height: r(40),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    IconData icon;

    switch (activity.type) {
      case 'order_completed':
        icon = Icons.check_circle_rounded;
        break;
      default:
        icon = Icons.notifications_rounded;
    }

    return Container(
      width: r(52),
      height: r(52),
      decoration: BoxDecoration(
        color: _iconSurface(activity.type),
        borderRadius: BorderRadius.circular(r(18)),
        border: Border.all(color: const Color(0xFFE8ECF4), width: 1),
      ),
      child: Icon(icon, size: r(22), color: _statusColor(activity.type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    double r(double value) => value * scale;

    final dateText = _formatTime(activity.createdAt);
    final hourText = _formatHour(activity.createdAt);

    return Container(
      margin: EdgeInsets.symmetric(vertical: r(6)),
      padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(r(22)),
        border: Border.all(color: const Color(0xFFEAECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.018),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _leadingIcon(context),
          SizedBox(width: r(12)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: r(1)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sf(
                            size: r(13.5),
                            weight: FontWeight.w800,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      SizedBox(width: r(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r(10),
                          vertical: r(5),
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg(activity.type),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(activity.type),
                          style: sf(
                            size: r(10),
                            weight: FontWeight.w700,
                            color: _statusColor(activity.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r(6)),
                  Text(
                    activity.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sf(
                      size: r(11.2),
                      weight: FontWeight.w500,
                      color: const Color(0xFF667085),
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: r(10)),
                  Row(
                    children: [
                      Container(
                        width: r(6),
                        height: r(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD0D5DD),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: r(6)),
                      Text(
                        dateText,
                        style: sf(
                          size: r(10.5),
                          weight: FontWeight.w600,
                          color: const Color(0xFF98A2B3),
                        ),
                      ),
                      if (hourText.isNotEmpty) ...[
                        SizedBox(width: r(8)),
                        Text(
                          hourText,
                          style: sf(
                            size: r(10.5),
                            weight: FontWeight.w700,
                            color: const Color(0xFF475467),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
