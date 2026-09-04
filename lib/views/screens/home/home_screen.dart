import 'package:flutter/material.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/models/recent_activity_model.dart';
import 'package:wanmac/services/recent_activities_service.dart';
import 'package:wanmac/views/screens/home/all_activities_screen.dart';
import 'package:wanmac/views/screens/home/widgets/home_activity_card.dart';
import 'package:wanmac/views/screens/home/widgets/home_section_header.dart';
import 'package:wanmac/views/screens/home/widgets/home_text_style.dart';
import 'package:wanmac/views/screens/send_package/send_package_intro_screen.dart';
import 'package:wanmac/views/screens/send_package/send_package_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final RecentActivitiesService _recentActivitiesService =
      RecentActivitiesService();

  late Future<List<RecentActivityModel>> _recentActivitiesFuture;

  late final AnimationController _heroEntranceController;
  late final AnimationController _ctaPressController;

  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _ctaPressScale;

  @override
  void initState() {
    super.initState();

    _recentActivitiesFuture = _recentActivitiesService.getRecentActivities();

    _heroEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _ctaPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 120),
    );

    _heroFade = CurvedAnimation(
      parent: _heroEntranceController,
      curve: Curves.easeOutCubic,
    );

    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.045), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _heroEntranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _ctaPressScale = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _ctaPressController, curve: Curves.easeOutCubic),
    );

    _heroEntranceController.forward();
  }

  @override
  void dispose() {
    _heroEntranceController.dispose();
    _ctaPressController.dispose();
    super.dispose();
  }

  bool _isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  bool _isShortHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 700;
  }

  double _contentMaxWidth(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

    if (isTablet && isLandscape) return 1120;
    if (isTablet) return 680;
    if (isLandscape) return 920;
    return double.infinity;
  }

  EdgeInsets _contentPadding(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return EdgeInsets.fromLTRB(
      isTablet ? 32 : 20,
      isLandscape || isShort ? 16 : 20,
      isTablet ? 32 : 20,
      isLandscape ? 20 : 28,
    );
  }

  Future<void> _refreshHome() async {
    setState(() {
      _recentActivitiesFuture = _recentActivitiesService.getRecentActivities();
    });

    await _recentActivitiesFuture;
  }

  void _goToSendPackage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SendPackageIntroScreen()),
    );
  }

  Future<void> _goToAllActivities(BuildContext context) async {
    try {
      final activities = await _recentActivitiesFuture;

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AllActivitiesScreen(activities: activities),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      AppSnackBar.show(
        context,
        message: 'Unable to load activities',
        type: AppSnackBarType.error,
      );
    }
  }

  void _comingSoon(BuildContext context, String feature) {
    AppSnackBar.show(
      context,
      message: '$feature coming soon',
      type: AppSnackBarType.info,
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    String actionText, {
    VoidCallback? onActionTap,
  }) {
    final isTablet = _isTablet(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: sf(
              size: isTablet ? 19 : 17,
              weight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.25,
            ),
          ),
        ),
        if (actionText.isNotEmpty)
          GestureDetector(
            onTap: onActionTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                actionText,
                style: sf(
                  size: isTablet ? 12 : 11,
                  weight: FontWeight.w700,
                  color: AppColors.brandBlueDark,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivitiesSection(BuildContext context) {
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return Padding(
      padding: _contentPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                context,
                'Recent activity',
                'See all',
                onActionTap: () => _goToAllActivities(context),
              ),
              SizedBox(height: isLandscape || isShort ? 12 : 14),
              HomeActivityCard(recentActivitiesFuture: _recentActivitiesFuture),
              SizedBox(height: isLandscape ? 18 : 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeHeroSection(
          heroFade: _heroFade,
          heroSlide: _heroSlide,
          ctaPressController: _ctaPressController,
          ctaPressScale: _ctaPressScale,
          onSendPackage: () => _goToSendPackage(context),
          onComingSoon: (feature) => _comingSoon(context, feature),
        ),
        _buildActivitiesSection(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _refreshHome,
              color: AppColors.brandBlueDark,
              backgroundColor: AppColors.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: _buildHomeContent(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
