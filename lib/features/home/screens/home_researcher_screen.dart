import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_error_view.dart';
import '../providers/weather_provider.dart';
import '../widgets/home_scaffold.dart';

class HomeResearcherScreen extends ConsumerWidget {
  const HomeResearcherScreen(
      {super.key, this.locationName = 'Ahmedabad, Gujarat'});
  final String locationName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider('researcher'));
    return weather.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => ApiErrorView(
        error: error,
        onRetry: () => ref.invalidate(weatherProvider('researcher')),
      ),
      data: (snapshot) => HomeScaffold(
        accentColor: AppColors.researcherBlue,
        metrics: snapshot.metrics,
        weather: snapshot,
        topRightAction: IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
        micIdleAccent: AppColors.researcherBlue,
        micHintText: 'home.researcher_hint'.tr(),
        suggestedPrompts: [
          'home.researcher_prompt_1'.tr(),
          'home.researcher_prompt_2'.tr(),
          'home.researcher_prompt_3'.tr()
        ],
        promptRoutes: {
          'home.researcher_prompt_1'.tr(): '/researcher/trends?metric=rainfall',
          'home.researcher_prompt_2'.tr(): '/researcher/comparison',
          'home.researcher_prompt_3'.tr(): '/researcher/historical',
        },
        showBottomInputBar: true,
        weatherIcon: Icons.wb_cloudy_outlined,
        locationName: locationName,
      ),
    );
  }
}
