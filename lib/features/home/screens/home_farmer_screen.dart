import 'package:flutter/material.dart';
import 'weather_home_screen.dart';

class HomeFarmerScreen extends StatelessWidget {
  const HomeFarmerScreen({super.key, this.locationName = ''});
  final String locationName;
  @override
  Widget build(BuildContext context) => const WeatherHomeScreen();
}
