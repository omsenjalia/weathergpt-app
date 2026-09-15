import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _languages = [
    ('en', 'English'),
    ('hi', 'हिंदी'),
    ('gu', 'ગુજરાતી'),
    ('mr', 'मराठी'),
    ('ta', 'தமிழ்'),
    ('te', 'తెలుగు'),
    ('kn', 'ಕನ್ನಡ'),
    ('ml', 'മലയാളം'),
    ('bn', 'বাংলা'),
  ];

  static const _ttsLocales = {
    'en': 'en-US',
    'hi': 'hi-IN',
    'gu': 'gu-IN',
    'mr': 'mr-IN',
    'ta': 'ta-IN',
    'te': 'te-IN',
    'kn': 'kn-IN',
    'ml': 'ml-IN',
    'bn': 'bn-IN',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        backgroundColor: AppColors.bgPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle('settings.section_language'.tr()),
          _Card(
            child: Column(
              children: [
                for (final (code, label) in _languages)
                  RadioListTile<String>(
                    value: code,
                    groupValue: settings.language,
                    title: Text(label),
                    activeColor: AppColors.statusAmber,
                    onChanged: (v) async {
                      if (v == null) return;
                      await notifier.updateLanguage(v);
                      await notifier.updateTtsVoiceLocale(_ttsLocales[v] ?? 'en-US');
                      if (context.mounted) {
                        await context.setLocale(Locale(v));
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('settings.section_persona'.tr()),
          _Card(
            child: Column(
              children: [
                for (final (id, key) in [
                  ('everyone', 'persona.everyone'),
                  ('farmer', 'persona.farmer'),
                  ('researcher', 'persona.researcher'),
                ])
                  RadioListTile<String>(
                    value: id,
                    groupValue: settings.userPersona,
                    title: Text(key.tr()),
                    activeColor: AppColors.statusAmber,
                    onChanged: (v) {
                      if (v != null) notifier.updatePersona(v);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('settings.section_units'.tr()),
          _Card(
            child: SwitchListTile(
              title: Text('settings.use_fahrenheit'.tr()),
              value: settings.units == TemperatureUnit.fahrenheit,
              activeColor: AppColors.statusAmber,
              onChanged: (v) => notifier.updateUnits(
                v ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('settings.section_voice'.tr()),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text('settings.tts_speed'.tr()),
                  subtitle: Text(
                    settings.ttsSpeed < 0.7
                        ? 'settings.speed_slow'.tr()
                        : settings.ttsSpeed > 1.0
                            ? 'settings.speed_fast'.tr()
                            : 'settings.speed_normal'.tr(),
                  ),
                ),
                Slider(
                  value: settings.ttsSpeed.clamp(0.4, 1.2),
                  min: 0.4,
                  max: 1.2,
                  divisions: 8,
                  label: settings.ttsSpeed.toStringAsFixed(2),
                  activeColor: AppColors.statusAmber,
                  onChanged: (v) => notifier.updateTtsSpeed(v),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('settings.section_data'.tr()),
          _Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text('settings.saved_locations'.tr()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/saved'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text('settings.open_map'.tr()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/explore'),
                ),
                if (settings.userPersona == 'farmer') ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.agriculture_outlined),
                    title: Text('settings.farm_profile'.tr()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/farmer/farm-profile'),
                  ),
                ],
                if (settings.userPersona == 'researcher') ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: Text('settings.historical'.tr()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/researcher/historical'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.compare_arrows),
                    title: Text('settings.comparison'.tr()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/researcher/comparison'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'settings.footer'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}
