import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/api_client.dart';
import '../../../models/weather.dart';
import '../../../models/weather_parser.dart';
import '../../../models/weather_v2_parser.dart';
import '../../settings/providers/settings_provider.dart';
import 'location_provider.dart';

/// Current conditions — now WeatherNext aware via /v2/weather.
/// v2 returns selected_source, fallback_reasons, and richer provenance.
/// Falls back to legacy /weather if v2 unavailable.
final weatherProvider = FutureProvider<WeatherSnapshot>((ref) async {
  final location = ref.watch(locationProvider);
  final mode = ref.watch(settingsProvider.select((s) => s.mode));
  final cityName = location.name.split(',').first;

  try {
    final data = await ApiClient.instance.get(
      ApiEndpoints.v2Weather,
      query: {
        'lat': location.lat,
        'lon': location.lon,
        'mode': mode.wire,
        'requested_source': mode.wire == 'researcher' ? 'weathernext' : 'auto',
      },
    );
    return parseWeatherSnapshotV2(data, cityName: cityName);
  } catch (_) {
    final data = await ApiClient.instance.get(
      ApiEndpoints.weather,
      query: {'lat': location.lat, 'lon': location.lon, 'mode': mode.wire},
    );
    return parseWeatherSnapshot(data, cityName: cityName);
  }
});
