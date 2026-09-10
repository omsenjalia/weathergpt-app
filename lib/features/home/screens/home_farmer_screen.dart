import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/weather_provider.dart';
import '../widgets/home_scaffold.dart';

class HomeFarmerScreen extends ConsumerWidget {
  const HomeFarmerScreen({super.key, this.locationName = 'Ahmedabad, Gujarat'});
  final String locationName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider('farmer'));
    return weather.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (snapshot) => HomeScaffold(
        accentColor: AppColors.farmerGreen,
        metrics: snapshot.metrics,
        weather: snapshot,
        topRightAction: const CircleAvatar(
            backgroundColor: AppColors.farmerGreen,
            child: Icon(Icons.eco, color: AppColors.bgPrimary)),
        micIdleAccent: AppColors.farmerGreen,
        micHintText: 'home.farmer_hint'.tr(),
        suggestedPrompts: [
          'home.farmer_prompt_1'.tr(),
          'home.farmer_prompt_2'.tr(),
          'home.farmer_prompt_3'.tr()
        ],
        showBottomInputBar: false,
        weatherIcon: Icons.cloudy_snowing,
        locationName: locationName,
        belowPrompts: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Expanded(
                child: _FarmTool(
              icon: Icons.eco_outlined,
              label: 'home.my_farm'.tr(),
              onTap: () => context.push('/farmer/farm-profile'),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _FarmTool(
              icon: Icons.schedule_outlined,
              label: 'home.action_windows'.tr(),
              onTap: () => context.push('/farmer/action-windows'),
            )),
          ]),
        ),
      ),
    );
  }
}

class _FarmTool extends StatelessWidget {
  const _FarmTool(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AppCard(
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: AppColors.farmerGreen),
            const SizedBox(width: 7),
            Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        ),
      ));
}
