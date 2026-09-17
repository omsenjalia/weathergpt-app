import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_error_view.dart';
import '../../../models/location.dart';
import '../../explore/providers/saved_locations_provider.dart';
import '../../settings/providers/developer_options_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/atmosphere_theme.dart';
import '../widgets/atmosphere_video_background.dart';
import '../widgets/voice_orb.dart';
import '../widgets/weather_detail_panels.dart';
import '../widgets/weather_hero_card.dart';
import '../widgets/weather_metric_strip.dart';
import '../widgets/weather_segment_tabs.dart';

class WeatherHomeScreen extends ConsumerStatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  ConsumerState<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends ConsumerState<WeatherHomeScreen> {
  int _tab = 0;

  Future<void> _pickLocation() async {
    final selected = await showModalBottomSheet<AppLocation>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _LocationSheet(),
    );
    if (selected != null) {
      // weatherProvider re-fetches automatically on location change,
      // so no manual invalidate is needed.
      await ref.read(locationProvider.notifier).select(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final bottomInset = bottomPad + 100; // space for nav + mic

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: weatherAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => ApiErrorView(
          error: e,
          onRetry: () => ref.invalidate(weatherProvider),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
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
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 8,
                                              ),
                                            ],
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
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: WeatherHeroCard(weather: w, palette: palette),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: WeatherMetricStrip(weather: w, palette: palette),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: WeatherSegmentTabs(
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
                            ? WeatherOverviewGrid(weather: w, palette: palette)
                            : _tab == 1
                                ? WeatherHourlyPanel(weather: w, palette: palette)
                                : WeatherDailyPanel(weather: w, palette: palette),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: bottomInset + 24)),
                  ],
                ),
              ),
              // Mic FAB — above floating nav bar (classic position)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPad + 78,
                child: Center(
                  child: VoiceOrb(
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

/// Bottom sheet listing preset + saved locations and the GPS option.
class _LocationSheet extends ConsumerWidget {
  const _LocationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(locationProvider);
    final saved = ref.watch(savedLocationsProvider);
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
        height: MediaQuery.of(context).size.height * 0.6,
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.my_location, color: AppColors.accent),
              title: Text('home.use_my_location'.tr()),
              onTap: () async {
                final loc =
                    await ref.read(locationProvider.notifier).selectFromGps();
                if (context.mounted) Navigator.pop(context, loc);
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
                    onTap: () => Navigator.pop(context, loc),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
