import 'package:flutter/material.dart';
import 'weather_home_screen.dart';

class HomeResearcherScreen extends StatelessWidget {
  const HomeResearcherScreen({super.key, this.locationName = ''});
  final String locationName;
  @override
  Widget build(BuildContext context) => const WeatherHomeScreen();
}
