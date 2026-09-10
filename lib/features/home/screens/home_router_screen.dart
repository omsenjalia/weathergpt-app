import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_provider.dart';
import 'home_everyone_screen.dart';
import 'home_farmer_screen.dart';
import 'home_researcher_screen.dart';

class HomeRouterScreen extends ConsumerWidget {
  const HomeRouterScreen({super.key, this.locationName = 'Ahmedabad, Gujarat'});
  final String locationName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(homePersonaProvider);
    return switch (persona) {
      'farmer' => HomeFarmerScreen(locationName: locationName),
      'researcher' => HomeResearcherScreen(locationName: locationName),
      _ => HomeEveryoneScreen(locationName: locationName),
    };
  }
}
