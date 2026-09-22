import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/atmosphere_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../home/theme/atmosphere_theme.dart';

/// Farmer hub — the dedicated "Farm" tab. Every farmer tool lives one tap
/// from here instead of inside Settings.
class FarmerHubScreen extends ConsumerWidget {
  const FarmerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ambientPalette();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AtmosphereBackground(
            top: palette.top,
            mid: palette.mid,
            bottom: palette.bottom,
            glow: AppColors.farmerGreen,
            secondaryGlow: palette.accent,
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.paddingOf(context).bottom + 96,
              ),
              children: [
                Text(
                  'persona.farmer'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'persona.farmer_description'.tr(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _HubCard(
                  icon: Icons.schedule_rounded,
                  accent: AppColors.farmerGreen,
                  title: 'home.action_windows'.tr(),
                  onTap: () => context.push('/farmer/action-windows'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.agriculture_outlined,
                  accent: AppColors.farmerGreen,
                  title: 'farmer.farm_profile'.tr(),
                  onTap: () => context.push('/farmer/farm-profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Researcher hub — the dedicated "Lab" tab with the three analysis tools.
class ResearcherHubScreen extends ConsumerWidget {
  const ResearcherHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ambientPalette();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AtmosphereBackground(
            top: palette.top,
            mid: palette.mid,
            bottom: palette.bottom,
            glow: AppColors.researcherBlue,
            secondaryGlow: palette.accent,
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.paddingOf(context).bottom + 96,
              ),
              children: [
                Text(
                  'persona.researcher'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'persona.researcher_description'.tr(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _HubCard(
                  icon: Icons.history_rounded,
                  accent: AppColors.researcherBlue,
                  title: 'researcher.historical_weather'.tr(),
                  onTap: () => context.push('/researcher/historical'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.compare_arrows_rounded,
                  accent: AppColors.researcherBlue,
                  title: 'researcher.compare_locations'.tr(),
                  onTap: () => context.push('/researcher/comparison'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.trending_up_rounded,
                  accent: AppColors.researcherBlue,
                  title: 'researcher.anomaly_trends'.tr(),
                  onTap: () => context.push('/researcher/trends'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: accent.withValues(alpha: 0.16),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 24, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              size: 22, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
