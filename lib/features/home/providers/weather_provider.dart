import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../models/weather.dart';
import 'location_provider.dart';

String _hourLabel(String? iso) {
  if (iso == null || iso.length < 13) return '';
  final h = int.tryParse(iso.substring(11, 13)) ?? 0;
  if (h == 0) return '12AM';
  if (h == 12) return '12PM';
  return h > 12 ? '${h - 12}PM' : '${h}AM';
}

/// Current conditions for the active location.
///
/// Watches [locationProvider] internally, so it re-fetches automatically
/// whenever the location changes — no cache keying or manual invalidate
/// needed on the caller side.
final weatherProvider = FutureProvider<WeatherSnapshot>((ref) async {
  final location = ref.watch(locationProvider);
  final data = await ApiClient.instance.get(
    '/weather',
    query: {'lat': location.lat, 'lon': location.lon},
  );

  final hourlyRaw = (data['hourly'] as List?) ?? const [];
  final hourly = <HourlyPoint>[];
  for (final item in hourlyRaw.take(12)) {
    if (item is! Map) continue;
    final t = item['temperature_c'];
    if (t is! num) continue;
    hourly.add(HourlyPoint(
      label: _hourLabel('${item['time']}'),
      tempC: t.toDouble(),
    ));
  }

  final forecastRaw = (data['forecast'] as List?) ?? const [];
  final forecast = <DayForecast>[];
  for (final item in forecastRaw) {
    if (item is! Map) continue;
    forecast.add(DayForecast(
      date: '${item['date'] ?? ''}',
      highC: (item['high_c'] as num?)?.toDouble(),
      lowC: (item['low_c'] as num?)?.toDouble(),
      condition: '${item['condition'] ?? ''}',
      rainProbability: item['rain_probability'] as num?,
    ));
  }

  return WeatherSnapshot(
    temperatureC: (data['temperature_c'] as num?)?.toDouble(),
    feelsLikeC: (data['feels_like_c'] as num?)?.toDouble(),
    condition: '${data['condition'] ?? '—'}',
    weatherCode: (data['weather_code'] as num?)?.toInt() ?? 0,
    highC: (data['high_c'] as num?)?.toDouble(),
    lowC: (data['low_c'] as num?)?.toDouble(),
    humidity: data['humidity'] as num?,
    windKmh: data['wind_kmh'] as num?,
    windDirection: data['wind_direction'] as num?,
    pressureHpa: data['pressure_hpa'] as num?,
    rainProbability: data['rain_probability'] as num?,
    uvIndex: data['uv_index'] as num?,
    sunrise: data['sunrise'] as String?,
    sunset: data['sunset'] as String?,
    aqi: data['aqi'] as num?,
    pm25: data['pm2_5'] as num?,
    hourly: hourly,
    forecast: forecast,
    cityName: location.name.split(',').first,
  );
});
