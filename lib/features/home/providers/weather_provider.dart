import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/api_client.dart';
import '../../../models/weather.dart';
import '../../../models/weather_parser.dart';
import '../../settings/providers/settings_provider.dart';
import 'location_provider.dart';


/// Current conditions for the active location.
///
/// Watches [locationProvider] and the active mode internally, so it re-fetches
/// automatically whenever either changes — no cache keying or manual invalidate
/// needed on the caller side, and a request for a superseded location is
/// discarded by Riverpod rather than written into state.
final weatherProvider = FutureProvider<WeatherSnapshot>((ref) async {
  final location = ref.watch(locationProvider);
  final mode = ref.watch(settingsProvider.select((s) => s.mode));
  final data = await ApiClient.instance.get(
    ApiEndpoints.weather,
    query: {'lat': location.lat, 'lon': location.lon, 'mode': mode.wire},
  );

  return parseWeatherSnapshot(data, cityName: location.name.split(',').first);
});
