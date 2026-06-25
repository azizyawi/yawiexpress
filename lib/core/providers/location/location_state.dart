import 'package:flutter/foundation.dart';
import 'package:wanmac/models/location_model.dart' show LocationModel;

@immutable
class LocationState {
  final bool isLoading;
  final String? error;
  final LocationModel? currentLocation;
  final LocationModel? pickupLocation;
  final LocationModel? dropoffLocation;

  const LocationState({
    this.isLoading = false,
    this.error,
    this.currentLocation,
    this.pickupLocation,
    this.dropoffLocation,
  });

  LocationState copyWith({
    bool? isLoading,
    String? error,
    LocationModel? currentLocation,
    LocationModel? pickupLocation,
    LocationModel? dropoffLocation,
    bool clearError = false,
    bool clearDropoff = false,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentLocation: currentLocation ?? this.currentLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: clearDropoff
          ? null
          : (dropoffLocation ?? this.dropoffLocation),
    );
  }
  static const initial = LocationState();
}
