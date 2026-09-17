import 'package:flutter/material.dart';

/// Immutable models for weather data, extracted from
/// `weather_provider.dart` so UI/theme layers can import them without
/// provider machinery.

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
