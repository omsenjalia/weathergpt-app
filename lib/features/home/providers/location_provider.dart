import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/location.dart';

class LocationNotifier extends StateNotifier<AppLocation> {
  LocationNotifier() : super(_load());

  static AppLocation _load() {
    if (!Hive.isBoxOpen('settings')) return kDefaultLocation;
    final box = Hive.box('settings');
    final raw = box.get('selected_location');
    if (raw is Map) return AppLocation.fromMap(raw);
    return kDefaultLocation;
  }

  Future<void> select(AppLocation location) async {
    state = location;
    if (!Hive.isBoxOpen('settings')) return;
    await Hive.box('settings').put('selected_location', location.toMap());
  }

  /// Resolve GPS and persist as the active home location.
  Future<AppLocation?> selectFromGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition();
    final loc = AppLocation(
      name: 'Current location',
      lat: pos.latitude,
      lon: pos.longitude,
    );
    await select(loc);
    return loc;
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, AppLocation>(
  (ref) => LocationNotifier(),
);
