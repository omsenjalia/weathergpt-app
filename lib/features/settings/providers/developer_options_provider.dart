import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../home/theme/atmosphere_theme.dart';

class DeveloperOptions {
  const DeveloperOptions({
    this.enabled = false,
    this.forcePeriod,
    this.forceSky,
    this.forceTtsLocale,
    this.forceTtsSpeed,
    this.disableVideoSky = false,
  });

  final bool enabled;
  final SkyPeriod? forcePeriod;
  final SkyCondition? forceSky;
  final String? forceTtsLocale;
  final double? forceTtsSpeed;
  final bool disableVideoSky;

  DeveloperOptions copyWith({
    bool? enabled,
    SkyPeriod? forcePeriod,
    SkyCondition? forceSky,
    String? forceTtsLocale,
    double? forceTtsSpeed,
    bool? disableVideoSky,
    bool clearPeriod = false,
    bool clearSky = false,
    bool clearTtsLocale = false,
    bool clearTtsSpeed = false,
  }) =>
      DeveloperOptions(
        enabled: enabled ?? this.enabled,
        forcePeriod: clearPeriod ? null : (forcePeriod ?? this.forcePeriod),
        forceSky: clearSky ? null : (forceSky ?? this.forceSky),
        forceTtsLocale:
            clearTtsLocale ? null : (forceTtsLocale ?? this.forceTtsLocale),
        forceTtsSpeed:
            clearTtsSpeed ? null : (forceTtsSpeed ?? this.forceTtsSpeed),
        disableVideoSky: disableVideoSky ?? this.disableVideoSky,
      );
}

class DeveloperOptionsNotifier extends StateNotifier<DeveloperOptions> {
  DeveloperOptionsNotifier() : super(_load());

  static const _boxName = 'settings';

  static DeveloperOptions _load() {
    if (!Hive.isBoxOpen(_boxName)) return const DeveloperOptions();
    final box = Hive.box(_boxName);
    final enabled = box.get('dev_enabled', defaultValue: false) == true;
    final periodName = box.get('dev_force_period') as String?;
    final skyName = box.get('dev_force_sky') as String?;
    SkyPeriod? period;
    SkyCondition? sky;
    if (periodName != null) {
      try {
        period = SkyPeriod.values.byName(periodName);
      } catch (_) {}
    }
    if (skyName != null) {
      try {
        sky = SkyCondition.values.byName(skyName);
      } catch (_) {}
    }
    return DeveloperOptions(
      enabled: enabled,
      forcePeriod: period,
      forceSky: sky,
      forceTtsLocale: box.get('dev_tts_locale') as String?,
      forceTtsSpeed: (box.get('dev_tts_speed') as num?)?.toDouble(),
      disableVideoSky: box.get('dev_disable_video_sky') == true,
    );
  }

  Future<void> _persist() async {
    final box = await Hive.openBox(_boxName);
    await box.put('dev_enabled', state.enabled);
    await box.put('dev_force_period', state.forcePeriod?.name);
    await box.put('dev_force_sky', state.forceSky?.name);
    await box.put('dev_tts_locale', state.forceTtsLocale);
    await box.put('dev_tts_speed', state.forceTtsSpeed);
    await box.put('dev_disable_video_sky', state.disableVideoSky);
  }

  Future<void> setEnabled(bool v) async {
    state = state.copyWith(enabled: v);
    await _persist();
  }

  Future<void> setForcePeriod(SkyPeriod? p) async {
    state = p == null
        ? state.copyWith(clearPeriod: true)
        : state.copyWith(forcePeriod: p);
    await _persist();
  }

  Future<void> setForceSky(SkyCondition? s) async {
    state = s == null
        ? state.copyWith(clearSky: true)
        : state.copyWith(forceSky: s);
    await _persist();
  }

  Future<void> setForceTtsLocale(String? locale) async {
    state = locale == null
        ? state.copyWith(clearTtsLocale: true)
        : state.copyWith(forceTtsLocale: locale);
    await _persist();
  }

  Future<void> setForceTtsSpeed(double? speed) async {
    state = speed == null
        ? state.copyWith(clearTtsSpeed: true)
        : state.copyWith(forceTtsSpeed: speed);
    await _persist();
  }

  Future<void> setDisableVideoSky(bool v) async {
    state = state.copyWith(disableVideoSky: v);
    await _persist();
  }

  Future<void> reset() async {
    state = const DeveloperOptions();
    await _persist();
  }
}

final developerOptionsProvider =
    StateNotifierProvider<DeveloperOptionsNotifier, DeveloperOptions>(
  (ref) => DeveloperOptionsNotifier(),
);
