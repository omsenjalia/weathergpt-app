import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Windy embed overlay ids (must match embed.windy.com `overlay=` values).
enum MapLayer {
  wind,
  rain,
  temp,
  clouds,
  radar,
  waves,
  pressure,
}

class MapState {
  const MapState({
    this.activeLayer = MapLayer.wind,
    this.lat = 23.0225,
    this.lon = 72.5714,
    this.zoom = 6,
    this.currentLocation,
    this.isLoadingLocation = false,
  });

  final MapLayer activeLayer;
  final double lat;
  final double lon;
  final int zoom;
  final ({double lat, double lon})? currentLocation;
  final bool isLoadingLocation;

  MapState copyWith({
    MapLayer? activeLayer,
    double? lat,
    double? lon,
    int? zoom,
    ({double lat, double lon})? currentLocation,
    bool? isLoadingLocation,
    bool clearLocation = false,
  }) =>
      MapState(
        activeLayer: activeLayer ?? this.activeLayer,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        zoom: zoom ?? this.zoom,
        currentLocation:
            clearLocation ? null : (currentLocation ?? this.currentLocation),
        isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      );
}

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(const MapState());

  void setLayer(MapLayer layer) => state = state.copyWith(activeLayer: layer);

  void setCenter(double lat, double lon, {int? zoom}) => state = state.copyWith(
        lat: lat,
        lon: lon,
        zoom: zoom ?? state.zoom,
      );

  /// Returns detected position when permission and location services allow it.
  Future<({double lat, double lon})?> detectCurrentLocation() async {
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
      final location = (lat: position.latitude, lon: position.longitude);
      state = state.copyWith(
        currentLocation: location,
        lat: location.lat,
        lon: location.lon,
        zoom: 11,
      );
      return location;
    } finally {
      state = state.copyWith(isLoadingLocation: false);
    }
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>(
  (ref) => MapNotifier(),
);
