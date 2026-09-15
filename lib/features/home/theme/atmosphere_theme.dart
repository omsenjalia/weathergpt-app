import 'package:flutter/material.dart';

import '../providers/weather_provider.dart';

enum DayPeriod {
  midnight,
  night,
  sunrise,
  morning,
  midday,
  afternoon,
  sunset,
  evening,
}

enum SkyCondition {
  clear,
  cloudy,
  overcast,
  rain,
  thunder,
  fog,
  snow,
}

class AtmospherePalette {
  const AtmospherePalette({
    required this.top,
    required this.mid,
    required this.bottom,
    required this.accent,
    required this.glow,
    required this.card,
    required this.text,
    required this.textMuted,
    required this.orbStart,
    required this.orbEnd,
    required this.showSun,
    required this.showMoon,
    required this.sunY, // 0 top → 1 bottom of sky band
    required this.moonY,
  });

  final Color top;
  final Color mid;
  final Color bottom;
  final Color accent;
  final Color glow;
  final Color card;
  final Color text;
  final Color textMuted;
  final Color orbStart;
  final Color orbEnd;
  final bool showSun;
  final bool showMoon;
  final double sunY;
  final double moonY;
}

DayPeriod periodFromLocalTime(DateTime now, DateTime? sunrise, DateTime? sunset) {
  final minutes = now.hour * 60 + now.minute;
  final rise = sunrise != null ? sunrise.hour * 60 + sunrise.minute : 6 * 60;
  final set = sunset != null ? sunset.hour * 60 + sunset.minute : 18 * 60 + 30;

  if (minutes >= 0 && minutes < 90) return DayPeriod.midnight; // 0:00–1:30
  if (minutes < rise - 45) return DayPeriod.night;
  if (minutes < rise + 40) return DayPeriod.sunrise;
  if (minutes < rise + 180) return DayPeriod.morning;
  if (minutes < 12 * 60 + 30) return DayPeriod.midday;
  if (minutes < set - 50) return DayPeriod.afternoon;
  if (minutes < set + 35) return DayPeriod.sunset;
  if (minutes < 22 * 60) return DayPeriod.evening;
  return DayPeriod.night;
}

SkyCondition conditionFromWeather(WeatherSnapshot w) {
  final code = w.weatherCode;
  final c = w.condition.toLowerCase();
  if (code >= 95 || c.contains('thunder')) return SkyCondition.thunder;
  if ((code >= 51 && code <= 67) ||
      (code >= 80 && code <= 82) ||
      c.contains('rain') ||
      c.contains('drizzle')) {
    return SkyCondition.rain;
  }
  if ((code >= 71 && code <= 77) || c.contains('snow')) return SkyCondition.snow;
  if ((code >= 45 && code <= 48) || c.contains('fog') || c.contains('mist')) {
    return SkyCondition.fog;
  }
  if (code >= 3 || c.contains('overcast')) return SkyCondition.overcast;
  if (code >= 1 || c.contains('cloud')) return SkyCondition.cloudy;
  return SkyCondition.clear;
}

AtmospherePalette paletteFor(DayPeriod period, SkyCondition sky) {
  // Base by time of day
  AtmospherePalette base = switch (period) {
    DayPeriod.midnight => const AtmospherePalette(
        top: Color(0xFF020617),
        mid: Color(0xFF0B1220),
        bottom: Color(0xFF111827),
        accent: Color(0xFF818CF8),
        glow: Color(0xFF312E81),
        card: Color(0xCC0F172A),
        text: Color(0xFFF1F5F9),
        textMuted: Color(0xFF94A3B8),
        orbStart: Color(0xFFA5B4FC),
        orbEnd: Color(0xFF6366F1),
        showSun: false,
        showMoon: true,
        sunY: 1.2,
        moonY: 0.22,
      ),
    DayPeriod.night => const AtmospherePalette(
        top: Color(0xFF0B1225),
        mid: Color(0xFF111B33),
        bottom: Color(0xFF1A2438),
        accent: Color(0xFF93C5FD),
        glow: Color(0xFF1E3A5F),
        card: Color(0xCC152036),
        text: Color(0xFFF8FAFC),
        textMuted: Color(0xFF94A3B8),
        orbStart: Color(0xFFE2E8F0),
        orbEnd: Color(0xFF94A3B8),
        showSun: false,
        showMoon: true,
        sunY: 1.2,
        moonY: 0.28,
      ),
    DayPeriod.sunrise => const AtmospherePalette(
        top: Color(0xFF1E3A5F),
        mid: Color(0xFFB45309),
        bottom: Color(0xFFFDBA74),
        accent: Color(0xFFFBBF24),
        glow: Color(0xFFF97316),
        card: Color(0xCC1C1917),
        text: Color(0xFFFFFBEB),
        textMuted: Color(0xFFE7E5E4),
        orbStart: Color(0xFFFDE68A),
        orbEnd: Color(0xFFF97316),
        showSun: true,
        showMoon: false,
        sunY: 0.72,
        moonY: 1.2,
      ),
    DayPeriod.morning => const AtmospherePalette(
        top: Color(0xFF38BDF8),
        mid: Color(0xFF7DD3FC),
        bottom: Color(0xFFE0F2FE),
        accent: Color(0xFF0284C7),
        glow: Color(0xFF38BDF8),
        card: Color(0xCC0C4A6E),
        text: Color(0xFF0C4A6E),
        textMuted: Color(0xFF0369A1),
        orbStart: Color(0xFFFEF08A),
        orbEnd: Color(0xFFFBBF24),
        showSun: true,
        showMoon: false,
        sunY: 0.35,
        moonY: 1.2,
      ),
    DayPeriod.midday => const AtmospherePalette(
        top: Color(0xFF0EA5E9),
        mid: Color(0xFF38BDF8),
        bottom: Color(0xFFBAE6FD),
        accent: Color(0xFFF59E0B),
        glow: Color(0xFFFBBF24),
        card: Color(0xCC0C4A6E),
        text: Color(0xFF0C4A6E),
        textMuted: Color(0xFF0369A1),
        orbStart: Color(0xFFFEF9C3),
        orbEnd: Color(0xFFF59E0B),
        showSun: true,
        showMoon: false,
        sunY: 0.18,
        moonY: 1.2,
      ),
    DayPeriod.afternoon => const AtmospherePalette(
        top: Color(0xFF0284C7),
        mid: Color(0xFF0EA5E9),
        bottom: Color(0xFF7DD3FC),
        accent: Color(0xFF2DD4BF),
        glow: Color(0xFF38BDF8),
        card: Color(0xCC0F2744),
        text: Color(0xFFF0F9FF),
        textMuted: Color(0xFFBAE6FD),
        orbStart: Color(0xFFFDE68A),
        orbEnd: Color(0xFFFBBF24),
        showSun: true,
        showMoon: false,
        sunY: 0.42,
        moonY: 1.2,
      ),
    DayPeriod.sunset => const AtmospherePalette(
        top: Color(0xFF312E81),
        mid: Color(0xFFEA580C),
        bottom: Color(0xFFFBBF24),
        accent: Color(0xFFFB923C),
        glow: Color(0xFFEA580C),
        card: Color(0xCC1C0A00),
        text: Color(0xFFFFF7ED),
        textMuted: Color(0xFFFED7AA),
        orbStart: Color(0xFFFED7AA),
        orbEnd: Color(0xFFEA580C),
        showSun: true,
        showMoon: true,
        sunY: 0.78,
        moonY: 0.25,
      ),
    DayPeriod.evening => const AtmospherePalette(
        top: Color(0xFF1E1B4B),
        mid: Color(0xFF312E81),
        bottom: Color(0xFF1E3A5F),
        accent: Color(0xFFA78BFA),
        glow: Color(0xFF4C1D95),
        card: Color(0xCC0F172A),
        text: Color(0xFFF5F3FF),
        textMuted: Color(0xFFC4B5FD),
        orbStart: Color(0xFFE0E7FF),
        orbEnd: Color(0xFFA5B4FC),
        showSun: false,
        showMoon: true,
        sunY: 1.2,
        moonY: 0.30,
      ),
  };

  // Weather overlays darken / cool the palette
  if (sky == SkyCondition.rain || sky == SkyCondition.thunder) {
    return AtmospherePalette(
      top: Color.lerp(base.top, const Color(0xFF1E293B), 0.55)!,
      mid: Color.lerp(base.mid, const Color(0xFF334155), 0.5)!,
      bottom: Color.lerp(base.bottom, const Color(0xFF475569), 0.45)!,
      accent: sky == SkyCondition.thunder
          ? const Color(0xFFA78BFA)
          : const Color(0xFF38BDF8),
      glow: sky == SkyCondition.thunder
          ? const Color(0xFF7C3AED)
          : const Color(0xFF0EA5E9),
      card: Color.lerp(base.card, const Color(0xFF0F172A), 0.4)!,
      text: const Color(0xFFF8FAFC),
      textMuted: const Color(0xFFCBD5E1),
      orbStart: base.orbStart,
      orbEnd: base.orbEnd,
      showSun: false,
      showMoon: period == DayPeriod.night ||
          period == DayPeriod.midnight ||
          period == DayPeriod.evening,
      sunY: base.sunY,
      moonY: base.moonY,
    );
  }
  if (sky == SkyCondition.overcast || sky == SkyCondition.fog) {
    return AtmospherePalette(
      top: Color.lerp(base.top, const Color(0xFF64748B), 0.35)!,
      mid: Color.lerp(base.mid, const Color(0xFF94A3B8), 0.3)!,
      bottom: Color.lerp(base.bottom, const Color(0xFFCBD5E1), 0.25)!,
      accent: base.accent,
      glow: base.glow,
      card: base.card,
      text: base.text,
      textMuted: base.textMuted,
      orbStart: base.orbStart,
      orbEnd: base.orbEnd,
      showSun: base.showSun && sky != SkyCondition.overcast,
      showMoon: base.showMoon,
      sunY: base.sunY,
      moonY: base.moonY,
    );
  }
  return base;
}

DateTime? parseWeatherTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    // Handles "2026-09-15T06:26" and full ISO
    var s = raw.trim();
    if (s.length == 16 && s.contains('T')) s = '${s}:00';
    return DateTime.tryParse(s);
  } catch (_) {
    return null;
  }
}

String formatClock(String? raw) {
  final dt = parseWeatherTime(raw);
  if (dt == null) return '—';
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$h12:$m $period';
}

String windDirLabel(num? deg) {
  if (deg == null) return '—';
  const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final i = ((deg % 360) / 45).round() % 8;
  return dirs[i];
}
