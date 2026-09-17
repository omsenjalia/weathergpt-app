import 'package:flutter/material.dart';

import '../../../models/weather.dart';
import '../theme/atmosphere_theme.dart';

/// Tab body: grid of secondary conditions (AQI, UV, sun, …).
class WeatherOverviewGrid extends StatelessWidget {
  const WeatherOverviewGrid({super.key, required this.weather, required this.palette});
  final WeatherSnapshot weather;
  final AtmospherePalette palette;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('AQI', weather.aqi?.toString() ?? '—', 'Air quality'),
      (
        'UV',
        weather.uvIndex == null
            ? '—'
            : weather.uvIndex!.toStringAsFixed(
                (weather.uvIndex! % 1 == 0) ? 0 : 1),
        'Index'
      ),
      ('Sunrise', formatClock(weather.sunrise), 'Morning'),
      ('Sunset', formatClock(weather.sunset), 'Evening'),
      (
        'PM2.5',
        weather.pm25 == null ? '—' : weather.pm25!.toStringAsFixed(0),
        'µg/m³'
      ),
      (
        'Pressure',
        weather.pressureHpa == null
            ? '—'
            : '${weather.pressureHpa!.round()}',
        'hPa'
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) {
        final t = tiles[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.$1,
                  style: TextStyle(fontSize: 12, color: palette.textMuted)),
              const Spacer(),
              Text(t.$2,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: palette.text)),
              const SizedBox(height: 4),
              Text(t.$3,
                  style: TextStyle(fontSize: 12, color: palette.textMuted)),
            ],
          ),
        );
      },
    );
  }
}

/// Tab body: horizontal scroll of hourly temperatures.
class WeatherHourlyPanel extends StatelessWidget {
  const WeatherHourlyPanel({super.key, required this.weather, required this.palette});
  final WeatherSnapshot weather;
  final AtmospherePalette palette;

  @override
  Widget build(BuildContext context) {
    final hours = weather.hourly;
    if (hours.isEmpty) {
      return Text('Hourly data unavailable',
          style: TextStyle(color: palette.textMuted));
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hours.length.clamp(0, 24),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final h = hours[i];
          return Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(h.label,
                    style:
                        TextStyle(fontSize: 11, color: palette.textMuted)),
                const SizedBox(height: 8),
                Text('${h.tempC.round()}°',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: palette.text)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tab body: 7-day forecast list.
class WeatherDailyPanel extends StatelessWidget {
  const WeatherDailyPanel({super.key, required this.weather, required this.palette});
  final WeatherSnapshot weather;
  final AtmospherePalette palette;

  @override
  Widget build(BuildContext context) {
    final days = weather.forecast;
    if (days.isEmpty) {
      return Text('Forecast unavailable',
          style: TextStyle(color: palette.textMuted));
    }
    return Column(
      children: days.take(7).map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(d.date,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: palette.text)),
              ),
              Expanded(
                child: Text(d.condition,
                    style:
                        TextStyle(color: palette.textMuted, fontSize: 13)),
              ),
              Text(
                '${d.highC?.round() ?? '—'}° / ${d.lowC?.round() ?? '—'}°',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: palette.text),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
