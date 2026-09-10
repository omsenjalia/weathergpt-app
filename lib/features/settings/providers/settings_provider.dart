import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/api_client.dart';

enum TemperatureUnit { celsius, fahrenheit }

class SettingsState {
  const SettingsState({
    this.displayName,
    this.email,
    this.language = 'en',
    this.userPersona = 'everyone',
    this.units = TemperatureUnit.celsius,
    this.ttsVoiceLocale = 'en-US',
    this.ttsSpeed = 1.0,
    this.notificationsEnabled = const {
      'weather_alerts': true,
      'imd_warnings': true,
      'daily_summary': false,
    },
  });

  final String? displayName;
  final String? email;
  final String language;
  final String userPersona;
  final TemperatureUnit units;
  final String ttsVoiceLocale;
  final double ttsSpeed;
  final Map<String, bool> notificationsEnabled;

  SettingsState copyWith(
          {String? displayName,
          String? email,
          String? language,
          String? userPersona,
          TemperatureUnit? units,
          String? ttsVoiceLocale,
          double? ttsSpeed,
          Map<String, bool>? notificationsEnabled}) =>
      SettingsState(
          displayName: displayName ?? this.displayName,
          email: email ?? this.email,
          language: language ?? this.language,
          userPersona: userPersona ?? this.userPersona,
          units: units ?? this.units,
          ttsVoiceLocale: ttsVoiceLocale ?? this.ttsVoiceLocale,
          ttsSpeed: ttsSpeed ?? this.ttsSpeed,
          notificationsEnabled:
              notificationsEnabled ?? this.notificationsEnabled);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(_load());

  static SettingsState _load() {
    if (!Hive.isBoxOpen('settings')) return const SettingsState();
    final box = Hive.box('settings');
    final rawNotifications = box.get('notifications_enabled');
    final notifications = rawNotifications is Map
        ? rawNotifications.map((key, value) => MapEntry('$key', value == true))
        : const <String, bool>{
            'weather_alerts': true,
            'imd_warnings': true,
            'daily_summary': false
          };
    return SettingsState(
      displayName: box.get('display_name') as String?,
      email: box.get('email') as String?,
      language: box.get('language', defaultValue: 'en') as String,
      userPersona: box.get('user_persona', defaultValue: 'everyone') as String,
      units:
          box.get('temperature_unit', defaultValue: 'celsius') == 'fahrenheit'
              ? TemperatureUnit.fahrenheit
              : TemperatureUnit.celsius,
      ttsVoiceLocale:
          box.get('tts_voice_locale', defaultValue: 'en-US') as String,
      ttsSpeed: (box.get('tts_speed', defaultValue: 1.0) as num).toDouble(),
      notificationsEnabled: notifications,
    );
  }

  Future<Box<dynamic>> get _box => Hive.openBox<dynamic>('settings');
  Future<void> updateProfile(String name, String email) async {
    state = state.copyWith(displayName: name, email: email);
    final box = await _box;
    await box.put('display_name', name);
    await box.put('email', email);
  }

  Future<void> updateLanguage(String code) async {
    state = state.copyWith(language: code);
    ApiClient.instance.setLanguage(code);
    await (await _box).put('language', code);
  }

  Future<void> updatePersona(String persona) async {
    state = state.copyWith(userPersona: persona);
    await (await _box).put('user_persona', persona);
  }

  Future<void> updateUnits(TemperatureUnit unit) async {
    state = state.copyWith(units: unit);
    await (await _box).put('temperature_unit', unit.name);
  }

  Future<void> updateVoiceSettings(String locale, double speed) async {
    state = state.copyWith(ttsVoiceLocale: locale, ttsSpeed: speed);
    final box = await _box;
    await box.put('tts_voice_locale', locale);
    await box.put('tts_speed', speed);
  }

  Future<void> updateNotificationPref(String key, bool enabled) async {
    final prefs = {...state.notificationsEnabled, key: enabled};
    state = state.copyWith(notificationsEnabled: prefs);
    await (await _box).put('notifications_enabled', prefs);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
    (ref) => SettingsNotifier());
