import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/views/screens/FAQ/faq_screen.dart';
import 'package:wanmac/views/screens/profile_detail/profile_detail_screen.dart';
import 'package:wanmac/views/screens/referralScreen/referral_screen.dart';
import 'package:wanmac/views/screens/termsScreen/terms_screen.dart';

double _scale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

double _maxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isTablet = size.shortestSide >= 600;

  if (isTablet) return 680;

  return double.infinity;
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String firstName = '';
  String lastName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      firstName = prefs.getString('firstName') ?? '';
      lastName = prefs.getString('lastName') ?? '';
    });
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return 'User';
    return '$firstName $lastName'.trim();
  }

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.wanpadi.com/privacy');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: r(20), vertical: r(12)),
              children: [
                _buildTopBar(),
                SizedBox(height: r(20)),
                _buildProfileCard(),
                SizedBox(height: r(24)),

                _buildFlatSectionHeader("Personal"),
                _buildFlatListTile(
                  icon: Icons.person_outline_rounded,
                  title: "Profile Details",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileDetailsScreen(),
                      ),
                    );
                  },
                ),

                _buildFlatListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const ReferralScreen();
                        },
                      ),
                    );
                  },
                  icon: Icons.people_outline,
                  title: "Referral Program",
                  showDivider: false,
                ),

                SizedBox(height: r(18)),

                _buildFlatSectionHeader("Explore"),
                _buildFlatListTile(
                  icon: Icons.help_outline_rounded,
                  title: "FAQs",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FAQScreen(),
                      ),
                    );
                  },
                ),
                _buildFlatListTile(
                  onTap: _openPrivacyPolicy,
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                ),
                _buildFlatListTile(
                  icon: Icons.description_outlined,
                  title: "Terms of Use",
                  showDivider: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: r(24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final s = _scale(context);
    double r(double value) => value * s;

    return Row(
      children: [
        Expanded(
          child: Text(
            "Account",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: r(26),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(28)),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(r(22)),
                child: SizedBox(
                  height: r(84),
                  width: r(84),
                  child: Image.asset(
                    "assets/images/profile_avata.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: r(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: r(6)),
                    Text(
                      "Premium account",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(12),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: r(10)),
                    Wrap(
                      spacing: r(8),
                      runSpacing: r(8),
                      children: [
                        _infoChip(
                          icon: Icons.verified_outlined,
                          label: "Verified",
                          bgColor: AppColors.infoBg,
                          textColor: AppColors.brandBlueDark,
                          iconColor: AppColors.brandBlueDark,
                        ),
                        _infoChip(
                          icon: Icons.star_rounded,
                          label: "5.0 Rating",
                          bgColor: AppColors.brandBlueDark,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r(18)),
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(14)),
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(r(20)),
          //     color: AppColors.brandBlueDark,
          //   ),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: Text(
          //           "9733962811  |  Paystack-Titan",
          //           overflow: TextOverflow.ellipsis,
          //           style: GoogleFonts.montserrat(
          //             color: Colors.white,
          //             fontSize: r(13),
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //       ),
          //       SizedBox(width: r(10)),
          //       Container(
          //         padding: EdgeInsets.all(r(8)),
          //         decoration: BoxDecoration(
          //           color: Colors.white.withOpacity(0.14),
          //           borderRadius: BorderRadius.circular(r(12)),
          //         ),
          //         child: Icon(
          //           Icons.copy_rounded,
          //           color: Colors.white,
          //           size: r(16),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildFlatSectionHeader(String title) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      margin: EdgeInsets.only(bottom: r(2)),
      padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(r(18)),
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: r(16),
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFlatListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(0),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r(8), vertical: r(18)),
              child: Row(
                children: [
                  Container(
                    height: r(40),
                    width: r(40),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: r(22),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: r(12)),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[trailing, SizedBox(width: r(10))],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: r(22),
                  ),
                ],
              ),
            ),
          ),
          if (showDivider)
            Padding(
              padding: EdgeInsets.only(left: r(60)),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.inputBorder,
              ),
            ),
        ],
      ),
    );
  }

  // Widget _countBadge(String text) {
  //   final s = _scale(context);
  //   double r(double value) => value * s;
  //
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: r(12), vertical: r(6)),
  //     decoration: BoxDecoration(
  //       color: AppColors.surface,
  //       borderRadius: BorderRadius.circular(r(999)),
  //       border: Border.all(color: AppColors.infoBorder),
  //     ),
  //     child: Text(
  //       text,
  //       style: GoogleFonts.montserrat(
  //         color: AppColors.brandBlueDark,
  //         fontSize: r(11),
  //         fontWeight: FontWeight.w700,
  //       ),
  //     ),
  //   );
  // }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r(10), vertical: r(8)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(r(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: r(14), color: iconColor),
          SizedBox(width: r(6)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: r(11),
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
