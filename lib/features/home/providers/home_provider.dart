import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/providers/settings_provider.dart';

/// SettingsProvider is the single persisted source for the active persona.
final homePersonaProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider.select((state) => state.userPersona)),
);
