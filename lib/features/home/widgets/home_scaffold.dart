import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_chip.dart';
import '../../../core/widgets/outlined_button_pill.dart';
import '../providers/weather_provider.dart';

class HomeScaffold extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, showBottomInputBar ? 100 : 24),
                child: Column(
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 19),
                      const SizedBox(width: 5),
                      Text(locationName, style: const TextStyle(fontSize: 15)),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                      const Spacer(),
                      SizedBox(width: 40, height: 40, child: topRightAction),
                    ]),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(weatherIcon, size: 60, color: accentColor),
                      const SizedBox(width: 18),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(weather.temperature,
                                style: const TextStyle(
                                    fontSize: 60,
                                    height: .95,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 7),
                            Text(weather.condition,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15)),
                            const SizedBox(height: 3),
                            Text(weather.range,
                                style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 13)),
                          ]),
                    ]),
                    const SizedBox(height: 28),
                    Row(
                        children: metrics
                            .map((metric) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: metric == metrics.last ? 0 : 8),
                                    child: MetricChip(
                                        icon: metric.icon,
                                        value: metric.value,
                                        label:
                                            metric.qualifier ?? metric.label),
                                  ),
                                ))
                            .toList()),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () => _openVoice(context),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: micIdleAccent == null
                              ? AppColors.surfaceCardAlt
                              : AppColors.bgPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: micIdleAccent ?? AppColors.borderSubtle,
                              width: micIdleAccent == null ? 1 : 2),
                          boxShadow: micIdleAccent == null
                              ? null
                              : [
                                  BoxShadow(
                                      color:
                                          micIdleAccent!.withValues(alpha: .5),
                                      blurRadius: 26,
                                      spreadRadius: 3)
                                ],
                        ),
                        child: Icon(Icons.mic_none_rounded,
                            size: 44,
                            color: micIdleAccent ?? AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(micHintText,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 15)),
                    const SizedBox(height: 20),
                    ...suggestedPrompts.map((prompt) => Padding(
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
                              }),
                        )),
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
                        border: Border.all(color: AppColors.borderSubtle)),
                    child: Row(children: [
                      Expanded(
                          child: Text('home.ask_something_else'.tr(),
                              style: const TextStyle(color: AppColors.textTertiary))),
                      IconButton(
                          onPressed: () => _openVoice(context),
                          icon:
                              Icon(Icons.mic_none_rounded, color: accentColor)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      );
}
