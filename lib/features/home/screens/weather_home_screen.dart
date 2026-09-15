import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_error_view.dart';
import '../../explore/providers/saved_locations_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/providers/developer_options_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/atmosphere_theme.dart';
import '../widgets/atmosphere_video_background.dart';

class WeatherHomeScreen extends ConsumerStatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  ConsumerState<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends ConsumerState<WeatherHomeScreen> {
  int _tab = 0;

  Future<void> _pickLocation() async {
    final current = ref.read(locationProvider);
    final saved = ref.read(savedLocationsProvider);
    final selected = await showModalBottomSheet<AppLocation>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = <AppLocation>[
          ...kPresetLocations,
          ...saved
              .map((s) => AppLocation(name: s.name, lat: s.lat, lon: s.lon)),
        ];
        final seen = <String>{};
        final unique = <AppLocation>[];
        for (final o in options) {
          if (seen.add(o.name)) unique.add(o);
        }
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'home.choose_location'.tr(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.my_location, color: AppColors.accent),
                  title: Text('home.use_my_location'.tr()),
                  onTap: () async {
                    final loc = await ref
                        .read(locationProvider.notifier)
                        .selectFromGps();
                    if (ctx.mounted) Navigator.pop(ctx, loc);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                Expanded(
                  child: ListView.builder(
                    itemCount: unique.length,
                    itemBuilder: (_, i) {
                      final loc = unique[i];
                      final sel = loc.name == current.name;
                      return ListTile(
                        leading: Icon(
                          Icons.place_outlined,
                          color:
                              sel ? AppColors.accent : AppColors.textSecondary,
                        ),
                        title: Text(loc.name),
                        trailing: sel
                            ? const Icon(Icons.check_circle,
                                color: AppColors.accent, size: 20)
                            : null,
                        onTap: () => Navigator.pop(ctx, loc),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) {
      await ref.read(locationProvider.notifier).select(selected);
      ref.invalidate(weatherProvider(ref.read(settingsProvider).userPersona));
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final persona = ref.watch(settingsProvider).userPersona;
    final weatherAsync = ref.watch(weatherProvider(persona));
    final bottomInset = MediaQuery.paddingOf(context).bottom + 80;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: weatherAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => ApiErrorView(
          error: e,
          onRetry: () => ref.invalidate(weatherProvider(persona)),
        ),
        data: (w) {
          final sunrise = parseWeatherTime(w.sunrise);
          final sunset = parseWeatherTime(w.sunset);
          final dev = ref.watch(developerOptionsProvider);
          final period = (dev.enabled && dev.forcePeriod != null)
              ? dev.forcePeriod!
              : periodFromLocalTime(DateTime.now(), sunrise, sunset);
          final sky = (dev.enabled && dev.forceSky != null)
              ? dev.forceSky!
              : conditionFromWeather(w);
          final palette = paletteFor(period, sky);

          return Stack(
            children: [
              Positioned.fill(
                child: (dev.enabled && dev.disableVideoSky)
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [palette.top, palette.mid, palette.bottom],
                          ),
                        ),
                      )
                    : AtmosphereVideoBackground(
                        palette: palette,
                        sky: sky,
                        period: period,
                      ),
              ),
              // readability veil over lower content
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        palette.bottom.withValues(alpha: 0.55),
                        const Color(0xFF0B1220).withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickLocation,
                                child: Row(
                                  children: [
                                    Icon(Icons.near_me_rounded,
                                        size: 18, color: palette.accent),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        location.name.split(',').first,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: palette.text,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down_rounded,
                                        color: palette.textMuted),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.go('/profile'),
                              icon: Icon(Icons.settings_outlined,
                                  color: palette.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _HeroCard(weather: w, palette: palette),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _MetricStrip(weather: w, palette: palette),
                      ),
                    ),
                    const Spacerv(height: 18),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SegmentTabs(
                          index: _tab,
                          onChanged: (i) => setState(() => _tab = i),
                          palette: palette,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _tab == 0
                            ? _OverviewGrid(weather: w, palette: palette)
                            : _tab == 1
                                ? _HourlyPanel(weather: w, palette: palette)
                                : _DailyPanel(weather: w, palette: palette),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: bottomInset + 24)),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset - 52,
                child: Center(
                  child: _VoiceOrb(
                    palette: palette,
                    onTap: () => context.push('/voice/listening', extra: {
                      'accent': palette.accent,
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Spacerv extends StatelessWidget {
  const Spacerv({super.key, required this.height});
  final double height;
  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: SizedBox(height: height));
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.weather, required this.palette});
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

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.weather, required this.palette});
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
        'Rain'
      ),
      (
        Icons.air,
        weather.windKmh == null
            ? '—'
            : '${weather.windKmh!.toStringAsFixed(0)}',
        'Wind km/h'
      ),
      (
        Icons.opacity,
        weather.humidity == null ? '—' : '${weather.humidity!.round()}%',
        'Humidity'
      ),
      (
        Icons.compress,
        weather.pressureHpa == null
            ? '—'
            : '${weather.pressureHpa!.round()}',
        'hPa'
      ),
      (
        Icons.explore_outlined,
        windDirLabel(weather.windDirection),
        'Direction'
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
                  Text(it.$2,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.text)),
                  Text(it.$3,
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

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({
    required this.index,
    required this.onChanged,
    required this.palette,
  });
  final int index;
  final ValueChanged<int> onChanged;
  final AtmospherePalette palette;

  @override
  Widget build(BuildContext context) {
    final labels = [
      'home.tab_overview'.tr(),
      'home.tab_hourly'.tr(),
      'home.tab_7day'.tr(),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? palette.accent.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? palette.accent : palette.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.weather, required this.palette});
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

class _HourlyPanel extends StatelessWidget {
  const _HourlyPanel({required this.weather, required this.palette});
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

class _DailyPanel extends StatelessWidget {
  const _DailyPanel({required this.weather, required this.palette});
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

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({required this.palette, required this.onTap});
  final AtmospherePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [palette.orbStart, palette.orbEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.black87, size: 30),
      ),
    );
  }
}
