import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/services/push_notification_service.dart';
import 'package:wanmac/views/screens/Account/account_screen.dart';
import 'package:wanmac/views/screens/Support/support_screen.dart';
import 'package:wanmac/views/screens/home/home_screen.dart';
import 'package:wanmac/views/screens/order/order_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    OrderScreen(),
    SupportScreen(),
    AccountScreen(),
  ];

  static const Color _navActive = AppColors.brandBlueDark;
  static const Color _navInactive = Color(0xFF9AA1AD);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PushNotificationService.syncTokenAfterLogin();
    });
  }

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isShort = size.height < 700;

    if (isTablet) return 1.10;
    if (isLandscape || isShort) return 0.90;
    return 1.0;
  }

  Widget _assetIcon(
    BuildContext context,
    String asset,
    Color color, {
    double size = 24,
  }) {
    final scale = _scale(context);

    return Image.asset(
      asset,
      width: size * scale,
      height: size * scale,
      color: color,
    );
  }

  Widget _profileIcon(BuildContext context, Color color) {
    final scale = _scale(context);

    return Icon(Icons.person_outline_rounded, size: 25 * scale, color: color);
  }

  Widget _navItem({
    required BuildContext context,
    required int index,
    required String label,
    required Widget icon,
    required Widget activeIcon,
  }) {
    final scale = _scale(context);
    final bool isActive = _currentIndex == index;
    final Color textColor = isActive ? _navActive : _navInactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: SizedBox(
          height: 56 * scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: isActive ? activeIcon : icon,
              ),
              SizedBox(height: 4 * scale),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 11.5 * scale,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              8 * scale,
              7 * scale,
              8 * scale,
              7 * scale,
            ),
            child: SizedBox(
              height: 60 * scale,
              child: Row(
                children: [
                  _navItem(
                    context: context,
                    index: 0,
                    label: 'Home',
                    icon: Icon(
                      Icons.grid_view_rounded,
                      size: 24 * scale,
                      color: _navInactive,
                    ),
                    activeIcon: Icon(
                      Icons.grid_view_rounded,
                      size: 25 * scale,
                      color: _navActive,
                    ),
                  ),
                  _navItem(
                    context: context,
                    index: 1,
                    label: 'Orders',
                    icon: _assetIcon(
                      context,
                      'assets/icons/cube.png',
                      _navInactive,
                      size: 23,
                    ),
                    activeIcon: _assetIcon(
                      context,
                      'assets/icons/cube.png',
                      _navActive,
                      size: 24,
                    ),
                  ),
                  _navItem(
                    context: context,
                    index: 2,
                    label: 'Support',
                    icon: _assetIcon(
                      context,
                      'assets/icons/support.png',
                      _navInactive,
                      size: 23,
                    ),
                    activeIcon: _assetIcon(
                      context,
                      'assets/icons/support.png',
                      _navActive,
                      size: 24,
                    ),
                  ),
                  _navItem(
                    context: context,
                    index: 3,
                    label: 'Profile',
                    icon: _profileIcon(context, _navInactive),
                    activeIcon: _profileIcon(context, _navActive),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
