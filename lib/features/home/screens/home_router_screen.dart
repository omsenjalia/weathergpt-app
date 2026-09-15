import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'weather_home_screen.dart';

/// Persona-specific homes collapsed into the unified web-like weather home.
class HomeRouterScreen extends ConsumerWidget {
  const HomeRouterScreen({super.key, this.locationName = 'Ahmedabad, Gujarat'});
  final String locationName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WeatherHomeScreen();
  }
}
