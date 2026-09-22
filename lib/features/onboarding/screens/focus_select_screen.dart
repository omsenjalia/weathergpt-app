import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/atmosphere_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../farmer/models/farm_profile_model.dart';
import '../../farmer/providers/farm_profile_provider.dart';
import '../../farmer/screens/farm_profile_screen.dart';
import '../../home/providers/atmosphere_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/onboarding_provider.dart';

class FocusSelectScreen extends ConsumerStatefulWidget {
  const FocusSelectScreen({super.key});

  @override
  ConsumerState<FocusSelectScreen> createState() => _FocusSelectScreenState();
}

class _FocusSelectScreenState extends ConsumerState<FocusSelectScreen> {
  late final TextEditingController _locationController;
  late final TextEditingController _sizeController;
  late String _crop;
  late String _stage;
  late String _irrigation;
  late String _soil;

  static const _options = [
    (
      'everyone',
      Icons.person_outline,
      'persona.everyone',
      'persona.everyone_description'
    ),
    (
      'farmer',
      Icons.eco_outlined,
      'persona.farmer',
      'persona.farmer_description'
    ),
    (
      'researcher',
      Icons.bar_chart_outlined,
      'persona.researcher',
      'persona.researcher_description'
    ),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(farmProfileProvider);
    _locationController = TextEditingController(text: profile.location);
    _sizeController = TextEditingController(
      text: profile.farmSizeAcres.toStringAsFixed(
        profile.farmSizeAcres % 1 == 0 ? 0 : 1,
      ),
    );
    _crop = profile.crop;
    _stage = profile.growthStage;
    _irrigation = profile.irrigationType;
    _soil = profile.soilType;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Color _accent(String persona) => switch (persona) {
        'farmer' => AppColors.farmerGreen,
        'researcher' => AppColors.researcherBlue,
        _ => AppColors.accent,
      };

  Future<void> _continue() async {
    final selected = ref.read(onboardingProvider).selectedPersona;
    if (selected == 'farmer') {
      final size = double.tryParse(_sizeController.text.trim()) ?? 4.0;
      final loc = _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : 'Anand, Gujarat';
      final profile = FarmProfile(
        location: loc,
        crop: _crop,
        growthStage: _stage,
        farmSizeAcres: size > 0 ? size : 4.0,
        irrigationType: _irrigation,
        soilType: _soil,
      );
      await ref.read(farmProfileProvider.notifier).save(profile);
    }
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    await ref.read(settingsProvider.notifier).updatePersona(selected);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(onboardingProvider).selectedPersona;
    final palette = ref.watch(atmospherePaletteProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AtmosphereBackground(
            palette: palette,
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('onboarding.focus_headline'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 7),
                  Text('onboarding.focus_hint'.tr(),
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ..._options.map((option) {
                    final active = option.$1 == selected;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => ref
                            .read(onboardingProvider.notifier)
                            .selectPersona(option.$1),
                        child: GlassCard(
                          borderColor: active
                              ? _accent(option.$1)
                              : AppColors.glassBorder,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          radius: 20,
                          strong: active,
                          child: SizedBox(
                            height: 82,
                            child: Row(children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? _accent(option.$1).withValues(alpha: 0.16)
                                      : Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: active
                                        ? _accent(option.$1)
                                        : AppColors.glassBorderStrong,
                                  ),
                                ),
                                child: Icon(option.$2,
                                    color: active
                                        ? _accent(option.$1)
                                        : AppColors.textSecondary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(option.$3.tr(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(option.$4.tr(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? _accent(option.$1)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: active
                                        ? _accent(option.$1)
                                        : AppColors.glassBorderStrong,
                                    width: 1.8,
                                  ),
                                ),
                                child: active
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (selected == 'farmer') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.glassFillStrong,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.farmerGreen.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.farmerGreen
                                      .withValues(alpha: 0.16),
                                  border: Border.all(
                                    color: AppColors.farmerGreen
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.agriculture_rounded,
                                  color: AppColors.farmerGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'farmer.farm_profile'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'farmer.edit_farm_profile'.tr(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          FarmTextField(
                            label: 'farmer.location'.tr(),
                            controller: _locationController,
                          ),
                          FarmTextField(
                            label: '${'farmer.farm_size'.tr()} (acres)',
                            controller: _sizeController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                          FarmSelectField(
                            label: 'farmer.crop'.tr(),
                            value: _crop,
                            values: FarmProfileEditor.crops,
                            onChanged: (v) {
                              if (v != null) setState(() => _crop = v);
                            },
                          ),
                          FarmSelectField(
                            label: 'farmer.growth_stage'.tr(),
                            value: _stage,
                            values: FarmProfileEditor.stages,
                            onChanged: (v) {
                              if (v != null) setState(() => _stage = v);
                            },
                          ),
                          FarmSelectField(
                            label: 'farmer.irrigation_type'.tr(),
                            value: _irrigation,
                            values: FarmProfileEditor.irrigations,
                            onChanged: (v) {
                              if (v != null) setState(() => _irrigation = v);
                            },
                          ),
                          FarmSelectField(
                            label: 'farmer.soil_type'.tr(),
                            value: _soil,
                            values: FarmProfileEditor.soils,
                            onChanged: (v) {
                              if (v != null) setState(() => _soil = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'onboarding.continue'.tr(),
                    onPressed: _continue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
