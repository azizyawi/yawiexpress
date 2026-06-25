import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmac/services/location_service.dart';
import 'location_notifier.dart';
import 'location_state.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationNotifierProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
