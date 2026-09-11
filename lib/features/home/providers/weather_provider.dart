import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import 'location_provider.dart';

class HourlyPoint {
  const HourlyPoint({required this.label, required this.tempC});
  final String label;
  final double tempC;
}

class DayForecast {
  const DayForecast({
    required this.date,
    required this.highC,
    required this.lowC,
    required this.condition,
    required this.rainProbability,
  });
  final String date;
  final double? highC;
  final double? lowC;
  final String condition;
  final num? rainProbability;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.condition,
    required this.weatherCode,
    required this.highC,
    required this.lowC,
    required this.humidity,
    required this.windKmh,
    required this.windDirection,
    required this.pressureHpa,
    required this.rainProbability,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.aqi,
    required this.pm25,
    required this.hourly,
    required this.forecast,
    required this.cityName,
  });

  final double? temperatureC;
  final double? feelsLikeC;
  final String condition;
  final int weatherCode;
  final double? highC;
  final double? lowC;
  final num? humidity;
  final num? windKmh;
  final num? windDirection;
  final num? pressureHpa;
  final num? rainProbability;
  final num? uvIndex;
  final String? sunrise;
  final String? sunset;
  final num? aqi;
  final num? pm25;
  final List<HourlyPoint> hourly;
  final List<DayForecast> forecast;
  final String cityName;

  // Back-compat for older home scaffolds
  String get temperature =>
      temperatureC == null ? '—' : '${temperatureC!.round()}°';
  String get range =>
      'H: ${highC?.round() ?? '—'}°  L: ${lowC?.round() ?? '—'}°';
  List<WeatherMetric> get metrics => [
        WeatherMetric(Icons.water_drop_outlined,
            rainProbability == null ? '—' : '${rainProbability!.round()}%', 'Rain'),
        WeatherMetric(Icons.air,
            windKmh == null ? '—' : '${windKmh!.toStringAsFixed(0)} km/h', 'Wind'),
        WeatherMetric(Icons.opacity_outlined,
            humidity == null ? '—' : '${humidity!.round()}%', 'Humidity'),
        WeatherMetric(Icons.compress_outlined,
            pressureHpa == null ? '—' : '${pressureHpa!.round()} hPa', 'Pressure'),
      ];
}

class WeatherMetric {
  const WeatherMetric(this.icon, this.value, this.label, {this.qualifier});
  final IconData icon;
  final String value;
  final String label;
  final String? qualifier;
}

String _hourLabel(String? iso) {
  if (iso == null || iso.length < 13) return '';
  final h = int.tryParse(iso.substring(11, 13)) ?? 0;
  if (h == 0) return '12AM';
  if (h == 12) return '12PM';
  return h > 12 ? '${h - 12}PM' : '${h}AM';
}

final weatherProvider =
    FutureProvider.family<WeatherSnapshot, String>((ref, persona) async {
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
