import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmac/core/providers/location/location_providers.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/models/recent_activity_model.dart';
import 'package:wanmac/services/recent_activities_service.dart';
import 'package:wanmac/views/screens/home/all_activities_screen.dart';
import 'package:wanmac/views/screens/home/widgets/home_text_style.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  Future<void> _openAllActivities(BuildContext context) async {
    final activities = await RecentActivitiesService().getRecentActivities();

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllActivitiesScreen(activities: activities),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isShort = size.height < 700;

    final scale = isTablet ? 1.12 : (isLandscape || isShort ? 0.92 : 1.0);

    double r(double value) => value * scale;

    final locationState = ref.watch(locationNotifierProvider);
    final pickup = locationState.pickupLocation;
    final current = locationState.currentLocation;

    String address = '';

    if (pickup?.address.isNotEmpty ?? false) {
      address = pickup!.address;
    } else if (current?.address.isNotEmpty ?? false) {
      address = current!.address;
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                if (address.isNotEmpty)
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: r(20),
                  ),
                if (address.isNotEmpty) SizedBox(width: r(8)),
                Expanded(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sf(
                      size: r(13),
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: r(12)),
        FutureBuilder<List<RecentActivityModel>>(
          future: RecentActivitiesService().getRecentActivities(),
          builder: (context, snapshot) {
            final hasActivities =
                snapshot.hasData && (snapshot.data?.isNotEmpty ?? false);

            return GestureDetector(
              onTap: () => _openAllActivities(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: r(48),
                    height: r(48),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(r(18)),
                      border: Border.all(
                        color: AppColors.inputBorder.withOpacity(0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                      size: r(23),
                    ),
                  ),
                  if (hasActivities)
                    Positioned(
                      top: -r(2),
                      right: -r(2),
                      child: Container(
                        width: r(12),
                        height: r(12),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: r(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
