import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import 'location_provider.dart';

class WeatherMetric {
  const WeatherMetric(this.icon, this.value, this.label, {this.qualifier});
  final IconData icon;
  final String value;
  final String label;
  final String? qualifier;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperature,
    required this.condition,
    required this.range,
    required this.metrics,
  });
  final String temperature;
  final String condition;
  final String range;
  final List<WeatherMetric> metrics;
}

String _fmtTemp(num? v) => v == null ? '—' : '${v.round()}°';
String _fmtInt(num? v, {String suffix = ''}) =>
    v == null ? '—' : '${v.round()}$suffix';
String _fmtOne(num? v, {String suffix = ''}) =>
    v == null ? '—' : '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}$suffix';

final weatherProvider =
    FutureProvider.family<WeatherSnapshot, String>((ref, persona) async {
  final location = ref.watch(locationProvider);
  final data = await ApiClient.instance.get(
    '/weather',
    query: {'lat': location.lat, 'lon': location.lon},
  );

  final rain = data['rain_probability'];
  final wind = data['wind_kmh'];
  final humidity = data['humidity'];
  final pressure = data['pressure_hpa'];

  return WeatherSnapshot(
    temperature: _fmtTemp(data['temperature_c'] as num?),
    condition: '${data['condition'] ?? '—'}',
    range:
        'H: ${_fmtTemp(data['high_c'] as num?)}  L: ${_fmtTemp(data['low_c'] as num?)}',
    metrics: persona == 'farmer'
        ? [
            WeatherMetric(
                Icons.water_drop_outlined, _fmtInt(rain as num?, suffix: '%'), 'Rain'),
            WeatherMetric(Icons.air, _fmtOne(wind as num?, suffix: ' km/h'), 'Wind'),
            WeatherMetric(Icons.opacity_outlined,
                _fmtInt(humidity as num?, suffix: '%'), 'Humidity'),
            const WeatherMetric(
                Icons.water_outlined, 'Advisory', 'Soil'),
          ]
        : [
            WeatherMetric(
                Icons.water_drop_outlined, _fmtInt(rain as num?, suffix: '%'), 'Rain'),
            WeatherMetric(Icons.air, _fmtOne(wind as num?, suffix: ' km/h'), 'Wind'),
            WeatherMetric(Icons.opacity_outlined,
                _fmtInt(humidity as num?, suffix: '%'), 'Humidity'),
            WeatherMetric(Icons.compress_outlined,
                _fmtInt(pressure as num?, suffix: ' hPa'), 'Pressure'),
          ],
  );
});
