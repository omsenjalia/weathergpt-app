import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';

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

final weatherProvider = FutureProvider.family<WeatherSnapshot, String>((ref, persona) async {
  final data = await ApiClient.instance.get('/weather', query: {'lat': 23.0225, 'lon': 72.5714});
  final rain = data['rain_probability'] ?? 0;
  return WeatherSnapshot(
    temperature: '${(data['temperature_c'] as num).round()}°',
    condition: '${data['condition']}',
    range: 'H: ${(data['high_c'] as num).round()}°  L: ${(data['low_c'] as num).round()}°',
    metrics: persona == 'farmer'
        ? [WeatherMetric(Icons.water_drop_outlined, '$rain%', 'Rain'), WeatherMetric(Icons.air, '${data['wind_kmh']} km/h', 'Wind'), WeatherMetric(Icons.opacity_outlined, '${data['humidity']}%', 'Humidity'), const WeatherMetric(Icons.water_outlined, 'See advisory', 'Soil moisture')]
        : [WeatherMetric(Icons.water_drop_outlined, '$rain%', 'Rain'), WeatherMetric(Icons.air, '${data['wind_kmh']} km/h', 'Wind'), WeatherMetric(Icons.opacity_outlined, '${data['humidity']}%', 'Humidity'), WeatherMetric(Icons.compress_outlined, '${data['pressure_hpa']} hPa', 'Pressure')],
  );
});
