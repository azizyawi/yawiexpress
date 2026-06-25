import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/models/recent_activity_model.dart';
import 'package:wanmac/views/screens/home/widgets/home_transaction_tile.dart';

class AllActivitiesScreen extends StatelessWidget {
  final List<RecentActivityModel> activities;

  const AllActivitiesScreen({super.key, required this.activities});

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

  double _maxWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isTablet && isLandscape) return 760;
    if (isTablet) return 620;
    if (isLandscape) return 680;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final sortedActivities = [...activities]
      ..sort(
        (a, b) =>
            DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
      );

    final scale = _scale(context);
    double r(double value) => value * scale;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxWidth(context)),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(r(20), r(8), r(20), r(14)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: r(42),
                          height: r(42),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(r(16)),
                            border: Border.all(
                              color: AppColors.inputBorder.withOpacity(0.75),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: r(17),
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: r(14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activity history',
                              style: GoogleFonts.montserrat(
                                color: AppColors.textPrimary,
                                fontSize: r(20),
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: r(3)),
                            Text(
                              '${sortedActivities.length} total updates',
                              style: GoogleFonts.montserrat(
                                color: AppColors.textSecondary,
                                fontSize: r(12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: sortedActivities.isEmpty
                      ? const _EmptyActivities()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            r(16),
                            r(4),
                            r(16),
                            r(24),
                          ),
                          itemCount: sortedActivities.length,
                          separatorBuilder: (_, __) => SizedBox(height: r(2)),
                          itemBuilder: (context, index) {
                            return HomeTransactionTile(
                              activity: sortedActivities[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities();

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

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    double r(double value) => value * scale;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r(28)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: r(72),
            height: r(72),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(r(24)),
              border: Border.all(
                color: AppColors.inputBorder.withOpacity(0.75),
              ),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: AppColors.brandBlueDark,
              size: r(32),
            ),
          ),
          SizedBox(height: r(18)),
          Text(
            'No activities yet',
            style: GoogleFonts.montserrat(
              color: AppColors.textPrimary,
              fontSize: r(16),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: r(6)),
          Text(
            'Your package updates and order activity will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
              fontSize: r(12),
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
