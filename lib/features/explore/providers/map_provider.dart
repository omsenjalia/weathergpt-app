import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum MapLayer { wind, rain, temp, pressure }

class MapState {
  const MapState({
    this.activeLayer = MapLayer.wind,
    this.currentLocation,
    this.isLoadingLocation = false,
  });

  final MapLayer activeLayer;
  final LatLng? currentLocation;
  final bool isLoadingLocation;

  MapState copyWith({
    MapLayer? activeLayer,
    LatLng? currentLocation,
    bool? isLoadingLocation,
  }) =>
      MapState(
        activeLayer: activeLayer ?? this.activeLayer,
        currentLocation: currentLocation ?? this.currentLocation,
        isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      );
}

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(const MapState());

  void setLayer(MapLayer layer) => state = state.copyWith(activeLayer: layer);

  /// Returns the detected position when permission and location services allow it.
  Future<LatLng?> detectCurrentLocation() async {
    state = state.copyWith(isLoadingLocation: true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      state = state.copyWith(currentLocation: location);
      return location;
    } finally {
      state = state.copyWith(isLoadingLocation: false);
    }
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>(
  (ref) => MapNotifier(),
);
