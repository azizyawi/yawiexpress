import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/models/order_model.dart';
import 'package:wanmac/services/get_customer_order_service.dart';
import 'package:wanmac/views/screens/wanny/wanny_chat_screen.dart';

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

double _maxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isTablet = size.shortestSide >= 600;
  final isLandscape =
      MediaQuery.orientationOf(context) == Orientation.landscape;

  if (isTablet && isLandscape) return 900;
  if (isTablet) return 680;
  if (isLandscape) return 760;

  return double.infinity;
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  OrderModel? _recentOrder;
  bool _isLoadingOrder = true;

  @override
  void initState() {
    super.initState();
    _loadRecentOrder();
  }

  Future<void> _loadRecentOrder() async {
    try {
      final orders = await OrderApiService.getCustomerOrders();

      orders.sort(
        (a, b) => b.timestamps.createdAt.compareTo(a.timestamps.createdAt),
      );

      if (!mounted) return;

      setState(() {
        _recentOrder = orders.isNotEmpty ? orders.first : null;
        _isLoadingOrder = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _recentOrder = null;
        _isLoadingOrder = false;
      });
    }
  }

  Future<void> _openWannyChat(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('userId') ?? '';
    final firstName = prefs.getString('firstName') ?? '';

    final name = firstName.trim();

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WannyChatScreen(
          userId: userId.isNotEmpty
              ? userId
              : DateTime.now().millisecondsSinceEpoch.toString(),
          userName: name.isNotEmpty ? name : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
            child: Column(
              children: [
                _SupportHeader(onChatTap: () => _openWannyChat(context)),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(r(20), r(18), r(20), r(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help with a recent delivery',
                          style: _T.text(
                            context,
                            15,
                            FontWeight.w500,
                            AppColors.textHint,
                          ),
                        ),
                        SizedBox(height: r(14)),
                        if (_isLoadingOrder)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: r(18)),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.brandBlueDark,
                              ),
                            ),
                          )
                        else if (_recentOrder != null)
                          _RecentOrderCard(order: _recentOrder!)
                        else
                          _NoRecentOrderCard(
                            onTap: () => _openWannyChat(context),
                          ),
                        SizedBox(height: r(24)),
                        Divider(color: AppColors.inputBorder, thickness: 1),
                        SizedBox(height: r(22)),
                        Text(
                          'Help with something else',
                          style: _T.text(
                            context,
                            15,
                            FontWeight.w500,
                            AppColors.textHint,
                          ),
                        ),
                        SizedBox(height: r(16)),
                        _OtherHelpCard(onTap: () => _openWannyChat(context)),
                      ],
                    ),
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

class _SupportHeader extends StatelessWidget {
  final VoidCallback onChatTap;

  const _SupportHeader({required this.onChatTap});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final size = MediaQuery.sizeOf(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isShort = size.height < 700;

    final headerHeight = isLandscape || isShort ? r(170) : r(215);

    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.brandBlueDark),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _HeaderPatternPainter()),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(r(20), r(20), r(20), r(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isLandscape || isShort ? r(8) : r(18)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Hello, how\ncan we help?',
                        style: _T.text(
                          context,
                          28,
                          FontWeight.w700,
                          AppColors.surface,
                          height: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(width: r(12)),
                    _ChatButton(onTap: onChatTap),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: r(10),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withOpacity(0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ChatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(r(28)),
      child: InkWell(
        borderRadius: BorderRadius.circular(r(28)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r(18), vertical: r(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: r(18),
                color: AppColors.brandBlueDark,
              ),
              SizedBox(width: r(8)),
              Text(
                'Chat with Wanny',
                style: _T.text(context, 15, FontWeight.w700, AppColors.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final OrderModel order;

  const _RecentOrderCard({required this.order});

  String _shortOrderId(String id) {
    final clean = id.trim();
    if (clean.isEmpty) return 'ORDER';
    if (clean.length <= 8) return clean.toUpperCase();
    return clean.substring(0, 8).toUpperCase();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Awaiting payment';
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'arrived_pickup':
        return 'At pickup';
      case 'picked_up':
        return 'In transit';
      case 'arrived_delivery':
        return 'At destination';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Updated';
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '--';

    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final hour = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'pm' : 'am';

      return '${dateTime.day}/${dateTime.month}/${dateTime.year} • $hour:$minute $period';
    } catch (_) {
      return '--';
    }
  }

  Future<void> _copyOrderId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: order.orderId));

    if (!context.mounted) return;

    AppSnackBar.show(
      context,
      message: 'Order ID copied',
      type: AppSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final pickup = order.pickup.address.trim().isNotEmpty
        ? order.pickup.address.trim()
        : 'Pickup location';

    final dropoff = order.delivery.address.trim().isNotEmpty
        ? order.delivery.address.trim()
        : 'Dropoff location';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r(18), vertical: r(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(16)),
        border: Border.all(color: AppColors.inputBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: r(12),
            height: r(12),
            margin: EdgeInsets.only(top: r(5)),
            decoration: const BoxDecoration(
              color: AppColors.brandBlueDark,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pickup → $dropoff',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.text(
                    context,
                    12.5,
                    FontWeight.w600,
                    AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: r(4)),
                Text(
                  '${_statusLabel(order.status)} on ${_formatDate(order.timestamps.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.text(
                    context,
                    11.8,
                    FontWeight.w500,
                    AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: r(10)),
          GestureDetector(
            onTap: () => _copyOrderId(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r(9), vertical: r(6)),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(r(10)),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${_shortOrderId(order.orderId)}',
                    style: _T.text(
                      context,
                      11.5,
                      FontWeight.w700,
                      AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: r(5)),
                  Icon(
                    Icons.copy_rounded,
                    size: r(13),
                    color: AppColors.textSecondary,
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

class _NoRecentOrderCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NoRecentOrderCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(r(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(r(16)),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r(16)),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Container(
                width: r(46),
                height: r(46),
                decoration: const BoxDecoration(
                  color: AppColors.infoBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.brandBlueDark,
                  size: r(23),
                ),
              ),
              SizedBox(width: r(14)),
              Expanded(
                child: Text(
                  'No recent delivery found. Chat with Wanny if you still need help.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _T.text(
                    context,
                    13.5,
                    FontWeight.w500,
                    AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brandBlueDark,
                size: r(24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtherHelpCard extends StatelessWidget {
  final VoidCallback onTap;

  const _OtherHelpCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(r(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(r(16)),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r(16)),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Container(
                width: r(48),
                height: r(48),
                decoration: const BoxDecoration(
                  color: AppColors.infoBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.brandBlueDark,
                  size: r(24),
                ),
              ),
              SizedBox(width: r(14)),
              Expanded(
                child: Text(
                  'Need help with your delivery? Chat with Wanny.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _T.text(
                    context,
                    14,
                    FontWeight.w500,
                    AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brandBlueDark,
                size: r(24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  const _HeaderPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.25,
        0,
        size.width * 0.5,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.4,
        size.width,
        size.height * 0.1,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _T {
  static TextStyle text(
    BuildContext context,
    double size,
    FontWeight weight,
    Color color, {
    double? height,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size * _scale(context),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.08,
    );
  }
}
