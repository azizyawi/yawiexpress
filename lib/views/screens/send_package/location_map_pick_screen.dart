import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/models/location_model.dart';
import 'package:wanmac/services/location_service.dart';

class LocationMapPickerScreen extends StatefulWidget {
  final LocationModel? initialLocation;
  final bool isPickup;

  const LocationMapPickerScreen({
    super.key,
    this.initialLocation,
    this.isPickup = true,
  });

  @override
  State<LocationMapPickerScreen> createState() =>
      _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState extends State<LocationMapPickerScreen> {
  static const LatLng _beninCenter = LatLng(6.3350, 5.6037);

  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;

  // Keep the map focused on roads/street names, similar to the reference.
  // Business/POI labels and icons are hidden to reduce visual clutter.
  static const String _cleanMapStyle = r'''
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.business",
    "elementType": "all",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.medical",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.school",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.attraction",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [
      { "visibility": "on" }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text",
    "stylers": [
      { "visibility": "on" }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text",
    "stylers": [
      { "visibility": "on" }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text",
    "stylers": [
      { "visibility": "on" }
    ]
  }
]
''';

  late LatLng _selectedPosition;
  late final String _selectedSearchText;
  LocationModel? _resolvedLocation;

  bool _isConfirming = false;
  bool _isOutsideServiceArea = false;
  bool _hasMovedPin = false;
  int _idleCount = 0;

  // Reverse geocoding is debounced and single-flight.
  // This prevents repeated drag stops from firing many requests at once,
  // which can otherwise make address updates appear to freeze.
  Timer? _reverseGeocodeDebounce;
  bool _isResolvingAddress = false;
  LatLng? _pendingResolvePosition;
  LatLng? _lastResolvedPosition;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialLocation;

    _selectedPosition = initial == null
        ? _beninCenter
        : LatLng(initial.latitude, initial.longitude);

    // The top search bar represents what the customer searched/selected.
    // Keep it stable, exactly like the reference flow.
    _selectedSearchText = _searchBarText(initial);

    // The bottom card starts with the selected place, then silently changes
    // to the STREET/ROAD under the pin after the map's first idle event.
    _resolvedLocation = initial;

    _isOutsideServiceArea = !_locationService.isWithinServiceArea(
      _selectedPosition.latitude,
      _selectedPosition.longitude,
    );
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _pendingResolvePosition = null;
    _mapController?.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _applyMapStyle(
    GoogleMapController controller,
  ) async {
    _mapController = controller;

    try {
      await controller.setMapStyle(_cleanMapStyle);
    } catch (_) {
      // Map styling should never block location picking.
    }
  }

  String get _instruction => widget.isPickup
      ? 'Drag the pin to your preferred location'
      : 'Drag the pin to your preferred location';

  String _clean(String? value) => value?.trim() ?? '';

  bool _looksLikeCoordinates(String value) {
    return RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$')
        .hasMatch(value.trim());
  }

  bool _containsPlusCode(String value) {
    final clean = value.trim().toUpperCase();

    return RegExp(
      r'(^|[\s,])([23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3})(?=$|[\s,])',
    ).hasMatch(clean);
  }

  String _searchBarText(LocationModel? location) {
    if (location == null) return 'Selected location';

    final name = _clean(location.name);
    final address = _clean(location.address);
    final shortAddress = _clean(location.shortAddress);

    if (name.isNotEmpty &&
        !_looksLikeCoordinates(name) &&
        !_containsPlusCode(name)) {
      if (address.isNotEmpty &&
          !_looksLikeCoordinates(address) &&
          !_containsPlusCode(address) &&
          !address.toLowerCase().contains(name.toLowerCase())) {
        return '$name, $address';
      }
      return name;
    }

    if (address.isNotEmpty &&
        !_looksLikeCoordinates(address) &&
        !_containsPlusCode(address)) {
      return address;
    }

    if (shortAddress.isNotEmpty &&
        !_looksLikeCoordinates(shortAddress) &&
        !_containsPlusCode(shortAddress)) {
      return shortAddress;
    }

    return 'Selected location';
  }

  /// We intentionally avoid presenting a reverse-geocoded house number as
  /// "exact" after the user has moved the pin. Google can return the nearest
  /// known postal address even when the pin is on a neighbouring street.
  /// The actual coordinates we return are always the centre-pin coordinates.
  String _primaryAddress(LocationModel? location) {
    if (location == null) {
      return 'Pinned location';
    }

    final shortAddress = _clean(location.shortAddress);
    final name = _clean(location.name);
    final address = _clean(location.address);

    // Before the customer moves the pin, preserve the actual place selected
    // from autocomplete instead of immediately replacing it with a road.
    if (!_hasMovedPin &&
        name.isNotEmpty &&
        !_looksLikeCoordinates(name) &&
        !_containsPlusCode(name)) {
      return name;
    }

    // After the customer moves the pin, the coordinates become the source of
    // truth and the reverse-geocoded road/locality is the appropriate label.
    if (shortAddress.isNotEmpty &&
        !_looksLikeCoordinates(shortAddress) &&
        !_containsPlusCode(shortAddress) &&
        shortAddress.toLowerCase() != 'pinned location' &&
        shortAddress.toLowerCase() != 'unnamed road' &&
        shortAddress.toLowerCase() != 'unnamed street' &&
        shortAddress.toLowerCase() != 'unknown road' &&
        shortAddress.toLowerCase() != 'unknown street') {
      return shortAddress;
    }

    if (name.isNotEmpty &&
        !_looksLikeCoordinates(name) &&
        !_containsPlusCode(name)) {
      return name;
    }

    if (address.isNotEmpty &&
        !_looksLikeCoordinates(address) &&
        !_containsPlusCode(address)) {
      final first = address.split(',').first.trim();
      if (first.toLowerCase() != 'unnamed road' &&
          first.toLowerCase() != 'unnamed street' &&
          first.toLowerCase() != 'unknown road' &&
          first.toLowerCase() != 'unknown street') {
        return first;
      }
    }

    final city = _clean(location.city);
    if (city.isNotEmpty && !_containsPlusCode(city)) {
      return city;
    }

    return 'Pinned location';
  }

  String _secondaryAddress(LocationModel? location) {
    if (location == null) {
      return 'Benin City, Edo';
    }

    final city = _clean(location.city);
    final state = _clean(location.state);

    return [city, state]
        .where(
          (part) =>
              part.isNotEmpty &&
              !_containsPlusCode(part),
        )
        .toSet()
        .join(', ');
  }

  void _onCameraMove(CameraPosition position) {
    _selectedPosition = position.target;

    final outside = !_locationService.isWithinServiceArea(
      position.target.latitude,
      position.target.longitude,
    );

    // Do not call setState continuously while the map is moving.
    // Only rebuild if the service-area state actually changed.
    if (outside != _isOutsideServiceArea) {
      setState(() {
        _isOutsideServiceArea = outside;
      });
    }
  }

  Future<void> _onCameraIdle() async {
    _idleCount++;

    if (_isOutsideServiceArea) return;

    // First idle is only GoogleMap settling on the place the customer
    // selected from search. Keep that selected place exactly as-is.
    //
    // Example:
    //   Search "SLYCE KITCHEN" -> show "SLYCE KITCHEN"
    //   Search "Chicken Republic" -> show "Chicken Republic"
    //
    // Only reverse-geocode after the customer actually moves the map.
    if (_idleCount == 1) {
      return;
    }

    // Every later idle represents a real camera move.
    if (!_hasMovedPin) {
      setState(() {
        _hasMovedPin = true;
      });
    }

    _pendingResolvePosition = _selectedPosition;

    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(
      const Duration(milliseconds: 550),
      _drainReverseGeocodeQueue,
    );
  }

  Future<void> _drainReverseGeocodeQueue() async {
    if (_isResolvingAddress || !mounted) return;

    while (mounted && _pendingResolvePosition != null) {
      final position = _pendingResolvePosition!;
      _pendingResolvePosition = null;

      // Avoid paying for another lookup when the pin barely moved.
      if (_lastResolvedPosition != null &&
          _isAlmostSamePosition(
            _lastResolvedPosition!,
            position,
          )) {
        continue;
      }

      _isResolvingAddress = true;

      try {
        final resolved = await _locationService.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
          preferExactAddress: true,
          fallbackLabel: 'Pinned location',
        );

        if (!mounted) return;

        // If the user moved again while this request was running, do not let
        // the older response overwrite the newer pin position. The loop will
        // immediately resolve the queued latest position.
        if (_pendingResolvePosition == null &&
            _isAlmostSamePosition(
              _selectedPosition,
              position,
              tolerance: 0.00008,
            )) {
          setState(() {
            _resolvedLocation = resolved;
          });

          _lastResolvedPosition = position;
        }
      } catch (_) {
        // Keep the last readable address. A later drag can still resolve.
      } finally {
        _isResolvingAddress = false;
      }
    }
  }

  bool _isAlmostSamePosition(
    LatLng a,
    LatLng b, {
    double tolerance = 0.000025,
  }) {
    return (a.latitude - b.latitude).abs() <= tolerance &&
        (a.longitude - b.longitude).abs() <= tolerance;
  }

  Future<void> _confirmLocation() async {
    if (_isOutsideServiceArea || _isConfirming) return;

    _reverseGeocodeDebounce?.cancel();
    _pendingResolvePosition = null;

    setState(() => _isConfirming = true);

    try {
      LocationModel? location = _resolvedLocation;

      // If the customer moved the pin, resolve the exact final camera centre
      // once more on confirmation. This avoids returning a stale address if
      // they tap immediately after dragging.
      if (_hasMovedPin || location == null) {
        try {
          location = await _locationService.reverseGeocode(
            latitude: _selectedPosition.latitude,
            longitude: _selectedPosition.longitude,
            preferExactAddress: true,
            fallbackLabel: 'Pinned location',
          );
        } catch (_) {
          location ??= LocationModel(
            latitude: _selectedPosition.latitude,
            longitude: _selectedPosition.longitude,
            address: 'Pinned location',
            shortAddress: 'Pinned location',
            city: 'Benin City',
            state: 'Edo',
            country: 'Nigeria',
          );
        }
      }

      if (!mounted || location == null) return;

      final finalLocation = LocationModel(
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        name: location.name,
        address: location.address,
        shortAddress: location.shortAddress,
        city: location.city,
        state: location.state,
        country: location.country,
      );

      Navigator.pop(context, finalLocation);
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final isTablet = size.shortestSide >= 600;
    final horizontal = isTablet ? 28.0 : 20.0;
    final bottomInset = media.padding.bottom;

    final initialTarget = widget.initialLocation == null
        ? _beninCenter
        : LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: widget.initialLocation == null ? 14.5 : 17.0,
            ),
            onMapCreated: _applyMapStyle,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            mapType: MapType.normal,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            buildingsEnabled: true,
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            // IMPORTANT:
            // Do not add GoogleMap.padding here. Padding changes Google's
            // camera target/projection and makes a fixed overlay pin appear
            // to drift away from the coordinate being reverse-geocoded.
          ),

          // Real teardrop map pin. The sharp tip is the exact selected point.
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: const _WanpadiPin(),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _BackButton(
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        Text(
                          'Select an address',
                          style: GoogleFonts.montserrat(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TopAddressBar(
                    text: _selectedSearchText,
                    isLoading: false,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: horizontal,
            right: horizontal,
            bottom: 16 + bottomInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LocationCard(
                  instruction: _instruction,
                  primaryAddress: _primaryAddress(_resolvedLocation),
                  secondaryAddress: _secondaryAddress(_resolvedLocation),
                  isOutsideServiceArea: _isOutsideServiceArea,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isOutsideServiceArea ||
                            _isConfirming
                        ? null
                        : _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.brandBlueDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE8EBF5),
                      disabledForegroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Select this location',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WanpadiPin extends StatelessWidget {
  const _WanpadiPin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 54,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 17,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.16),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          CustomPaint(
            size: const Size(42, 49),
            painter: _PinPainter(
              color: AppColors.brandBlueDark,
            ),
          ),
          const Positioned(
            top: 12,
            child: CircleAvatar(
              radius: 6,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;

  const _PinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final fillPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cx = size.width / 2;
    final headRadius = size.width * .39;
    final headCenterY = headRadius + 2;
    final tipY = size.height - 2;

    final path = Path()
      ..moveTo(cx, tipY)
      ..cubicTo(
        cx - size.width * .10,
        size.height * .78,
        cx - headRadius,
        size.height * .56,
        cx - headRadius,
        headCenterY,
      )
      ..arcTo(
        Rect.fromCircle(
          center: Offset(cx, headCenterY),
          radius: headRadius,
        ),
        math.pi,
        math.pi,
        false,
      )
      ..cubicTo(
        cx + headRadius,
        size.height * .56,
        cx + size.width * .10,
        size.height * .78,
        cx,
        tipY,
      )
      ..close();

    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE4E6EA)),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
            color: Color(0xFF1B1C21),
          ),
        ),
      ),
    );
  }
}

class _TopAddressBar extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onTap;

  const _TopAddressBar({
    required this.text,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFD8DBE2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 21,
                color: Color(0xFF8D919C),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String instruction;
  final String primaryAddress;
  final String secondaryAddress;
  final bool isOutsideServiceArea;

  const _LocationCard({
    required this.instruction,
    required this.primaryAddress,
    required this.secondaryAddress,
    required this.isOutsideServiceArea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isOutsideServiceArea
              ? AppColors.error.withOpacity(.45)
              : AppColors.brandBlueDark.withOpacity(.28),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              isOutsideServiceArea ? 'Outside service area' : instruction,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: isOutsideServiceArea
                    ? AppColors.error
                    : AppColors.brandBlueDark,
              ),
            ),
          ),
          const SizedBox(height: 13),
          if (isOutsideServiceArea)
            Text(
              'Wanpadi currently serves locations within Benin City. Move the pin back into the service area.',
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.brandBlueDark,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (secondaryAddress.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          secondaryAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}