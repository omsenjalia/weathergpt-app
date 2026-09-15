import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_error_view.dart';
import '../../explore/providers/saved_locations_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';

/// Web-parity weather landing page (Overview / metrics / prompts / voice).
class WeatherHomeScreen extends ConsumerStatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  ConsumerState<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends ConsumerState<WeatherHomeScreen> {
  int _tab = 0; // 0 overview, 1 hourly, 2 7-day
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final current = ref.read(locationProvider);
    final saved = ref.read(savedLocationsProvider);
    final selected = await showModalBottomSheet<AppLocation>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            height: MediaQuery.of(ctx).size.height * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choose location',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.my_location,
                      color: AppColors.statusAmber),
                  title: const Text('Use my location'),
                  onTap: () async {
                    final loc =
                        await ref.read(locationProvider.notifier).selectFromGps();
                    if (ctx.mounted) Navigator.pop(ctx, loc);
                  },
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: unique.length,
                    itemBuilder: (_, i) {
                      final loc = unique[i];
                      final sel = loc.name == current.name;
                      return ListTile(
                        leading: Icon(Icons.location_on_outlined,
                            color: sel
                                ? AppColors.statusAmber
                                : AppColors.textSecondary),
                        title: Text(loc.name),
                        trailing: sel
                            ? const Icon(Icons.check,
                                color: AppColors.statusAmber, size: 20)
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
      ref.invalidate(weatherProvider);
    }
  }

  void _openVoice([String? prompt]) {
    context.push('/voice/listening', extra: {
      'prompt': prompt,
      'accent': AppColors.statusAmber,
    });
  }


  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider('everyone'));
    final location = ref.watch(locationProvider);

    return weatherAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ApiErrorView(
        error: e,
        onRetry: () => ref.invalidate(weatherProvider('everyone')),
      ),
      data: (w) => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _Header(onMenu: () {})),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'your weather, always clear.',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _SearchField(
                              controller: _searchCtrl,
                              onSubmit: (q) async {
                                // Simple preset match; full geocode can come later
                                final match = kPresetLocations.where((l) =>
                                    l.name.toLowerCase().contains(q.toLowerCase()));
                                if (match.isNotEmpty) {
                                  await ref
                                      .read(locationProvider.notifier)
                                      .select(match.first);
                                  ref.invalidate(weatherProvider);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Try a major city name, or pick from the list.'),
                                    ),
                                  );
                                  _pickLocation();
                                }
                              },
                              onTapIcon: _pickLocation,
                            ),
                            const SizedBox(height: 14),
                            _TabRow(
                              index: _tab,
                              onChanged: (i) => setState(() => _tab = i),
                            ),
                            const SizedBox(height: 14),
                            _HeroCard(
                              weather: w,
                              locationLabel: location.name.split(',').first,
                              onLocationTap: _pickLocation,
                            ),
                            const SizedBox(height: 12),
                            if (_tab == 0)
                              _MetricGrid(weather: w)
                            else if (_tab == 1)
                              _HourlyList(points: w.hourly)
                            else
                              _SevenDayList(days: w.forecast),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Large animated mic only — chat lives in the Chat tab.
              _VoiceFab(onTap: () => _openVoice()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMenu});
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.menu),
          ),
          const Expanded(
            child: Text(
              'WeatherGPT',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmit,
    required this.onTapIcon,
  });
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onTapIcon;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTapIcon,
            child: const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search location...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    const labels = ['Overview', 'Hourly', '7-Day'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final selected = index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surfaceCardAlt : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: selected
                      ? Border.all(color: AppColors.borderSubtle)
                      : null,
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.weather,
    required this.locationLabel,
    required this.onLocationTap,
  });
  final WeatherSnapshot weather;
  final String locationLabel;
  final VoidCallback onLocationTap;

  IconData get _icon {
    final c = weather.weatherCode;
    if (c == 0 || c == 1) return Icons.wb_sunny_outlined;
    if (c == 2) return Icons.cloud_queue;
    if (c == 3) return Icons.cloud_outlined;
    if (c >= 51 && c <= 67) return Icons.water_drop_outlined;
    if (c >= 80) return Icons.thunderstorm_outlined;
    return Icons.cloud_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onLocationTap,
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.statusAmber),
                const SizedBox(width: 6),
                Text(locationLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(width: 8),
                Text('|  $date',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather.temperatureC == null
                    ? '—'
                    : '${weather.temperatureC!.round()}°',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w600,
                  height: 0.95,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('C',
                    style: TextStyle(
                        fontSize: 22, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(weather.condition,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      weather.feelsLikeC == null
                          ? ''
                          : 'Feels Like ${weather.feelsLikeC!.round()}°c',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(_icon, size: 36, color: AppColors.statusAmber),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Pill(
                title: 'HIGH / LOW',
                value:
                    '${weather.highC?.round() ?? '—'}° / ${weather.lowC?.round() ?? '—'}°',
              ),
              const SizedBox(width: 8),
              _Pill(
                title: 'HUMIDITY',
                value: weather.humidity == null
                    ? '—'
                    : '${weather.humidity!.round()}%',
              ),
              const SizedBox(width: 8),
              _Pill(
                title: 'WIND',
                value: weather.windKmh == null
                    ? '—'
                    : '${weather.windKmh!.round()} km/h',
              ),
            ],
          ),
          if (weather.hourly.isNotEmpty) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 56,
              child: CustomPaint(
                painter: _SparklinePainter(
                  weather.hourly.map((e) => e.tempC).toList(),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: weather.hourly.take(7).map((h) {
                return Expanded(
                  child: Text(
                    '${h.tempC.round()}°',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCardAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.4,
                    color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.1 ? 1.0 : maxV - minV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minV) / range) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    // last point
    final lastX = size.width;
    final lastY = size.height -
        ((values.last - minV) / range) * (size.height - 8) -
        4;
    canvas.drawCircle(Offset(lastX, lastY), 3.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.values != values;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.weather});
  final WeatherSnapshot weather;

  String _aqiLabel(num? aqi) {
    if (aqi == null) return '—';
    final v = aqi.toDouble();
    if (v <= 40) return 'GOOD';
    if (v <= 80) return 'MODERATE';
    if (v <= 120) return 'POOR';
    return 'BAD';
  }

  Color _aqiColor(num? aqi) {
    if (aqi == null) return AppColors.textSecondary;
    final v = aqi.toDouble();
    if (v <= 40) return AppColors.statusGreenText;
    if (v <= 80) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  String _uvLabel(num? uv) {
    if (uv == null) return '—';
    final v = uv.toDouble();
    if (v <= 2) return 'LOW';
    if (v <= 5) return 'MOD';
    if (v <= 7) return 'HIGH';
    if (v <= 10) return 'V.HIGH';
    return 'EXT';
  }

  String _cardinal(num? deg) {
    if (deg == null) return '—';
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg / 45).round()) % 8];
  }

  String _timeOnly(String? iso) {
    if (iso == null || iso.length < 16) return '--:--';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return iso.substring(11, 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                title: 'AQI',
                badge: _aqiLabel(weather.aqi),
                badgeColor: _aqiColor(weather.aqi),
                value: weather.aqi?.round().toString() ?? '—',
                subtitle: weather.pm25 == null
                    ? 'PM2.5 —'
                    : 'PM2.5: ${weather.pm25!.toStringAsFixed(1)} µg/m³',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoCard(
                title: 'UV INDEX',
                badge: _uvLabel(weather.uvIndex),
                badgeColor: AppColors.statusAmber,
                value: weather.uvIndex == null
                    ? '—'
                    : weather.uvIndex!.toStringAsFixed(1),
                subtitle: 'Max scale 12',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                title: 'WIND',
                badge: _cardinal(weather.windDirection),
                badgeColor: AppColors.researcherBlue,
                value: weather.windKmh?.round().toString() ?? '—',
                subtitle: weather.windDirection == null
                    ? '—'
                    : 'Bearing ${weather.windDirection!.round()}°',
                unit: 'km/h',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoCard(
                title: 'DAYLIGHT',
                badge: 'SUN',
                badgeColor: AppColors.statusAmber,
                value: '',
                customBody: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_timeOnly(weather.sunrise)}  –  ${_timeOnly(weather.sunset)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(colors: [
                          Color(0xFFFBBF24),
                          Color(0xFFF97316),
                          Color(0xFF374151),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InfoCard(
          title: 'PRESSURE',
          badge: 'HPA',
          badgeColor: AppColors.statusGreenText,
          value: weather.pressureHpa?.round().toString() ?? '—',
          subtitle: 'Standard Pressure',
          fullWidth: true,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.value,
    this.subtitle = '',
    this.unit,
    this.customBody,
    this.fullWidth = false,
    this.valueSuffix = false,
  });
  final String title;
  final String badge;
  final Color badgeColor;
  final String value;
  final String subtitle;
  final String? unit;
  final Widget? customBody;
  final bool fullWidth;
  final bool valueSuffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        badge,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (customBody != null)
            customBody!
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w700, height: 1)),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(unit!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ],
                if (valueSuffix)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 4),
                    child: Text('/ 12',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ),
              ],
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _HourlyList extends StatelessWidget {
  const _HourlyList({required this.points});
  final List<HourlyPoint> points;
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Hourly data unavailable. Redeploy backend for full payload.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: points
          .map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    SizedBox(
                        width: 56,
                        child: Text(p.label,
                            style: const TextStyle(
                                color: AppColors.textSecondary))),
                    const Spacer(),
                    Text('${p.tempC.round()}°',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _SevenDayList extends StatelessWidget {
  const _SevenDayList({required this.days});
  final List<DayForecast> days;
  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Forecast unavailable.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: days.map((d) {
        String label = d.date;
        try {
          label = DateFormat('EEE, MMM d').format(DateTime.parse(d.date));
        } catch (_) {}
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
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(d.condition,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              Text('${d.highC?.round() ?? '—'}° / ${d.lowC?.round() ?? '—'}°',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }
}


class _VoiceFab extends StatefulWidget {
  const _VoiceFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_VoiceFab> createState() => _VoiceFabState();
}

class _VoiceFabState extends State<_VoiceFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = 0.85 + (_controller.value * 0.15);
            final glow = 0.18 + (_controller.value * 0.22);
            return Transform.scale(
              scale: pulse,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceCardAlt,
                    border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.statusAmber.withValues(alpha: glow),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 36,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
