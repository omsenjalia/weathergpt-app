import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/atmosphere_theme.dart';

/// Live sky: gradient + sun/moon + optional rain/thunder particles.
class AtmosphereBackground extends StatefulWidget {
  const AtmosphereBackground({
    super.key,
    required this.palette,
    required this.sky,
    required this.period,
  });

  final AtmospherePalette palette;
  final SkyCondition sky;
  final DayPeriod period;

  @override
  State<AtmosphereBackground> createState() => _AtmosphereBackgroundState();
}

class _AtmosphereBackgroundState extends State<AtmosphereBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _pulse;
  late final AnimationController _weather;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _weather = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    _pulse.dispose();
    _weather.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return AnimatedBuilder(
      animation: Listenable.merge([_drift, _pulse, _weather]),
      builder: (context, _) {
        return CustomPaint(
          painter: _SkyPainter(
            palette: p,
            sky: widget.sky,
            period: widget.period,
            drift: _drift.value,
            pulse: _pulse.value,
            weatherT: _weather.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.palette,
    required this.sky,
    required this.period,
    required this.drift,
    required this.pulse,
    required this.weatherT,
  });

  final AtmospherePalette palette;
  final SkyCondition sky;
  final DayPeriod period;
  final double drift;
  final double pulse;
  final double weatherT;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.top, palette.mid, palette.bottom],
      stops: const [0.0, 0.45, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Soft ambient glow
    final glowCenter = Offset(
      size.width * (0.5 + (drift - 0.5) * 0.08),
      size.height * 0.22,
    );
    canvas.drawCircle(
      glowCenter,
      size.width * (0.45 + pulse * 0.05),
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.glow.withValues(alpha: 0.35),
            palette.glow.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: size.width * 0.5)),
    );

    if (palette.showSun) {
      final sun = Offset(
        size.width * (0.72 + (drift - 0.5) * 0.04),
        size.height * palette.sunY.clamp(0.08, 0.85),
      );
      final sunR = 28.0 + pulse * 4;
      canvas.drawCircle(
        sun,
        sunR * 2.2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              palette.orbStart.withValues(alpha: 0.55),
              palette.orbEnd.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: sun, radius: sunR * 2.2)),
      );
      canvas.drawCircle(
        sun,
        sunR,
        Paint()
          ..shader = RadialGradient(
            colors: [palette.orbStart, palette.orbEnd],
          ).createShader(Rect.fromCircle(center: sun, radius: sunR)),
      );
    }

    if (palette.showMoon) {
      final moon = Offset(
        size.width * (0.22 + (drift - 0.5) * 0.03),
        size.height * palette.moonY.clamp(0.1, 0.5),
      );
      final moonR = 18.0 + pulse * 2;
      canvas.drawCircle(
        moon,
        moonR * 1.8,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12),
      );
      canvas.drawCircle(
        moon,
        moonR,
        Paint()..color = const Color(0xFFE2E8F0),
      );
      // crescent cut
      canvas.drawCircle(
        moon.translate(moonR * 0.35, -moonR * 0.1),
        moonR * 0.85,
        Paint()..color = palette.top,
      );
    }

    // Stars at night
    if (period == DayPeriod.night ||
        period == DayPeriod.midnight ||
        period == DayPeriod.evening) {
      final rnd = math.Random(42);
      for (var i = 0; i < 40; i++) {
        final x = rnd.nextDouble() * size.width;
        final y = rnd.nextDouble() * size.height * 0.45;
        final a = 0.3 + 0.5 * ((math.sin(weatherT * math.pi * 2 + i) + 1) / 2);
        canvas.drawCircle(
          Offset(x, y),
          rnd.nextDouble() * 1.4 + 0.4,
          Paint()..color = Colors.white.withValues(alpha: a),
        );
      }
    }

    // Rain
    if (sky == SkyCondition.rain || sky == SkyCondition.thunder) {
      final rnd = math.Random(7);
      final rainPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 70; i++) {
        final x = (rnd.nextDouble() * size.width + weatherT * 40 + i * 9) %
            size.width;
        final yBase = (rnd.nextDouble() * size.height + weatherT * size.height) %
            size.height;
        canvas.drawLine(
          Offset(x, yBase),
          Offset(x - 3, yBase + 14),
          rainPaint,
        );
      }
    }

    // Thunder flash
    if (sky == SkyCondition.thunder) {
      final flash = math.sin(weatherT * math.pi * 6);
      if (flash > 0.92) {
        canvas.drawRect(
          rect,
          Paint()..color = Colors.white.withValues(alpha: 0.18),
        );
      }
    }

    // Soft cloud blobs when cloudy/overcast
    if (sky == SkyCondition.cloudy ||
        sky == SkyCondition.overcast ||
        sky == SkyCondition.fog) {
      final cloudPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: sky == SkyCondition.fog ? 0.18 : 0.12,
        );
      for (var i = 0; i < 5; i++) {
        final cx = size.width * ((0.15 * i + drift * 0.08) % 1.0);
        final cy = size.height * (0.12 + i * 0.06);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: 140 + i * 20,
            height: 40 + i * 4,
          ),
          cloudPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) =>
      old.drift != drift ||
      old.pulse != pulse ||
      old.weatherT != weatherT ||
      old.palette != palette ||
      old.sky != sky;
}
