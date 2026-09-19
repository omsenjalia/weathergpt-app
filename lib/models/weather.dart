import 'package:flutter/material.dart';

import '../core/models/data_provenance.dart';
import '../core/models/json_values.dart';

export '../core/models/data_provenance.dart';

/// Immutable models for weather data, extracted from
/// `weather_provider.dart` so UI/theme layers can import them without
/// provider machinery.
///
/// Nullable-by-design: a field the backend did not send stays `null` and the UI
/// renders an unavailable state. Missing measurements are never coerced to `0`,
/// and a missing weather code is never treated as "clear".

class HourlyPoint {
  const HourlyPoint({
    required this.label,
    required this.tempC,
    this.timeUtc,
    this.rainProbability,
    this.precipMm,
    this.windKmh,
  });

  final String label;
  final double tempC;

  /// Instant this bucket refers to, in UTC. Kept as UTC so any timezone
  /// conversion happens at display time with the location's timezone id.
  final DateTime? timeUtc;
  final num? rainProbability;
  final num? precipMm;
  final num? windKmh;
}

/// One forecast day. Every measurement is nullable: a day the backend could not
/// fully resolve must not render as a confident zero.
class DayForecast {
  const DayForecast({
    required this.date,
    required this.highC,
    required this.lowC,
    required this.condition,
    required this.rainProbability,
    this.dateUtc,
    this.precipMm,
    this.precipIntervalLabel,
    this.coversFullDay,
    this.windKmhMax,
  });

  final String date;
  final double? highC;
  final double? lowC;
  final String condition;
  final num? rainProbability;

  /// Calendar date as a UTC instant, preserved for per-day verdict lookups.
  final DateTime? dateUtc;

  /// Accumulated precipitation for this day, when reported.
  final num? precipMm;

  /// Human-readable coverage of [precipMm], e.g. "12–18 IST". A total whose
  /// interval is incomplete must never be shown as a whole-day total.
  final String? precipIntervalLabel;

  /// `false` when the backend says the interval does not cover the whole day.
  final bool? coversFullDay;
  final num? windKmhMax;

  bool get hasAnyMeasurement =>
      highC != null || lowC != null || rainProbability != null || precipMm != null;
}

/// Model-spread of forecast temperature (p10–p90).
///
/// This is a *spread*, not a probability: no exact rain/temperature probability
/// may be inferred from percentiles (feature/app/implementation_plan.md §3).
class TemperatureSpread {
  const TemperatureSpread({
    required this.p10C,
    required this.p90C,
    this.source,
    this.runId,
    this.validFromUtc,
    this.validToUtc,
    this.memberCount,
  });

  final double p10C;
  final double p90C;
  final String? source;
  final String? runId;
  final DateTime? validFromUtc;
  final DateTime? validToUtc;
  final int? memberCount;

  double get spanC => p90C - p10C;

  /// Coverage window this spread applies to; `null` when unreported.
  Duration? get coverage => validFromUtc == null || validToUtc == null
      ? null
      : validToUtc!.difference(validFromUtc!);

  bool get hasCoverage => coverage != null;

  /// Tolerant parser. Returns `null` unless *both* percentiles are present and
  /// ordered — a one-sided spread is not a spread.
  static TemperatureSpread? fromJson(Object? raw) {
    final data = jsonMap(raw);
    if (data == null) return null;
    final low = jsonDouble(data['p10_c'] ??
        data['p10'] ??
        data['temp_p10_c'] ??
        data['temperature_p10_c']);
    final high = jsonDouble(data['p90_c'] ??
        data['p90'] ??
        data['temp_p90_c'] ??
        data['temperature_p90_c']);
    if (low == null || high == null || high < low) return null;
    return TemperatureSpread(
      p10C: low,
      p90C: high,
      source: jsonString(data['source'] ?? data['provider']),
      runId: jsonString(data['run_id'] ?? data['run']),
      validFromUtc: jsonUtc(data['valid_from'] ?? data['start']),
      validToUtc: jsonUtc(data['valid_to'] ?? data['end']),
      memberCount: jsonInt(data['members'] ?? data['member_count']),
    );
  }
}

/// Expected precipitation for a bounded interval (the Everyone card uses the
/// next 24 hours). Carries its own coverage so a partial interval is never
/// presented as a full-period total.
class PrecipitationInterval {
  const PrecipitationInterval({
    required this.totalMm,
    this.startUtc,
    this.endUtc,
    this.coversFullPeriod,
    this.source,
    this.runId,
    this.label,
  });

  final double totalMm;
  final DateTime? startUtc;
  final DateTime? endUtc;

  /// `false` when the backend says the interval is incomplete.
  final bool? coversFullPeriod;
  final String? source;
  final String? runId;
  final String? label;

  Duration? get length => startUtc == null || endUtc == null
      ? null
      : endUtc!.difference(startUtc!);

  bool get isComplete => coversFullPeriod != false;

  static PrecipitationInterval? fromJson(Object? raw) {
    final data = jsonMap(raw);
    if (data == null) return null;
    final total = jsonDouble(data['total_mm'] ??
        data['precipitation_mm'] ??
        data['precip_mm'] ??
        data['rain_mm']);
    if (total == null || total < 0) return null;
    return PrecipitationInterval(
      totalMm: total,
      startUtc: jsonUtc(data['start'] ?? data['valid_from']),
      endUtc: jsonUtc(data['end'] ?? data['valid_to']),
      coversFullPeriod: jsonBool(data['complete'] ?? data['covers_full_period']),
      source: jsonString(data['source'] ?? data['provider']),
      runId: jsonString(data['run_id'] ?? data['run']),
      label: jsonString(data['label'] ?? data['interval']),
    );
  }
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.condition,
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
    this.weatherCode,
    this.provenance = WeatherProvenance.none,
    this.temperatureSpread,
    this.precipNext24h,
  });

  final double? temperatureC;
  final double? feelsLikeC;
  final String condition;

  /// WMO code when the backend sent one. `null` means unknown — it must never
  /// be read as code `0` ("clear sky").
  final int? weatherCode;
  final double? highC;
  final double? lowC;
  final num? humidity;
  final num? windKmh;
  final num? windDirection;

  /// Sea-level pressure. Kept separate from any station pressure the backend
  /// may add later rather than overloading one field.
  final num? pressureHpa;
  final num? rainProbability;
  final num? uvIndex;
  final String? sunrise;
  final String? sunset;
  final num? aqi;
  final num? pm25;

  /// Complete supported hourly series. Display layers slice what they need;
  /// truncating here would silently shorten the horizon for other modes.
  final List<HourlyPoint> hourly;
  final List<DayForecast> forecast;
  final String cityName;

  /// Source/run/freshness reported by the backend, if any.
  final WeatherProvenance provenance;

  /// Everyone-mode enrichment 1: forecast temperature p10–p90 range.
  final TemperatureSpread? temperatureSpread;

  /// Everyone-mode enrichment 2: expected precipitation for the next 24 hours.
  final PrecipitationInterval? precipNext24h;

  bool get hasCondition => weatherCode != null || condition != '—';

  /// Number of days the backend actually returned, for horizon labels.
  int get forecastDays => forecast.length;

  /// Number of hourly buckets returned, for horizon labels.
  int get hourlyPoints => hourly.length;

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
