import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../models/weather.dart';
import '../theme/atmosphere_theme.dart';

/// Source / freshness line plus the two agreed Everyone-mode enrichments
/// (forecast temperature p10–p90 range and expected next-24-hour precipitation).
///
/// Everything here renders only when the backend actually reported it. Nothing
/// is inferred: no rain probability is derived from percentiles, a partial
/// interval is labelled partial rather than shown as a full-period total, and
/// an unreported source says so instead of naming a provider.
class WeatherProvenanceBar extends StatelessWidget {
  const WeatherProvenanceBar({
    super.key,
    required this.weather,
    required this.palette,
    this.showEnrichments = true,
    this.nowUtc,
  });

  final WeatherSnapshot weather;
  final AtmospherePalette palette;

  /// The enrichments belong to Everyone mode; Farmer and Researcher get their
  /// own scope rather than the same card in another colour.
  final bool showEnrichments;

  /// Injectable clock so staleness is testable.
  final DateTime? nowUtc;

  static const _label = TextStyle(fontSize: 10.5, height: 1.1);
  static const _value =
      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.1);

  String _sourceLabel() {
    final provenance = weather.provenance;
    if (!provenance.hasSource) return 'home.source_not_reported'.tr();
    final name = provenance.source!;
    return switch (provenance.provider) {
      WeatherProvider.imd => 'IMD',
      WeatherProvider.weathernext => 'WeatherNext',
      WeatherProvider.accuweather => 'AccuWeather',
      WeatherProvider.openMeteo => 'Open-Meteo',
      WeatherProvider.unknown => name,
    };
  }

  /// Freshness text, or `null` when the backend reported no timestamp. An
  /// unknown age is not rendered as "fresh".
  String? _freshnessLabel() {
    final stamp = weather.provenance.effectiveAtUtc;
    if (stamp == null) return null;
    final stale = weather.provenance
        .isStaleAt(nowUtc ?? DateTime.now().toUtc());
    final time = DateFormat('HH:mm').format(stamp.toLocal());
    return stale
        ? 'home.data_stale'.tr(namedArgs: {'time': time})
        : 'home.updated'.tr(namedArgs: {'time': time});
  }

  @override
  Widget build(BuildContext context) {
    final spread = weather.temperatureSpread;
    final rain = weather.precipNext24h;
    final freshness = _freshnessLabel();

    final chips = <Widget>[
      _chip(
        icon: weather.provenance.fallback
            ? Icons.report_gmailerrorred_outlined
            : Icons.public,
        label: weather.provenance.fallback
            ? 'home.source_fallback'.tr()
            : 'home.source'.tr(),
        value: _sourceLabel(),
        warn: weather.provenance.fallback,
      ),
      if (freshness != null)
        _chip(
          icon: weather.provenance.isStaleAt(nowUtc ?? DateTime.now().toUtc())
              ? Icons.history_toggle_off
              : Icons.schedule,
          label: weather.provenance.isStaleAt(nowUtc ?? DateTime.now().toUtc())
              ? 'home.stale'.tr()
              : 'home.fresh'.tr(),
          value: freshness,
          warn: weather.provenance.isStaleAt(nowUtc ?? DateTime.now().toUtc()),
        ),
      if (weather.provenance.runId != null)
        _chip(
          icon: Icons.memory,
          label: 'home.run'.tr(),
          value: weather.provenance.runId!,
        ),
      if (showEnrichments && spread != null)
        _chip(
          icon: Icons.unfold_more,
          label: 'home.temp_spread'.tr(),
          value:
              '${spread.p10C.round()}°–${spread.p90C.round()}°',
          // A spread is a range, not a probability: the tooltip-free label is
          // deliberately worded so it cannot be read as "X% chance".
        ),
      if (showEnrichments && rain != null)
        _chip(
          icon: Icons.water_drop_outlined,
          label: rain.isComplete
              ? 'home.next_24h_rain'.tr()
              : 'home.next_24h_rain_partial'.tr(),
          value: '${rain.totalMm.toStringAsFixed(rain.totalMm < 10 ? 1 : 0)} mm',
          warn: !rain.isComplete,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required String value,
    bool warn = false,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: warn
                ? const Color(0xFFFBBF24).withValues(alpha: 0.5)
                : const Color(0x33FFFFFF),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: palette.textMuted),
          const SizedBox(width: 5),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(),
                style: _label.copyWith(color: palette.textMuted)),
            Text(value, style: _value.copyWith(color: palette.text)),
          ]),
        ]),
      );
}
