import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../models/weather.dart';
import '../theme/atmosphere_theme.dart';

/// Horizontal scrolling strip of quick weather metrics.
class WeatherMetricStrip extends StatelessWidget {
  const WeatherMetricStrip({super.key, required this.weather, required this.palette});
  final WeatherSnapshot weather;
  final AtmospherePalette palette;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.water_drop_outlined,
        weather.rainProbability == null
            ? '—'
            : '${weather.rainProbability!.round()}%',
        'home.rain_chance'.tr()
      ),
      (
        Icons.air,
        weather.windKmh == null
            ? '—'
            : '${weather.windKmh!.toStringAsFixed(0)}${weather.windDirection == null ? '' : ' ${windDirLabel(weather.windDirection)}'}',
        'home.wind_kmh'.tr()
      ),
      (
        Icons.opacity,
        weather.humidity == null ? '—' : '${weather.humidity!.round()}%',
        'home.humidity'.tr()
      ),
      (
        Icons.compress,
        weather.pressureHpa == null
            ? '—'
            : '${weather.pressureHpa!.round()}',
        'home.pressure_hpa'.tr()
      ),
      (
        Icons.cloud_outlined,
        weather.cloudCover == null ? '—' : '${weather.cloudCover!.round()}%',
        'home.cloud_cover'.tr()
      ),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + i * 80),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - t)),
                child: child,
              ),
            ),
            child: Container(
              width: 102,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(it.$1, size: 18, color: palette.accent),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(it.$2,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: it.$2 == '—' ? palette.textMuted : palette.text)),
                  ),
                  Text(it.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: palette.textMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
