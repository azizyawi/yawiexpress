import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmac/models/location_model.dart';
import 'package:wanmac/services/app_location_storage.dart';

class PickupLocationNotifier extends Notifier<LocationModel?> {
  @override
  LocationModel? build() {
    return null; // initial state
  }

  Future<void> loadSavedLocation() async {
    final saved = await AppLocationStorage.getPickupLocation();
    state = saved;
  }

  Future<void> setLocation(LocationModel location) async {
    state = location;
    await AppLocationStorage.savePickupLocation(location);
  }

  Future<void> clearLocation() async {
    state = null;
    await AppLocationStorage.clearPickupLocation();
  }
}

final pickupLocationProvider =
    NotifierProvider<PickupLocationNotifier, LocationModel?>(
      PickupLocationNotifier.new,
    );
