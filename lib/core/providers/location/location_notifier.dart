import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmac/models/location_model.dart';
import 'package:wanmac/services/app_location_storage.dart';
import 'package:wanmac/services/location_service.dart';

import 'location_state.dart';
import 'location_providers.dart';

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    Future.microtask(_loadSavedPickupLocation);
    return LocationState.initial;
  }

  LocationService get _service => ref.read(locationServiceProvider);

  Future<void> _loadSavedPickupLocation() async {
    final savedPickup = await AppLocationStorage.getPickupLocation();

    if (savedPickup != null) {
      state = state.copyWith(pickupLocation: savedPickup, clearError: true);
    }
  }

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final location = await _service.getCurrentLocation();

      state = state.copyWith(isLoading: false, currentLocation: location);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setPickupLocation(LocationModel location) async {
    state = state.copyWith(pickupLocation: location, clearError: true);

    await AppLocationStorage.savePickupLocation(location);
  }

  void setDropoffLocation(LocationModel location) {
    state = state.copyWith(dropoffLocation: location, clearError: true);
  }

  Future<void> useCurrentAsPickup() async {
    if (state.currentLocation != null) {
      await setPickupLocation(state.currentLocation!);
      return;
    }

    await fetchCurrentLocation();

    if (state.currentLocation != null) {
      await setPickupLocation(state.currentLocation!);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
void clearDropoffLocation() {
    state = state.copyWith(clearDropoff: true);
  }
  Future<void> clearAll() async {
    state = LocationState.initial;
    await AppLocationStorage.clearPickupLocation();
  }
}
