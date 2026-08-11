import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/models/location_model.dart';
import 'package:wanmac/services/location_service.dart';

class LocationMapPickerScreen extends StatefulWidget {
  const LocationMapPickerScreen({super.key});

  @override
  State<LocationMapPickerScreen> createState() =>
      _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState
    extends State<LocationMapPickerScreen> {
  static const LatLng _beninCenter = LatLng(
    6.3350,
    5.6037,
  );

  final LocationService _locationService =
      LocationService();

  LatLng _selectedPosition = _beninCenter;

  LocationModel? _resolvedLocation;

  bool _isResolving = false;
  bool _isConfirming = false;
  bool _isOutsideServiceArea = false;

  int _resolveRequestId = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resolveSelectedLocation(),
    );
  }

  @override
  void dispose() {
    _resolveRequestId++;
    _locationService.dispose();
    super.dispose();
  }

  void _onCameraMove(
    CameraPosition position,
  ) {
    _selectedPosition = position.target;

    final isOutside =
        !_locationService.isWithinServiceArea(
      position.target.latitude,
      position.target.longitude,
    );

    if (isOutside != _isOutsideServiceArea ||
        _resolvedLocation != null) {
      setState(() {
        _isOutsideServiceArea = isOutside;
        _resolvedLocation = null;
      });
    }
  }

  Future<void> _onCameraIdle() async {
    await _resolveSelectedLocation();
  }

  Future<void> _resolveSelectedLocation() async {
    final position = _selectedPosition;
    final requestId = ++_resolveRequestId;

    if (!_locationService.isWithinServiceArea(
      position.latitude,
      position.longitude,
    )) {
      if (!mounted) return;

      setState(() {
        _isOutsideServiceArea = true;
        _resolvedLocation = null;
        _isResolving = false;
      });

      return;
    }

    setState(() {
      _isOutsideServiceArea = false;
      _isResolving = true;
    });

    try {
      final location =
          await _locationService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
        preferExactAddress: true,
      );

      if (!mounted ||
          requestId != _resolveRequestId) {
        return;
      }

      setState(() {
        _resolvedLocation = location;
      });
    } catch (_) {
      if (!mounted ||
          requestId != _resolveRequestId) {
        return;
      }

      setState(() {
        _resolvedLocation = LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          address:
              '${position.latitude}, ${position.longitude}',
          shortAddress: 'Pinned Location',
          city: 'Benin City',
          state: 'Edo',
          country: 'Nigeria',
        );
      });
    } finally {
      if (mounted &&
          requestId == _resolveRequestId) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  Future<void> _confirmLocation() async {
    if (_isOutsideServiceArea ||
        _isConfirming) {
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    try {
      LocationModel? location =
          _resolvedLocation;

      if (location == null) {
        await _resolveSelectedLocation();
        location = _resolvedLocation;
      }

      if (!mounted || location == null) {
        return;
      }

      Navigator.pop(
        context,
        location,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet =
        size.shortestSide >= 600;

    final horizontalPadding =
        isTablet ? 28.0 : 18.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  const CameraPosition(
                target: _beninCenter,
                zoom: 14.5,
              ),
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              buildingsEnabled: true,
            ),

            // Fixed center pin. The user moves the map,
            // which is easier than dragging a tiny marker.
            Center(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 48,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 14,
              left: horizontalPadding,
              right: horizontalPadding,
              child: Row(
                children: [
                  _MapCircleButton(
                    icon:
                        Icons.arrow_back_rounded,
                    onTap: () =>
                        Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration:
                          BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.08),
                            blurRadius: 20,
                            offset:
                                const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'Move the map to the delivery location',
                        maxLines: 2,
                        textAlign:
                            TextAlign.center,
                        style:
                            GoogleFonts.montserrat(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight:
                              FontWeight.w700,
                          color: AppColors
                              .textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(
                        0.10,
                      ),
                      blurRadius: 28,
                      offset:
                          const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOutsideServiceArea
                          ? 'Outside service area'
                          : 'Selected location',
                      style:
                          GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        color: _isOutsideServiceArea
                            ? AppColors.error
                            : AppColors
                                .textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_isOutsideServiceArea)
                      Text(
                        'Wanpadi currently serves locations within Benin City. Move the pin back into the service area.',
                        style:
                            GoogleFonts.montserrat(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight:
                              FontWeight.w500,
                          color: AppColors
                              .textPrimary,
                        ),
                      )
                    else if (_isResolving)
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors
                                  .brandBlue,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              'Finding this address...',
                              style:
                                  GoogleFonts.montserrat(
                                fontSize: 13,
                                color: AppColors
                                    .textSecondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _resolvedLocation
                                ?.address ??
                            'Move the map slightly to choose the exact location.',
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            GoogleFonts.montserrat(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight:
                              FontWeight.w600,
                          color: AppColors
                              .textPrimary,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            _isOutsideServiceArea ||
                                    _isResolving ||
                                    _isConfirming
                                ? null
                                : _confirmLocation,
                        style:
                            ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor:
                              AppColors
                                  .brandBlueDark,
                          foregroundColor:
                              Colors.white,
                          disabledBackgroundColor:
                              AppColors.inputFill,
                          disabledForegroundColor:
                              AppColors
                                  .textSecondary,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child: _isConfirming
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : Text(
                                'Use this location',
                                style: GoogleFonts
                                    .montserrat(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder:
            const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            size: 21,
            color:
                AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}