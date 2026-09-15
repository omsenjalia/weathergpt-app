import 'package:flutter/material.dart';
import 'weather_home_screen.dart';

class HomeEveryoneScreen extends StatelessWidget {
  const HomeEveryoneScreen({super.key, this.locationName = ''});
  final String locationName;
  @override
  Widget build(BuildContext context) => const WeatherHomeScreen();
}
