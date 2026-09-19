import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../providers/developer_options_provider.dart';
import '../../home/theme/atmosphere_theme.dart';

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
    final n = ref.read(settingsProvider.notifier);
    final dev = ref.watch(developerOptionsProvider);
    final devN = ref.read(developerOptionsProvider.notifier);
    final bottom = MediaQuery.paddingOf(context).bottom + 80;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
          children: [
            const Text('Settings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Language, voice, and experience',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            _section('Language'),
            _card(
              // RadioGroup owns the group value in current Flutter releases;
              // per-tile groupValue/onChanged are deprecated.
              child: RadioGroup<String>(
                groupValue: settings.language,
                onChanged: (v) async {
                  if (v == null) return;
                  await n.updateLanguage(v);
                  await n.updateTtsVoiceLocale(_ttsLocales[v] ?? 'en-US');
                  if (context.mounted) await context.setLocale(Locale(v));
                },
                child: Column(
                  children: [
                    for (final (code, label) in _languages)
                      RadioListTile<String>(
                        value: code,
                        activeColor: AppColors.accent,
                        title: Text(label),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _section('Experience'),
            _card(
              child: RadioGroup<String>(
                groupValue: settings.userPersona,
                onChanged: (v) {
                  if (v != null) n.updatePersona(v);
                },
                child: Column(
                  children: [
                    for (final (id, key) in [
                      ('everyone', 'persona.everyone'),
                      ('farmer', 'persona.farmer'),
                      ('researcher', 'persona.researcher'),
                    ])
                      RadioListTile<String>(
                        value: id,
                        activeColor: AppColors.accent,
                        title: Text(key.tr()),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _section('Voice'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Speech speed'),
                    subtitle: Text(
                      settings.ttsSpeed < 0.7
                          ? 'Slow'
                          : settings.ttsSpeed > 1.0
                              ? 'Fast'
                              : 'Normal',
                    ),
                  ),
                  Slider(
                    value: settings.ttsSpeed.clamp(0.4, 1.2),
                    min: 0.4,
                    max: 1.2,
                    activeColor: AppColors.accent,
                    onChanged: n.updateTtsSpeed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _section('Tools'),
            _card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.map_outlined, color: AppColors.sky),
                    title: const Text('Weather map'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/explore'),
                  ),
                  if (settings.userPersona == 'researcher') ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.insights_outlined,
                          color: AppColors.researcherBlue),
                      title: const Text('Historical data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/researcher/historical'),
                    ),
                  ],
                  if (settings.userPersona == 'farmer') ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.agriculture_outlined,
                          color: AppColors.farmerGreen),
                      title: const Text('Farm profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/farmer/farm-profile'),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            _section('Developer'),
            _card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable developer options'),
                    subtitle: const Text('Override sky, weather, TTS for testing'),
                    value: dev.enabled,
                    activeThumbColor: AppColors.accent,
                    onChanged: devN.setEnabled,
                  ),
                  if (dev.enabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Force time of day'),
                      subtitle: Text(dev.forcePeriod?.name ?? 'Auto (device time)'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: DropdownButtonFormField<String>(
                        initialValue: dev.forcePeriod?.name ?? 'auto',
                        items: [
                          const DropdownMenuItem(value: 'auto', child: Text('Auto')),
                          ...SkyPeriod.values.map(
                            (e) => DropdownMenuItem(value: e.name, child: Text(e.name)),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null || v == 'auto') {
                            devN.setForcePeriod(null);
                          } else {
                            devN.setForcePeriod(SkyPeriod.values.byName(v));
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Force weather condition'),
                      subtitle: Text(dev.forceSky?.name ?? 'Auto (live weather)'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: DropdownButtonFormField<String>(
                        initialValue: dev.forceSky?.name ?? 'auto',
                        items: [
                          const DropdownMenuItem(value: 'auto', child: Text('Auto')),
                          ...SkyCondition.values.map(
                            (e) => DropdownMenuItem(value: e.name, child: Text(e.name)),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null || v == 'auto') {
                            devN.setForceSky(null);
                          } else {
                            devN.setForceSky(SkyCondition.values.byName(v));
                          }
                        },
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Disable video sky'),
                      subtitle: const Text('Use gradient only'),
                      value: dev.disableVideoSky,
                      activeThumbColor: AppColors.accent,
                      onChanged: devN.setDisableVideoSky,
                    ),
                    ListTile(
                      title: const Text('TTS locale override'),
                      subtitle: Text(dev.forceTtsLocale ?? settings.ttsVoiceLocale),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: DropdownButtonFormField<String>(
                        initialValue: dev.forceTtsLocale ?? 'default',
                        items: const [
                          DropdownMenuItem(value: 'default', child: Text('Use app setting')),
                          DropdownMenuItem(value: 'en-US', child: Text('en-US')),
                          DropdownMenuItem(value: 'en-IN', child: Text('en-IN')),
                          DropdownMenuItem(value: 'hi-IN', child: Text('hi-IN')),
                          DropdownMenuItem(value: 'gu-IN', child: Text('gu-IN')),
                          DropdownMenuItem(value: 'mr-IN', child: Text('mr-IN')),
                          DropdownMenuItem(value: 'ta-IN', child: Text('ta-IN')),
                          DropdownMenuItem(value: 'te-IN', child: Text('te-IN')),
                          DropdownMenuItem(value: 'bn-IN', child: Text('bn-IN')),
                        ],
                        onChanged: (v) {
                          if (v == null || v == 'default') {
                            devN.setForceTtsLocale(null);
                          } else {
                            devN.setForceTtsLocale(v);
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('TTS speed override'),
                      subtitle: Text(
                        dev.forceTtsSpeed == null
                            ? 'Use app setting (${settings.ttsSpeed.toStringAsFixed(2)})'
                            : dev.forceTtsSpeed!.toStringAsFixed(2),
                      ),
                    ),
                    Slider(
                      value: (dev.forceTtsSpeed ?? settings.ttsSpeed).clamp(0.4, 1.2),
                      min: 0.4,
                      max: 1.2,
                      activeColor: AppColors.accent,
                      onChanged: (v) => devN.setForceTtsSpeed(v),
                    ),
                    TextButton(
                      onPressed: () => devN.reset(),
                      child: const Text('Reset developer overrides'),
                    ),
                  ],
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          t.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}
