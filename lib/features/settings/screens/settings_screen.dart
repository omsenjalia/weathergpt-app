import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../explore/providers/saved_locations_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  static const _languageNames = {
    'en': 'English',
    'hi': 'Hindi',
    'gu': 'Gujarati',
    'mr': 'Marathi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'bn': 'Bengali'
  };
  static String _persona(String value) =>
      value[0].toUpperCase() + value.substring(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final saved = ref.watch(savedLocationsProvider);
    final name = settings.displayName?.trim().isNotEmpty == true
        ? settings.displayName!
        : 'Om Jalia';
    final email = settings.email?.trim().isNotEmpty == true
        ? settings.email!
        : 'om.jalia@email.com';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Scaffold(
        appBar: AppBar(title: Text('common.settings'.tr())),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              InkWell(
                  onTap: () => _profile(context, ref, name, email),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 27,
                            backgroundColor: AppColors.textTertiary,
                            child: Text(initials,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700))),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 3),
                              Text(email,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12))
                            ])),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary)
                      ]))),
              const SizedBox(height: 12),
              _row(
                  context,
                  Icons.language_outlined,
                  'settings.language'.tr(),
                  _languageNames[settings.language] ?? settings.language,
                  () => _language(context, ref, settings.language)),
              _row(
                  context,
                  Icons.eco_outlined,
                  'settings.user_type'.tr(),
                  _persona(settings.userPersona),
                  () => _personaPicker(context, ref, settings.userPersona)),
              _row(context, Icons.location_on_outlined, 'settings.saved_locations'.tr(),
                  '${saved.length} locations', () => context.push('/saved')),
              _row(
                  context,
                  Icons.thermostat_outlined,
                  'settings.units'.tr(),
                  settings.units == TemperatureUnit.celsius
                      ? 'Celsius (°C)'
                      : 'Fahrenheit (°F)',
                  () => _units(context, ref, settings.units)),
              _row(
                  context,
                  Icons.mic_none_outlined,
                  'settings.voice_settings'.tr(),
                  settings.ttsVoiceLocale,
                  () => _voice(context, ref, settings)),
              _row(context, Icons.notifications_none_outlined, 'settings.notifications'.tr(),
                  null, () => _notifications(context, ref, settings)),
              _row(
                  context,
                  Icons.file_download_outlined,
                  'settings.data_export'.tr(),
                  null,
                  () => _static(context, 'Data & Export',
                      'Export tools for researcher weather datasets will be available here.')),
              _row(
                  context,
                  Icons.help_outline,
                  'settings.help_support'.tr(),
                  null,
                  () => _static(context, 'Help & Support',
                      'FAQ\n\nHow do I change my location? Use Explore to find a city and save it.\n\nNeed help? Contact the WeatherGPT team.')),
              _row(
                  context,
                  Icons.info_outline,
                  'settings.about'.tr(),
                  null,
                  () => _static(context, 'About WeatherGPT',
                      'WeatherGPT\nVersion 1.0.0\n\nBuilt for Smart India Hackathon 2026 — problem statement SIH26068.\n\nMade with care by the WeatherGPT team.')),
            ]));
  }

  Widget _row(BuildContext context, IconData icon, String label, String? value,
          VoidCallback tap) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
              padding: EdgeInsets.zero,
              child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                      onTap: tap,
                      leading: Icon(icon, color: AppColors.textPrimary),
                      title: Text(label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: value == null
                          ? null
                          : Text(value,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary)))));
  Future<void> _profile(
      BuildContext context, WidgetRef ref, String name, String email) async {
    final n = TextEditingController(text: name);
    final e = TextEditingController(text: email);
    await _formSheet(context, 'Edit profile', [
      TextField(
          controller: n, decoration: const InputDecoration(labelText: 'Name')),
      TextField(
          controller: e,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress)
    ], () async {
      await ref
          .read(settingsProvider.notifier)
          .updateProfile(n.text.trim(), e.text.trim());
    });
    n.dispose();
    e.dispose();
  }

  Future<void> _language(
      BuildContext context, WidgetRef ref, String selected) async {
    await _choiceSheet(
        context,
        'Choose your language',
        _languageNames.entries.map((e) => (e.key, e.value)).toList(),
        selected, (code) async {
      await ref.read(settingsProvider.notifier).updateLanguage(code);
      if (context.mounted) await context.setLocale(Locale(code));
    });
  }

  Future<void> _personaPicker(
          BuildContext context, WidgetRef ref, String selected) =>
      _choiceSheet(
          context,
          'Choose your focus',
          const [
            ('everyone', 'Everyone'),
            ('farmer', 'Farmer'),
            ('researcher', 'Researcher')
          ],
          selected,
          (value) => ref.read(settingsProvider.notifier).updatePersona(value));
  Future<void> _units(
          BuildContext context, WidgetRef ref, TemperatureUnit unit) =>
      _choiceSheet(
          context,
          'Temperature units',
          const [
            ('celsius', 'Celsius (°C)'),
            ('fahrenheit', 'Fahrenheit (°F)')
          ],
          unit.name,
          (value) => ref
              .read(settingsProvider.notifier)
              .updateUnits(TemperatureUnit.values.byName(value)));
  Future<void> _voice(
      BuildContext context, WidgetRef ref, SettingsState settings) async {
    var locale = settings.ttsVoiceLocale;
    var speed = settings.ttsSpeed;
    await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surfaceCard,
        isScrollControlled: true,
        builder: (sheet) => StatefulBuilder(
            builder: (context, setState) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('settings.voice_settings'.tr(),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          DropdownButton<String>(
                              value: locale,
                              isExpanded: true,
                              items: const ['en-US', 'hi-IN', 'gu-IN', 'ta-IN']
                                  .map((value) => DropdownMenuItem(
                                      value: value, child: Text(value)))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => locale = value!)),
                          Text('Speed ${speed.toStringAsFixed(1)}x'),
                          Slider(
                              value: speed,
                              min: .5,
                              max: 2,
                              divisions: 6,
                              onChanged: (value) =>
                                  setState(() => speed = value)),
                          FilledButton(
                              onPressed: () async {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .updateVoiceSettings(locale, speed);
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: Text('common.save'.tr()))
                        ])))));
  }

  Future<void> _notifications(
          BuildContext context, WidgetRef ref, SettingsState settings) =>
      showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surfaceCard,
          builder: (sheet) => StatefulBuilder(builder: (context, setState) {
                final prefs = ref.watch(settingsProvider).notificationsEnabled;
                return SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              'weather_alerts',
                              'imd_warnings',
                              'daily_summary'
                            ]
                                .map((key) => SwitchListTile(
                                    title: Text({
                                      'weather_alerts': 'Weather alerts',
                                      'imd_warnings': 'IMD warnings',
                                      'daily_summary': 'Daily summary'
                                    }[key]!),
                                    value: prefs[key] ?? false,
                                    onChanged: (enabled) => ref
                                        .read(settingsProvider.notifier)
                                        .updateNotificationPref(key, enabled)))
                                .toList())));
              }));
  Future<void> _choiceSheet(
          BuildContext context,
          String title,
          List<(String, String)> options,
          String selected,
          Future<void> Function(String) choose) =>
      showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surfaceCard,
          builder: (sheet) => SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ...options.map((option) => ListTile(
                        leading: Icon(
                            option.$1 == selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: option.$1 == selected
                                ? AppColors.farmerGreen
                                : AppColors.textSecondary),
                        title: Text(option.$2),
                        onTap: () async {
                          await choose(option.$1);
                          if (context.mounted) Navigator.pop(context);
                        }))
                  ]))));
  Future<void> _formSheet(BuildContext context, String title,
          List<Widget> fields, Future<void> Function() save) =>
      showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surfaceCard,
          isScrollControlled: true,
          builder: (sheet) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.viewInsetsOf(sheet).bottom + 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                ...fields,
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () async {
                      await save();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text('common.save'.tr()))
              ])));
  void _static(BuildContext context, String title, String body) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => Scaffold(
              appBar: AppBar(title: Text(title)),
              body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(body,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.6))))));
}
