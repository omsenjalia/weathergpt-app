import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLocation {
  const AppLocation({
    required this.name,
    required this.lat,
    required this.lon,
  });

  final String name;
  final double lat;
  final double lon;

  Map<String, dynamic> toMap() => {'name': name, 'lat': lat, 'lon': lon};

  factory AppLocation.fromMap(Map<dynamic, dynamic> map) => AppLocation(
        name: map['name'] as String? ?? 'Ahmedabad, Gujarat',
        lat: (map['lat'] as num?)?.toDouble() ?? 23.0225,
        lon: (map['lon'] as num?)?.toDouble() ?? 72.5714,
      );
}

const kDefaultLocation = AppLocation(
  name: 'Ahmedabad, Gujarat',
  lat: 23.0225,
  lon: 72.5714,
);

const kPresetLocations = <AppLocation>[
  AppLocation(name: 'Ahmedabad, Gujarat', lat: 23.0225, lon: 72.5714),
  AppLocation(name: 'Mumbai, Maharashtra', lat: 19.0760, lon: 72.8777),
  AppLocation(name: 'Delhi, India', lat: 28.6139, lon: 77.2090),
  AppLocation(name: 'Bengaluru, Karnataka', lat: 12.9716, lon: 77.5946),
  AppLocation(name: 'Chennai, Tamil Nadu', lat: 13.0827, lon: 80.2707),
  AppLocation(name: 'Kolkata, West Bengal', lat: 22.5726, lon: 88.3639),
  AppLocation(name: 'Hyderabad, Telangana', lat: 17.3850, lon: 78.4867),
  AppLocation(name: 'Pune, Maharashtra', lat: 18.5204, lon: 73.8567),
  AppLocation(name: 'Jaipur, Rajasthan', lat: 26.9124, lon: 75.7873),
  AppLocation(name: 'Anand, Gujarat', lat: 22.5645, lon: 72.9289),
];

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

/// Geocode a free-text place name via Open-Meteo (no API key).
Future<AppLocation?> geocodePlaceName(String query) async {
  final q = query.trim();
  if (q.length < 2) return null;
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    final res = await dio.get<Map<String, dynamic>>(
      'https://geocoding-api.open-meteo.com/v1/search',
      queryParameters: {'name': q, 'count': 5, 'language': 'en'},
    );
    final results = res.data?['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;
    final name = first['name'] as String? ?? q;
    final admin = first['admin1'] as String?;
    final country = first['country'] as String?;
    final label = [
      name,
      if (admin != null && admin.isNotEmpty) admin,
      if (country != null && country.isNotEmpty && country != admin) country,
    ].join(', ');
    return AppLocation(
      name: label,
      lat: (first['latitude'] as num).toDouble(),
      lon: (first['longitude'] as num).toDouble(),
    );
  } catch (_) {
    return null;
  }
}
