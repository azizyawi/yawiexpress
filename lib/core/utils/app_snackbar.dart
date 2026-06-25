import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppSnackBarType { success, error, info, warning }

double _scale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

class AppSnackBar {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    _removeCurrent();

    final overlay = Overlay.of(context);
    final style = _resolveStyle(type);

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _TopSnackBarOverlay(
        message: message,
        style: style,
        onDismissed: () {
          if (_currentEntry == entry) {
            _removeCurrent();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      if (_currentEntry == entry) {
        _removeCurrent();
      }
    });
  }

  static void _removeCurrent() {
    _timer?.cancel();
    _timer = null;

    try {
      _currentEntry?.remove();
    } catch (_) {}

    _currentEntry = null;
  }

  static _SnackBarStyle _resolveStyle(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return const _SnackBarStyle(
          backgroundColor: Color(0xFFE6FAEC),
          borderColor: Color(0xFF72E3A0),
          textColor: Color(0xFF126B39),
          iconColor: Color(0xFF16A34A),
          iconContainerColor: Color(0xFFD7F8E2),
          closeColor: Color(0xFF0F3D2A),
          icon: Icons.check_circle_rounded,
        );

      case AppSnackBarType.error:
        return const _SnackBarStyle(
          backgroundColor: Color(0xFFFFEEEE),
          borderColor: Color(0xFFFFB4B4),
          textColor: Color(0xFF9F1239),
          iconColor: Color(0xFFFF6B6B),
          iconContainerColor: Color(0xFFFFDFDF),
          closeColor: Color(0xFF7F1D1D),
          icon: Icons.cancel_rounded,
        );

      case AppSnackBarType.warning:
        return const _SnackBarStyle(
          backgroundColor: Color(0xFFFFF7E6),
          borderColor: Color(0xFFFFD98A),
          textColor: Color(0xFF7A4B00),
          iconColor: Color(0xFFB7791F),
          iconContainerColor: Color(0xFFFFEFC7),
          closeColor: Color(0xFF7A4B00),
          icon: Icons.info_rounded,
        );

      case AppSnackBarType.info:
        return const _SnackBarStyle(
          backgroundColor: Color(0xFFF0F4FF),
          borderColor: Color(0xFFC7D2FE),
          textColor: Color(0xFF1E2FA8),
          iconColor: Color(0xFF2F49D1),
          iconContainerColor: Color(0xFFE2E8FF),
          closeColor: Color(0xFF1E2FA8),
          icon: Icons.info_rounded,
        );
    }
  }
}

class _TopSnackBarOverlay extends StatefulWidget {
  final String message;
  final _SnackBarStyle style;
  final VoidCallback onDismissed;

  const _TopSnackBarOverlay({
    required this.message,
    required this.style,
    required this.onDismissed,
  });

  @override
  State<_TopSnackBarOverlay> createState() => _TopSnackBarOverlayState();
}

class _TopSnackBarOverlayState extends State<_TopSnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.55), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;

    await _controller.reverse();

    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final topPadding = MediaQuery.paddingOf(context).top + r(8);

    return Positioned(
      top: topPadding,
      left: r(16),
      right: r(16),
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismissed(),
              child: Container(
                constraints: BoxConstraints(minHeight: r(64)),
                padding: EdgeInsets.fromLTRB(r(16), r(13), r(12), r(13)),
                decoration: BoxDecoration(
                  color: widget.style.backgroundColor,
                  borderRadius: BorderRadius.circular(r(14)),
                  border: Border.all(
                    color: widget.style.borderColor,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.style.borderColor.withOpacity(0.35),
                      blurRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: r(22),
                      height: r(22),
                      decoration: BoxDecoration(
                        color: widget.style.iconColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.style.icon,
                        size: r(15),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: r(12)),
                    Expanded(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: r(13),
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                          color: widget.style.textColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    SizedBox(width: r(10)),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        width: r(28),
                        height: r(28),
                        alignment: Alignment.center,
                        color: Colors.transparent,
                        child: Icon(
                          Icons.close_rounded,
                          size: r(22),
                          color: widget.style.closeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackBarStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final Color iconContainerColor;
  final Color closeColor;
  final IconData icon;

  const _SnackBarStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.iconContainerColor,
    required this.closeColor,
    required this.icon,
  });
}
