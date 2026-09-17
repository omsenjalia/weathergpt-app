import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/weather.dart';
import '../theme/atmosphere_theme.dart';

/// The big temperature card at the top of the home screen.
class WeatherHeroCard extends StatelessWidget {
  const WeatherHeroCard({super.key, required this.weather, required this.palette});
  final WeatherSnapshot weather;
  final AtmospherePalette palette;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: palette.glow.withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date,
                style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    weather.temperatureC == null
                        ? '—'
                        : '${weather.temperatureC!.round()}°',
                    style: TextStyle(
                      fontSize: 72,
                      height: 0.95,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -2,
                      color: palette.text,
                    ),
                  ),
                ),
                Icon(_iconFor(weather.condition),
                    size: 48, color: palette.accent),
              ],
            ),
            const SizedBox(height: 6),
            Text(weather.condition,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: palette.text)),
            if (weather.feelsLikeC != null) ...[
              const SizedBox(height: 6),
              Text(
                '${'home.feels_like'.tr()} ${weather.feelsLikeC!.round()}°',
                style: TextStyle(color: palette.textMuted),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _pill('H ${weather.highC?.round() ?? '—'}°', palette),
                const SizedBox(width: 8),
                _pill('L ${weather.lowC?.round() ?? '—'}°', palette),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String t, AtmospherePalette p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textMuted)),
      );

  IconData _iconFor(String c) {
    final s = c.toLowerCase();
    if (s.contains('thunder')) return Icons.thunderstorm_rounded;
    if (s.contains('rain') || s.contains('drizzle')) {
      return Icons.water_drop_rounded;
    }
    if (s.contains('cloud') || s.contains('overcast')) return Icons.cloud_rounded;
    if (s.contains('clear') || s.contains('sun')) return Icons.wb_sunny_rounded;
    return Icons.wb_cloudy_rounded;
  }
}
