import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_chip.dart';
import '../../../core/widgets/outlined_button_pill.dart';
import '../../explore/providers/saved_locations_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';

class HomeScaffold extends ConsumerWidget {
  const HomeScaffold({
    super.key,
    required this.accentColor,
    required this.metrics,
    required this.topRightAction,
    required this.micIdleAccent,
    required this.micHintText,
    required this.suggestedPrompts,
    required this.showBottomInputBar,
    required this.weatherIcon,
    required this.weather,
    this.locationName = 'Ahmedabad, Gujarat',
    this.belowPrompts,
    this.promptRoutes = const {},
  });

  final Color accentColor;
  final List<WeatherMetric> metrics;
  final Widget topRightAction;
  final Color? micIdleAccent;
  final String micHintText;
  final List<String> suggestedPrompts;
  final bool showBottomInputBar;
  final IconData weatherIcon;
  final WeatherSnapshot weather;
  final String locationName;
  final Widget? belowPrompts;
  final Map<String, String> promptRoutes;

  void _openVoice(BuildContext context, [String? prompt]) {
    context.push('/voice/listening',
        extra: {'prompt': prompt, 'accent': accentColor});
  }

  Future<void> _pickLocation(BuildContext context, WidgetRef ref) async {
    final current = ref.read(locationProvider);
    final saved = ref.read(savedLocationsProvider);
    final selected = await showModalBottomSheet<AppLocation>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = <AppLocation>[
          ...kPresetLocations,
          ...saved.map((s) => AppLocation(name: s.name, lat: s.lat, lon: s.lon)),
        ];
        // de-dupe by name
        final seen = <String>{};
        final unique = <AppLocation>[];
        for (final o in options) {
          if (seen.add(o.name)) unique.add(o);
        }
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  child: Text(
                    'Choose location',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.my_location, color: accentColor),
                title: const Text('Use my location'),
                subtitle: const Text('GPS'),
                onTap: () async {
                  final loc = await ref.read(locationProvider.notifier).selectFromGps();
                  if (ctx.mounted) {
                    Navigator.pop(ctx, loc);
                  }
                },
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: unique.length,
                  itemBuilder: (_, i) {
                    final loc = unique[i];
                    final isSelected = loc.name == current.name;
                    return ListTile(
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: isSelected ? accentColor : AppColors.textSecondary,
                      ),
                      title: Text(loc.name),
                      trailing: isSelected
                          ? Icon(Icons.check, color: accentColor, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, loc),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      // GPS path already persisted; presets need select()
      if (selected.name != 'Current location' ||
          ref.read(locationProvider).name != selected.name) {
        await ref.read(locationProvider.notifier).select(selected);
      }
      ref.invalidate(weatherProvider);
    } else {
      // user dismissed or GPS failed when they expected a result — no-op
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final displayName =
        location.name.isNotEmpty ? location.name : locationName;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, showBottomInputBar ? 100 : 24),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickLocation(context, ref),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 19),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 40, height: 40, child: topRightAction),
                  ]),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(weatherIcon, size: 56, color: accentColor),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weather.temperature,
                            style: const TextStyle(
                              fontSize: 56,
                              height: .95,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            weather.condition,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            weather.range,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: MetricChip(
                            icon: metrics[i].icon,
                            value: metrics[i].value,
                            label: metrics[i].qualifier ?? metrics[i].label,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 36),
                  GestureDetector(
                    onTap: () => _openVoice(context),
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceCardAlt,
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: (micIdleAccent ?? AppColors.textPrimary)
                                .withValues(alpha: 0.12),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: 44,
                        color: micIdleAccent ?? AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    micHintText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...suggestedPrompts.map(
                    (prompt) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButtonPill(
                        label: prompt,
                        onPressed: () {
                          final route = promptRoutes[prompt];
                          if (route != null) {
                            context.push(route);
                          } else {
                            _openVoice(context, prompt);
                          }
                        },
                      ),
                    ),
                  ),
                  if (belowPrompts != null) ...[
                    const SizedBox(height: 8),
                    belowPrompts!,
                  ],
                ],
              ),
            ),
            if (showBottomInputBar)
              Positioned(
                left: 20,
                right: 20,
                bottom: 12,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCardAlt,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        'home.ask_something_else'.tr(),
                        style: const TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openVoice(context),
                      icon: Icon(Icons.mic_none_rounded, color: accentColor),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
