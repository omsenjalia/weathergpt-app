import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/weather_provider.dart';
import '../widgets/home_scaffold.dart';

class HomeEveryoneScreen extends ConsumerWidget {
  const HomeEveryoneScreen(
      {super.key, this.locationName = 'Ahmedabad, Gujarat'});
  final String locationName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider('everyone'));
    return weather.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(weatherProvider('everyone')),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (snapshot) => HomeScaffold(
        accentColor: AppColors.statusAmber,
        metrics: snapshot.metrics,
        weather: snapshot,
        topRightAction: const Icon(Icons.settings_outlined),
        micIdleAccent: null,
        micHintText: 'home.everyone_hint'.tr(),
        suggestedPrompts: [
          'home.everyone_prompt_1'.tr(),
          'home.everyone_prompt_2'.tr(),
          'home.everyone_prompt_3'.tr()
        ],
        showBottomInputBar: false,
        weatherIcon: Icons.wb_cloudy_outlined,
        locationName: locationName,
      ),
    );
  }
}
