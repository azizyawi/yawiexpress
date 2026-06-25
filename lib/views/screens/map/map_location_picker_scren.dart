import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/models/location_model.dart';
import 'package:wanmac/models/location_suggestion_model.dart';
import 'package:wanmac/services/location_service.dart';

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

  if (size.shortestSide >= 600) {
    return 680;
  }

  return double.infinity;
}

class MapLocationPickerScreen extends StatefulWidget {
  final String title;
  final LocationModel? initialLocation;

  const MapLocationPickerScreen({
    super.key,
    required this.title,
    this.initialLocation,
  });

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;
  Timer? _mapDebounce;
  Timer? _searchDebounce;

  static const LatLng _defaultCenter = LatLng(6.3350, 5.6037);

  static const double _minBeninLat = 6.20;
  static const double _maxBeninLat = 6.45;
  static const double _minBeninLng = 5.50;
  static const double _maxBeninLng = 5.75;

  static const double _initialZoom = 16.0;
  static const double _selectedZoom = 16.8;

  late LatLng _mapCenter;
  LocationModel? _selectedLocation;
  List<LocationSuggestionModel> _suggestions = [];

  bool _isResolvingAddress = false;
  bool _isSearching = false;
  bool _isMapMoving = false;
  bool _hasUserPickedLocation = false;
  bool _showSuggestions = false;

  bool _isBusinessSelection = false;
  bool _lockDisplayName = false;
  bool _ignoreProgrammaticCameraMove = false;
  bool _ignoreSearchChange = false;

  String? _errorText;
  String? _selectedDisplayName;

  @override
  void initState() {
    super.initState();

    if (widget.initialLocation != null) {
      _mapCenter = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _selectedLocation = widget.initialLocation;
      _hasUserPickedLocation = true;
      _selectedDisplayName = widget.initialLocation!.shortAddress;
      _searchController.text = widget.initialLocation!.shortAddress ?? '';
    } else {
      _mapCenter = _defaultCenter;
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _mapDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  bool _isWithinCoverage(double lat, double lng) {
    return lat >= _minBeninLat &&
        lat <= _maxBeninLat &&
        lng >= _minBeninLng &&
        lng <= _maxBeninLng;
  }

  bool _isRoadLikeQuery(String value) {
    final text = value.trim().toLowerCase();

    return text.contains('road') ||
        text.contains(' rd') ||
        text == 'rd' ||
        text.contains('street') ||
        text.contains(' st') ||
        text == 'st' ||
        text.contains('avenue') ||
        text.contains(' ave') ||
        text == 'ave' ||
        text.contains('close') ||
        text.contains('crescent') ||
        text.contains('lane') ||
        text.contains('drive') ||
        text.contains('junction');
  }

  void _setSearchTextSilently(String value) {
    _ignoreSearchChange = true;
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _ignoreSearchChange = false;
  }

  void _onSearchChanged() {
    if (_ignoreSearchChange) return;

    final query = _searchController.text.trim();

    _searchDebounce?.cancel();

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      await _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
      _errorText = null;
    });

    try {
      final results = await _locationService.searchAddresses(query);

      if (!mounted) return;

      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _onSuggestionTap(LocationSuggestionModel suggestion) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = false;
      _showSuggestions = false;
      _errorText = null;
    });

    try {
      final place = await _locationService.getPlaceDetails(suggestion.placeId);
      final target = LatLng(place.latitude, place.longitude);

      if (!_isWithinCoverage(target.latitude, target.longitude)) {
        setState(() {
          _errorText = 'Selected location is outside Benin City coverage area';
          _hasUserPickedLocation = false;
        });
        return;
      }

      final isRoadLike = _isRoadLikeQuery(suggestion.title);

      _mapCenter = target;
      _selectedLocation = place;
      _hasUserPickedLocation = true;
      _isBusinessSelection = !isRoadLike;
      _lockDisplayName = !isRoadLike;

      _selectedDisplayName = suggestion.title.trim().isNotEmpty
          ? suggestion.title.trim()
          : (place.shortAddress ?? 'Selected location');

      _setSearchTextSilently(_selectedDisplayName ?? '');

      _ignoreProgrammaticCameraMove = true;

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: _selectedZoom),
        ),
      );

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _mapCenter = position.target;

    if (_ignoreProgrammaticCameraMove) {
      _isMapMoving = true;
      return;
    }

    if (_lockDisplayName) {
      _lockDisplayName = false;
      _isBusinessSelection = false;
    }

    if (!_isMapMoving) {
      setState(() {
        _isMapMoving = true;
      });
    }
  }

  void _onCameraIdle() {
    if (_ignoreProgrammaticCameraMove) {
      _ignoreProgrammaticCameraMove = false;
      _isMapMoving = false;
      return;
    }

    if (!_isMapMoving) return;

    _mapDebounce?.cancel();
    _mapDebounce = Timer(const Duration(milliseconds: 350), () async {
      await _resolveCenterAddress(
        fromUserInteraction: true,
        updateDisplayName: true,
        updateSearchField: true,
      );
    });
  }

  Future<void> _resolveCenterAddress({
    required bool fromUserInteraction,
    required bool updateDisplayName,
    required bool updateSearchField,
  }) async {
    if (!mounted) return;

    if (!_isWithinCoverage(_mapCenter.latitude, _mapCenter.longitude)) {
      setState(() {
        _isResolvingAddress = false;
        _isMapMoving = false;
        _hasUserPickedLocation = false;
        _selectedLocation = null;
        _selectedDisplayName = null;
        _isBusinessSelection = false;
        _errorText = 'Selected location is outside Benin City coverage area';
      });
      return;
    }

    setState(() {
      _isResolvingAddress = true;
      _isMapMoving = false;
      _errorText = null;
      _showSuggestions = false;
    });

    try {
      final location = await _locationService.reverseGeocode(
        latitude: _mapCenter.latitude,
        longitude: _mapCenter.longitude,
        preferExactAddress: fromUserInteraction,
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation = location;
        _isResolvingAddress = false;

        if (updateDisplayName) {
          _selectedDisplayName =
              (location.shortAddress != null &&
                  location.shortAddress!.trim().isNotEmpty)
              ? location.shortAddress!.trim()
              : 'Selected location';
        }

        if (updateSearchField) {
          _setSearchTextSilently(_selectedDisplayName ?? '');
        }

        if (fromUserInteraction) {
          _hasUserPickedLocation = true;
          _isBusinessSelection = false;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isResolvingAddress = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
        if (fromUserInteraction) {
          _hasUserPickedLocation = false;
        }
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isResolvingAddress = true;
      _errorText = null;
      _showSuggestions = false;
    });

    try {
      final current = await _locationService.getCurrentLocation();
      final target = LatLng(current.latitude, current.longitude);

      if (!_isWithinCoverage(target.latitude, target.longitude)) {
        setState(() {
          _isResolvingAddress = false;
          _errorText = 'Current location is outside Benin City coverage area';
          _hasUserPickedLocation = false;
        });
        return;
      }

      _mapCenter = target;
      _selectedLocation = current;
      _hasUserPickedLocation = true;
      _isBusinessSelection = false;
      _lockDisplayName = false;

      _selectedDisplayName =
          (current.shortAddress != null &&
              current.shortAddress!.trim().isNotEmpty)
          ? current.shortAddress!.trim()
          : 'Current location';

      _setSearchTextSilently(_selectedDisplayName ?? '');
      _ignoreProgrammaticCameraMove = true;

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: _selectedZoom),
        ),
      );

      if (!mounted) return;

      setState(() {
        _isResolvingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isResolvingAddress = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _confirmSelection() {
    if (_selectedLocation == null ||
        _isResolvingAddress ||
        !_hasUserPickedLocation) {
      return;
    }

    Navigator.pop(context, _selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final initialTarget = widget.initialLocation != null
        ? LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          )
        : _defaultCenter;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: _initialZoom,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(14.5, 19.0),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _maxContentWidth(context),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(r(16), r(10), r(16), 0),
                      child: Column(
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: r(20),
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: r(14)),
                          Row(
                            children: [
                              _CircleActionButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              SizedBox(width: r(12)),
                              Expanded(
                                child: Container(
                                  height: r(56),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(r(18)),
                                    border: Border.all(
                                      color: AppColors.inputBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: r(18),
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    textInputAction: TextInputAction.search,
                                    style: TextStyle(
                                      fontSize: r(14),
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search apartments, streets, places',
                                      hintStyle: TextStyle(
                                        fontSize: r(14),
                                        color: AppColors.textHint,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: AppColors.textSecondary,
                                        size: r(22),
                                      ),
                                      suffixIcon: _searchController.text.isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _suggestions = [];
                                                  _showSuggestions = false;
                                                });
                                              },
                                              icon: Icon(
                                                Icons.close_rounded,
                                                color: AppColors.textSecondary,
                                                size: r(20),
                                              ),
                                            ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: r(16),
                                      ),
                                    ),
                                    onTap: () {
                                      if (_suggestions.isNotEmpty) {
                                        setState(() {
                                          _showSuggestions = true;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (_showSuggestions)
                      Padding(
                        padding: EdgeInsets.fromLTRB(r(16), r(8), r(16), 0),
                        child: Container(
                          constraints: BoxConstraints(maxHeight: r(260)),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(r(18)),
                            border: Border.all(color: AppColors.inputBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: r(18),
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _isSearching
                              ? Padding(
                                  padding: EdgeInsets.all(r(18)),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: r(18),
                                        height: r(18),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.brandBlueDark,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: r(12)),
                                      Text(
                                        'Searching places...',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: r(13),
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _suggestions.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.all(r(18)),
                                  child: Text(
                                    'No address found',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: r(13),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.symmetric(vertical: r(8)),
                                  shrinkWrap: true,
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: AppColors.inputBorder,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = _suggestions[index];

                                    return ListTile(
                                      onTap: () => _onSuggestionTap(item),
                                      leading: Container(
                                        width: r(40),
                                        height: r(40),
                                        decoration: BoxDecoration(
                                          color: AppColors.infoBg,
                                          borderRadius: BorderRadius.circular(
                                            r(12),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.place_outlined,
                                          color: AppColors.brandBlueDark,
                                          size: r(20),
                                        ),
                                      ),
                                      title: Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: r(14),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      subtitle: Text(
                                        item.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: r(12),
                                          color: AppColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: Offset(0, -r(26)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: _isMapMoving ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        _isBusinessSelection
                            ? Icons.location_on
                            : Icons.location_pin,
                        size: r(58),
                        color: AppColors.brandBlueDark,
                      ),
                    ),
                    Container(
                      width: r(12),
                      height: r(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: r(10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: r(16),
            bottom: r(208),
            child: _CircleActionButton(
              icon: Icons.my_location_rounded,
              onTap: _useCurrentLocation,
            ),
          ),

          Positioned(
            left: r(16),
            right: r(16),
            bottom: r(20),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _maxContentWidth(context),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(r(24)),
                    border: Border.all(
                      color: AppColors.brandBlueDark.withOpacity(0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: r(24),
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: r(16),
                          vertical: r(12),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(r(24)),
                          ),
                        ),
                        child: Text(
                          'Drag the map to your preferred location',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: r(14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBlueDark,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          r(16),
                          r(14),
                          r(16),
                          r(14),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: r(2)),
                                  child: Icon(
                                    _isBusinessSelection
                                        ? Icons.storefront_rounded
                                        : Icons.place_rounded,
                                    color: AppColors.brandBlueDark,
                                    size: r(24),
                                  ),
                                ),
                                SizedBox(width: r(10)),
                                Expanded(child: _buildAddressState(context)),
                              ],
                            ),
                            SizedBox(height: r(16)),
                            SizedBox(
                              width: double.infinity,
                              height: r(56),
                              child: ElevatedButton(
                                onPressed:
                                    (_selectedLocation == null ||
                                        _isResolvingAddress ||
                                        !_hasUserPickedLocation)
                                    ? null
                                    : _confirmSelection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandBlueDark,
                                  disabledBackgroundColor:
                                      AppColors.inputBorder,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(r(16)),
                                  ),
                                ),
                                child: Text(
                                  'Select this location',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: r(16),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressState(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    if (_isResolvingAddress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fetching address...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r(17),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: r(8)),
          LinearProgressIndicator(
            minHeight: r(3),
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.inputBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.brandBlueDark,
            ),
          ),
        ],
      );
    }

    if (_errorText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location unavailable',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r(17),
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: r(4)),
          Text(
            _errorText!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r(13),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    if (!_hasUserPickedLocation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No location selected yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r(17),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: r(4)),
          Text(
            'Search for a place or move the map to choose an exact address.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r(13),
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      );
    }

    final title =
        (_selectedDisplayName != null &&
            _selectedDisplayName!.trim().isNotEmpty)
        ? _selectedDisplayName!.trim()
        : (_selectedLocation?.shortAddress ?? 'Selected location');

    final subtitle =
        _selectedLocation?.address ??
        '${_mapCenter.latitude}, ${_mapCenter.longitude}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: r(17),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: r(4)),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: r(13),
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: r(50),
          height: r(50),
          child: Icon(icon, size: r(22), color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
