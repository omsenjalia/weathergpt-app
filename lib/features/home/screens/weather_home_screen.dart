import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_error_view.dart';
import '../../explore/providers/saved_locations_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_video_background.dart';
import '../../settings/providers/settings_provider.dart';

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
          ...saved.map((s) => AppLocation(name: s.name, lat: s.lat, lon: s.lon)),
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
                  leading: const Icon(Icons.my_location, color: AppColors.accent),
                  title: Text('home.use_my_location'.tr()),
                  onTap: () async {
                    final loc =
                        await ref.read(locationProvider.notifier).selectFromGps();
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
                          color: sel ? AppColors.accent : AppColors.textSecondary,
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
    final bottomInset = MediaQuery.paddingOf(context).bottom + 96;

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
        data: (w) => Stack(
          children: [
            // Real looping weather video (condition-matched)
            Positioned.fill(
              child: WeatherVideoBackground(condition: w.condition, weatherCode: w.weatherCode),
            ),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickLocation,
                              child: Row(
                                children: [
                                  const Icon(Icons.near_me_rounded,
                                      size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      location.name.split(',').first,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.go('/profile'),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _HeroWeather(weather: w, onLocation: _pickLocation),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _MetricStrip(weather: w),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SegmentTabs(
                        index: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _tab == 0
                          ? _OverviewPanel(weather: w)
                          : _tab == 1
                              ? _HourlyPanel(weather: w)
                              : _DailyPanel(weather: w),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: bottomInset + 72)),
                ],
              ),
            ),
            // Voice FAB — above floating nav, right side so it does not cover cards
            Positioned(
              right: 20,
              bottom: bottomInset - 12,
              child: _VoiceOrb(
                onTap: () => context.push('/voice/listening', extra: {
                  'accent': AppColors.accent,
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroWeather extends StatelessWidget {
  const _HeroWeather({required this.weather, required this.onLocation});
  final WeatherSnapshot weather;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientHero,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  weather.temperatureC == null
                      ? '—'
                      : '${weather.temperatureC!.round()}°',
                  style: const TextStyle(
                    fontSize: 72,
                    height: 0.95,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -2,
                  ),
                ),
              ),
              Icon(
                _iconFor(weather.condition),
                size: 48,
                color: AppColors.accentSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            weather.condition,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (weather.feelsLikeC != null) ...[
            const SizedBox(height: 6),
            Text(
              '${'home.feels_like'.tr()} ${weather.feelsLikeC!.round()}°',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _mini('H', weather.highC?.round().toString() ?? '—'),
              const SizedBox(width: 12),
              _mini('L', weather.lowC?.round().toString() ?? '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String k, String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$k $v°',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );

  IconData _iconFor(String c) {
    final s = c.toLowerCase();
    if (s.contains('thunder')) return Icons.thunderstorm_rounded;
    if (s.contains('rain') || s.contains('drizzle')) return Icons.water_drop_rounded;
    if (s.contains('cloud')) return Icons.cloud_rounded;
    if (s.contains('clear') || s.contains('sun')) return Icons.wb_sunny_rounded;
    return Icons.wb_cloudy_rounded;
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.weather});
  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.water_drop_outlined,
          weather.rainProbability == null
              ? '—'
              : '${weather.rainProbability!.round()}%',
          'Rain'),
      (Icons.air,
          weather.windKmh == null
              ? '—'
              : '${weather.windKmh!.toStringAsFixed(0)} km/h',
          'Wind'),
      (Icons.opacity,
          weather.humidity == null ? '—' : '${weather.humidity!.round()}%',
          'Humidity'),
      (Icons.compress,
          weather.pressureHpa == null
              ? '—'
              : '${weather.pressureHpa!.round()}',
          'hPa'),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(it.$1, size: 18, color: AppColors.sky),
                const Spacer(),
                Text(it.$2,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(it.$3,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.accent.withValues(alpha: 0.18) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? AppColors.accentSoft : AppColors.textTertiary,
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

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.weather});
  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                title: 'AQI',
                value: weather.aqi?.toString() ?? '—',
                subtitle: 'Air quality',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                title: 'UV',
                value: weather.uvIndex?.toString() ?? '—',
                subtitle: 'Index',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                title: 'Sunrise',
                value: weather.sunrise ?? '—',
                subtitle: 'Morning',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                title: 'Sunset',
                value: weather.sunset ?? '—',
                subtitle: 'Evening',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _HourlyPanel extends StatelessWidget {
  const _HourlyPanel({required this.weather});
  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    final hours = weather.hourly;
    if (hours.isEmpty) {
      return const Text('Hourly data unavailable',
          style: TextStyle(color: AppColors.textSecondary));
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
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(h.label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('${h.tempC.round()}°',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DailyPanel extends StatelessWidget {
  const _DailyPanel({required this.weather});
  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    final days = weather.forecast;
    if (days.isEmpty) {
      return const Text('Forecast unavailable',
          style: TextStyle(color: AppColors.textSecondary));
    }
    return Column(
      children: days.take(7).map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(d.date,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(d.condition,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
              Text(
                '${d.highC?.round() ?? '—'}° / ${d.lowC?.round() ?? '—'}°',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradientAccent,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.black87, size: 26),
      ),
    );
  }
}
