/// Parser for v2 `/v2/weather` — WeatherNext capable.
/// Handles both v2 and legacy v1 so migration is safe.
library;

import '../core/models/data_provenance.dart';
import '../core/models/json_values.dart';
import 'weather.dart';

String _hourLabel(String? iso) {
  if (iso == null) return '';
  try {
    final dt = DateTime.parse(iso);
    final h = dt.toUtc().hour;
    if (h == 0) return '12AM';
    if (h == 12) return '12PM';
    return h > 12 ? '${h - 12}PM' : '${h}AM';
  } catch (_) {
    final h = int.tryParse(iso.length >= 13 ? iso.substring(11, 13) : '') ?? 0;
    if (h == 0) return '12AM';
    if (h == 12) return '12PM';
    return h > 12 ? '${h - 12}PM' : '${h}AM';
  }
}

WeatherSnapshot parseWeatherSnapshotV2(Map<String, dynamic> data, {required String cityName}) {
  final provenance = WeatherProvenance.fromJson(data);

  final hourly = <HourlyPoint>[];
  for (final item in jsonList(data['hourly'])) {
    final row = jsonMap(item);
    if (row == null) continue;
    final temp = jsonDouble(row['temperature_c'] ?? row['temperature']);
    if (temp == null) continue;
    final rawTime = row['time'] ?? row['time_utc'];
    hourly.add(HourlyPoint(
      label: _hourLabel(jsonString(rawTime)),
      tempC: temp,
      timeUtc: jsonUtc(rawTime),
      rainProbability: jsonNum(row['rain_probability'] ?? row['precipitation_probability']),
      precipMm: jsonNum(row['precipitation'] ?? row['precipitation_mm']),
      windKmh: jsonNum(row['wind_kmh'] ?? row['wind_speed_kmh']),
    ));
  }

  final dailyRaw = jsonList(data['daily']).isNotEmpty ? jsonList(data['daily']) : jsonList(data['forecast']);
  final forecast = <DayForecast>[];
  for (final item in dailyRaw) {
    final row = jsonMap(item);
    if (row == null) continue;
    forecast.add(DayForecast(
      date: jsonString(row['date']) ?? '',
      dateUtc: jsonUtc(row['date']),
      highC: jsonDouble(row['high_c']),
      lowC: jsonDouble(row['low_c']),
      condition: jsonString(row['condition']) ?? '—',
      rainProbability: jsonNum(row['rain_probability']),
      precipMm: jsonNum(row['precipitation_mm'] ?? row['rain_mm'] ?? row['rain_sum']),
      precipIntervalLabel: jsonString(row['precipitation_interval']),
      coversFullDay: jsonBool(row['covers_full_day']),
      windKmhMax: jsonNum(row['wind_kmh_max']),
    ));
  }

  final current = jsonMap(data['current']);
  double? temperatureC;
  double? feelsLikeC;
  String condition = '—';
  int? weatherCode;
  double? highC;
  double? lowC;
  num? humidity;
  num? windKmh;
  num? windDirection;
  num? pressureHpa;
  num? rainProbability;
  num? uvIndex;
  String? sunrise;
  String? sunset;
  num? aqi;
  num? pm25;

  if (current != null) {
    temperatureC = jsonDouble(current['temperature_c']);
    feelsLikeC = jsonDouble(current['feels_like_c']);
    condition = jsonString(current['condition']) ?? '—';
    weatherCode = jsonInt(current['weather_code']);
    humidity = jsonNum(current['humidity_percent'] ?? current['humidity']);
    windKmh = jsonNum(current['wind_speed_kmh'] ?? current['wind_kmh']);
    windDirection = jsonNum(current['wind_direction_deg'] ?? current['wind_direction']);
    pressureHpa = jsonNum(current['pressure_hpa']);
    rainProbability = jsonNum(current['precipitation_probability']);
    if (forecast.isNotEmpty) {
      highC = forecast.first.highC;
      lowC = forecast.first.lowC;
    }
    final first = dailyRaw.isNotEmpty ? jsonMap(dailyRaw.first) : null;
    sunrise = jsonString(first?['sunrise']);
    sunset = jsonString(first?['sunset']);
    final aq = jsonMap(data['air_quality']);
    if (aq != null) {
      aqi = jsonNum(aq['european_aqi'] ?? aq['aqi']);
      pm25 = jsonNum(aq['pm2_5'] ?? aq['pm25']);
    }
  } else {
    temperatureC = jsonDouble(data['temperature_c']);
    feelsLikeC = jsonDouble(data['feels_like_c']);
    condition = jsonString(data['condition']) ?? '—';
    weatherCode = jsonInt(data['weather_code']);
    highC = jsonDouble(data['high_c']);
    lowC = jsonDouble(data['low_c']);
    humidity = jsonNum(data['humidity']);
    windKmh = jsonNum(data['wind_kmh']);
    windDirection = jsonNum(data['wind_direction']);
    pressureHpa = jsonNum(data['pressure_hpa']);
    rainProbability = jsonNum(data['rain_probability']);
    uvIndex = jsonNum(data['uv_index']);
    sunrise = jsonString(data['sunrise']);
    sunset = jsonString(data['sunset']);
    aqi = jsonNum(data['aqi']);
    pm25 = jsonNum(data['pm2_5'] ?? data['pm25']);
  }

  return WeatherSnapshot(
    temperatureC: temperatureC,
    feelsLikeC: feelsLikeC,
    condition: condition,
    weatherCode: weatherCode,
    highC: highC,
    lowC: lowC,
    humidity: humidity,
    windKmh: windKmh,
    windDirection: windDirection,
    pressureHpa: pressureHpa,
    rainProbability: rainProbability,
    uvIndex: uvIndex,
    sunrise: sunrise,
    sunset: sunset,
    aqi: aqi,
    pm25: pm25,
    hourly: hourly,
    forecast: forecast,
    cityName: cityName,
    provenance: provenance,
    temperatureSpread: TemperatureSpread.fromJson(data['temperature_spread'] ?? data['temperature_range']),
    precipNext24h: PrecipitationInterval.fromJson(data['precip_next_24h'] ?? data['precipitation_next_24h']),
  );
}
