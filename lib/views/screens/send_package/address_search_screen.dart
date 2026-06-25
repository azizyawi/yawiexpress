import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/controllers/send_package_controller.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/models/location_model.dart';
import 'package:wanmac/models/location_suggestion_model.dart';

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

class AddressSearchScreen extends StatefulWidget {
  final String title;
  final bool isPickup;
  final SendPackageController controller;

  const AddressSearchScreen({
    super.key,
    required this.title,
    required this.isPickup,
    required this.controller,
  });

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  static const String _savedLocationsKey = 'wanmac_saved_delivery_locations_v1';

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<_SavedDeliveryLocation> _savedLocations = [];

  SendPackageController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    controller.clearSuggestions(notify: false);
    super.dispose();
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_savedLocationsKey) ?? [];

    final saved = rawList
        .map((raw) {
          try {
            return _SavedDeliveryLocation.fromJson(jsonDecode(raw));
          } catch (_) {
            return null;
          }
        })
        .whereType<_SavedDeliveryLocation>()
        .toList();

    if (!mounted) return;
    setState(() => _savedLocations = saved);
  }

  Future<void> _persistSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _savedLocationsKey,
      _savedLocations.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  void _showSnack(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    if (!mounted) return;

    AppSnackBar.show(context, message: message, type: type);
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.length < 2) {
      controller.clearSuggestions();
      setState(() {});
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 700), () {
      controller.searchAddresses(query);
    });

    setState(() {});
  }

  Future<void> _useCurrentLocation() async {
    final location = await controller.fetchCurrentLocationOnly();

    if (!mounted) return;

    if (location != null) {
      Navigator.pop(context, location);
    } else if (controller.locationError != null) {
      _showSnack(controller.locationError!, type: AppSnackBarType.error);
    }
  }

  Future<void> _onSuggestionTap(LocationSuggestionModel suggestion) async {
    final result = await controller.selectSuggestion(suggestion);

    if (!mounted) return;

    if (result != null) {
      Navigator.pop(context, result);
    } else if (controller.locationError != null) {
      _showSnack(controller.locationError!, type: AppSnackBarType.error);
    }
  }

  void _onRecentTap(LocationModel location) {
    Navigator.pop(context, location);
  }

  void _onSavedTap(_SavedDeliveryLocation item) {
    Navigator.pop(context, item.location);
  }

  Future<void> _saveSuggestion(LocationSuggestionModel suggestion) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final location = await controller.selectSuggestion(suggestion);

    if (!mounted) return;

    if (location == null) {
      if (controller.locationError != null) {
        _showSnack(controller.locationError!, type: AppSnackBarType.error);
      }
      return;
    }

    await _showSaveLocationSheet(location);
  }

  Future<void> _showSaveLocationSheet(LocationModel location) async {
    final label = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaveDeliveryLocationSheet(location: location),
    );

    if (!mounted) return;
    if (label == null || label.trim().isEmpty) return;

    final newLocation = _SavedDeliveryLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label.trim(),
      location: location,
    );

    final existsIndex = _savedLocations.indexWhere(
      (item) =>
          item.location.address.trim().toLowerCase() ==
          location.address.trim().toLowerCase(),
    );

    setState(() {
      if (existsIndex >= 0) {
        _savedLocations[existsIndex] = newLocation;
      } else {
        _savedLocations.insert(0, newLocation);
      }

      if (_savedLocations.length > 12) {
        _savedLocations = _savedLocations.take(12).toList();
      }
    });

    await _persistSavedLocations();

    if (!mounted) return;

    _showSnack('Delivery location saved', type: AppSnackBarType.success);
  }

  Future<void> _removeSavedLocation(_SavedDeliveryLocation item) async {
    final shouldRemove = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RemoveLocationSheet(
        title: item.label,
        subtitle: _locationTitle(item.location),
      ),
    );

    if (!mounted) return;
    if (shouldRemove != true) return;

    setState(() {
      _savedLocations.removeWhere((location) => location.id == item.id);
    });

    await _persistSavedLocations();

    if (!mounted) return;

    _showSnack('Delivery location removed', type: AppSnackBarType.success);
  }

  void _showSaveNewAddressHint() {
    FocusManager.instance.primaryFocus?.unfocus();

    _searchController.clear();
    controller.clearSuggestions();
    setState(() {});

    _showSnack(
      'Search for a delivery location, then tap the bookmark icon.',
      type: AppSnackBarType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final hasQuery = _searchController.text.trim().isNotEmpty;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _maxContentWidth(context),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(r(20), r(18), r(20), r(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: r(12)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.montserrat(
                                fontSize: r(22),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: r(44),
                              height: r(44),
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: r(20),
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r(18)),
                      _SearchField(
                        controller: _searchController,
                        onChanged: _onChanged,
                        isSearching: controller.isSearchingAddresses,
                      ),
                      SizedBox(height: r(12)),
                      Expanded(
                        child: hasQuery
                            ? _buildSuggestions()
                            : _buildDefaultContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    final s = _scale(context);
    double r(double value) => value * s;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (widget.isPickup) ...[
          _ActionRow(
            icon: Icons.my_location_rounded,
            title: 'Use your current location',
            trailing: controller.isGettingCurrentLocation
                ? SizedBox(
                    width: r(18),
                    height: r(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandBlue,
                    ),
                  )
                : null,
            onTap: _useCurrentLocation,
          ),
          const _SectionDivider(),
        ],
        _ActionRow(
          icon: Icons.bookmark_add_outlined,
          title: 'Save delivery location',
          onTap: _showSaveNewAddressHint,
        ),
        if (_savedLocations.isNotEmpty) ...[
          SizedBox(height: r(18)),
          const _SectionLabel(title: 'Saved delivery locations'),
          SizedBox(height: r(4)),
          ..._savedLocations.map(
            (item) => Column(
              children: [
                _SavedLocationRow(
                  label: item.label,
                  title: _locationTitle(item.location),
                  subtitle:
                      item.location.shortAddress ?? item.location.city ?? '',
                  onTap: () => _onSavedTap(item),
                  onRemove: () => _removeSavedLocation(item),
                ),
                const _SectionDivider(),
              ],
            ),
          ),
        ],
        if (controller.recentAddresses
            .where(
              (location) => !_savedLocations.any(
                (saved) =>
                    saved.location.address.trim().toLowerCase() ==
                    location.address.trim().toLowerCase(),
              ),
            )
            .isNotEmpty) ...[
          SizedBox(height: r(18)),
          const _SectionLabel(title: 'Recent delivery locations'),
          SizedBox(height: r(4)),
          ...controller.recentAddresses
              .where(
                (location) => !_savedLocations.any(
                  (saved) =>
                      saved.location.address.trim().toLowerCase() ==
                      location.address.trim().toLowerCase(),
                ),
              )
              .map(
                (location) => Column(
                  children: [
                    _AddressRow(
                      title: _locationTitle(location),
                      subtitle:
                          location.shortAddress != null &&
                              !_locationTitle(location).toLowerCase().contains(
                                location.shortAddress!.trim().toLowerCase(),
                              )
                          ? location.shortAddress!
                          : (location.city ?? ''),
                      onTap: () => _onRecentTap(location),
                    ),
                    const _SectionDivider(),
                  ],
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildSuggestions() {
    final s = _scale(context);
    double r(double value) => value * s;

    final query = _searchController.text.trim();
    final hasSuggestions = controller.suggestions.isNotEmpty;
    final isSearching = controller.isSearchingAddresses;

    if (query.length < 2) {
      return const _EmptySearchState(
        icon: Icons.search_rounded,
        title: 'Search for a delivery location',
        subtitle: 'Enter at least 2 characters to find nearby places',
      );
    }

    if (!hasSuggestions && isSearching) {
      return const SizedBox.shrink();
    }

    if (!hasSuggestions) {
      return const _EmptySearchState(
        icon: Icons.location_off_outlined,
        title: 'No matching locations found',
        subtitle: 'Try a landmark, street name, or business name',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: controller.suggestions.length,
      separatorBuilder: (_, __) => const _SectionDivider(),
      itemBuilder: (context, index) {
        final suggestion = controller.suggestions[index];

        return _AddressRow(
          title: [
            suggestion.title,
            suggestion.subtitle,
          ].where((e) => e.trim().isNotEmpty).join(', '),
          subtitle: _extractArea(suggestion.subtitle),
          onTap: () => _onSuggestionTap(suggestion),
          trailing: GestureDetector(
            onTap: () => _saveSuggestion(suggestion),
            child: Container(
              width: r(38),
              height: r(38),
              decoration: BoxDecoration(
                color: AppColors.brandBlueDark.withOpacity(0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandBlueDark.withOpacity(0.12),
                ),
              ),
              child: Icon(
                Icons.bookmark_add_outlined,
                size: r(19),
                color: AppColors.brandBlueDark,
              ),
            ),
          ),
        );
      },
    );
  }

  String _locationTitle(LocationModel location) {
    final name = location.name?.trim() ?? '';
    final address = location.address.trim();
    final shortAddress = location.shortAddress?.trim() ?? '';

    if (name.isNotEmpty && address.isNotEmpty) {
      final normalizedName = name.toLowerCase();
      final normalizedAddress = address.toLowerCase();

      if (normalizedAddress.contains(normalizedName) ||
          normalizedName.contains(normalizedAddress)) {
        return address;
      }

      return address;
    }

    if (name.isNotEmpty && shortAddress.isNotEmpty) {
      return '$name, $shortAddress';
    }

    if (name.isNotEmpty) return name;
    if (address.isNotEmpty) return address;
    if (shortAddress.isNotEmpty) return shortAddress;

    return 'Delivery location';
  }

  String _extractArea(String subtitle) {
    if (subtitle.trim().isEmpty) return '';

    final parts = subtitle.split(',');

    if (parts.length >= 2) {
      return '${parts.first.trim()} ${parts[1].trim()}';
    }

    return subtitle.trim();
  }
}

class _SavedDeliveryLocation {
  final String id;
  final String label;
  final LocationModel location;

  const _SavedDeliveryLocation({
    required this.id,
    required this.label,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'location': location.toJson()};
  }

  factory _SavedDeliveryLocation.fromJson(Map<String, dynamic> json) {
    return _SavedDeliveryLocation(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Delivery location',
      location: LocationModel.fromJson(
        Map<String, dynamic>.from(json['location'] as Map),
      ),
    );
  }
}

class _SaveDeliveryLocationSheet extends StatefulWidget {
  final LocationModel location;

  const _SaveDeliveryLocationSheet({required this.location});

  @override
  State<_SaveDeliveryLocationSheet> createState() =>
      _SaveDeliveryLocationSheetState();
}

class _SaveDeliveryLocationSheetState
    extends State<_SaveDeliveryLocationSheet> {
  final TextEditingController _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _labelController.text.trim();
    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.of(context).pop(text.isEmpty ? 'Delivery location' : text);
  }

  String _locationTitle(LocationModel location) {
    final name = location.name?.trim() ?? '';
    final address = location.address.trim();
    final shortAddress = location.shortAddress?.trim() ?? '';

    if (name.isNotEmpty && address.isNotEmpty) {
      if (address.toLowerCase().contains(name.toLowerCase())) {
        return address;
      }
      return '$name, $address';
    }

    if (name.isNotEmpty && shortAddress.isNotEmpty) {
      return '$name, $shortAddress';
    }

    if (name.isNotEmpty) return name;
    if (address.isNotEmpty) return address;
    if (shortAddress.isNotEmpty) return shortAddress;

    return 'Delivery location';
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
          child: Container(
            padding: EdgeInsets.fromLTRB(r(20), r(12), r(20), r(22)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(r(28))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: r(42),
                      height: r(5),
                      decoration: BoxDecoration(
                        color: AppColors.inputBorder,
                        borderRadius: BorderRadius.circular(r(100)),
                      ),
                    ),
                  ),
                  SizedBox(height: r(20)),
                  Text(
                    'Save delivery location',
                    style: GoogleFonts.montserrat(
                      fontSize: r(20),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: r(6)),
                  Text(
                    _locationTitle(widget.location),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(13),
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: r(18)),
                  Container(
                    height: r(56),
                    padding: EdgeInsets.symmetric(horizontal: r(14)),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(r(16)),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: TextField(
                      controller: _labelController,
                      autofocus: true,
                      cursorColor: AppColors.brandBlue,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: GoogleFonts.montserrat(
                        fontSize: r(15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Label e.g. Customer, Shop, Office',
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: r(14),
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r(18)),
                  SizedBox(
                    width: double.infinity,
                    height: r(56),
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.brandBlueDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r(18)),
                        ),
                      ),
                      child: Text(
                        'Save location',
                        style: GoogleFonts.montserrat(
                          fontSize: r(15),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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

class _RemoveLocationSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RemoveLocationSheet({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
        child: Container(
          padding: EdgeInsets.fromLTRB(r(20), r(12), r(20), r(22)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(r(28))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: r(42),
                  height: r(5),
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(r(100)),
                  ),
                ),
                SizedBox(height: r(20)),
                Icon(
                  Icons.delete_outline_rounded,
                  size: r(34),
                  color: AppColors.error,
                ),
                SizedBox(height: r(12)),
                Text(
                  'Remove delivery location?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: r(18),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: r(8)),
                Text(
                  '$title\n$subtitle',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(13),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: r(22)),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: r(54),
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.inputBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r(17)),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: r(12)),
                    Expanded(
                      child: SizedBox(
                        height: r(54),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r(17)),
                            ),
                          ),
                          child: Text(
                            'Remove',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isSearching;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final isShort =
        MediaQuery.sizeOf(context).height < 700 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Container(
      constraints: BoxConstraints(minHeight: r(isShort ? 48 : 58)),
      padding: EdgeInsets.symmetric(
        horizontal: r(14),
        vertical: r(isShort ? 1 : 0),
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(r(16)),
        border: Border.all(color: AppColors.inputBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: r(isShort ? 20 : 22),
            color: AppColors.textSecondary,
          ),
          SizedBox(width: r(10)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.brandBlue,
              textInputAction: TextInputAction.search,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.montserrat(
                fontSize: r(isShort ? 14 : 15),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: TextInputDecorationStyles.addressSearch(context),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isSearching
                ? SizedBox(
                    key: const ValueKey('loader'),
                    width: r(16),
                    height: r(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandBlue,
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('empty'),
                    width: r(16),
                    height: r(16),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Text(
      title.toUpperCase(),
      style: GoogleFonts.montserrat(
        fontSize: r(11),
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptySearchState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: r(58),
              height: r(58),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brandBlue, size: r(26)),
            ),
            SizedBox(height: r(14)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: r(15),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: r(6)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: r(13),
                height: 1.45,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r(16)),
        child: Row(
          children: [
            Container(
              width: r(28),
              alignment: Alignment.center,
              child: Icon(icon, size: r(21), color: AppColors.brandBlue),
            ),
            SizedBox(width: r(8)),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  color: AppColors.brandBlue,
                  fontSize: r(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _AddressRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: r(28),
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.location_on_rounded,
                size: r(21),
                color: AppColors.brandBlue,
              ),
            ),
            SizedBox(width: r(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: r(16),
                      height: 1.45,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    SizedBox(height: r(6)),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: r(14),
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[SizedBox(width: r(10)), trailing!],
          ],
        ),
      ),
    );
  }
}

class _SavedLocationRow extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedLocationRow({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r(14)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: r(34),
              height: r(34),
              decoration: BoxDecoration(
                color: AppColors.brandBlueDark.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_rounded,
                size: r(18),
                color: AppColors.brandBlueDark,
              ),
            ),
            SizedBox(width: r(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(14),
                      color: AppColors.brandBlueDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: r(5)),
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: r(15),
                      height: 1.45,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    SizedBox(height: r(5)),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: r(13),
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: r(8)),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: r(36),
                height: r(36),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: r(19),
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.inputBorder);
  }
}

class TextInputDecorationStyles {
  static InputDecoration addressSearch(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final isShort =
        MediaQuery.sizeOf(context).height < 700 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return InputDecoration(
      hintText: 'Enter a delivery location',
      border: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: r(isShort ? 8 : 12)),
      hintStyle: GoogleFonts.montserrat(
        color: AppColors.textHint,
        fontSize: r(isShort ? 14 : 15),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
