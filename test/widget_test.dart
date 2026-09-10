import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weathergpt_mobile/features/onboarding/screens/focus_select_screen.dart';
import 'package:weathergpt_mobile/features/onboarding/screens/language_select_screen.dart';
import 'package:weathergpt_mobile/features/onboarding/screens/splash_screen.dart';
import 'package:weathergpt_mobile/features/home/screens/home_everyone_screen.dart';
import 'package:weathergpt_mobile/features/home/screens/home_farmer_screen.dart';
import 'package:weathergpt_mobile/features/home/screens/home_researcher_screen.dart';
import 'package:weathergpt_mobile/features/voice/providers/voice_provider.dart';
import 'package:weathergpt_mobile/features/voice/screens/conversational_result_screen.dart';
import 'package:weathergpt_mobile/features/voice/screens/voice_listening_screen.dart';
import 'package:weathergpt_mobile/features/farmer/screens/action_windows_screen.dart';
import 'package:weathergpt_mobile/features/farmer/screens/farm_profile_screen.dart';
import 'package:weathergpt_mobile/features/researcher/screens/anomaly_trends_screen.dart';
import 'package:weathergpt_mobile/features/researcher/screens/comparison_screen.dart';
import 'package:weathergpt_mobile/features/researcher/screens/historical_data_screen.dart';
import 'package:weathergpt_mobile/features/settings/screens/settings_screen.dart';

void main() {
  testWidgets('splash renders WeatherGPT wordmark',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );
    expect(find.text('WeatherGPT'), findsOneWidget);
  });

  testWidgets('language selection renders headline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LanguageSelectScreen()),
    ));
    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('focus selection renders preselected farmer',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: FocusSelectScreen()),
    ));
    expect(find.text('What best describes you?'), findsOneWidget);
    expect(find.text('Farmer'), findsOneWidget);
  });

  testWidgets('everyone home shows everyday metrics and prompts',
      (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeEveryoneScreen())));
    expect(find.text('Ask WeatherGPT anything...'), findsOneWidget);
    expect(find.text('Will it rain tomorrow?'), findsOneWidget);
    expect(find.text('AQI'), findsOneWidget);
  });

  testWidgets('farmer home shows farm-specific content', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeFarmerScreen())));
    expect(find.text('Soil moisture'), findsOneWidget);
    expect(find.text('How is my wheat crop doing?'), findsOneWidget);
  });

  testWidgets('researcher home shows analytical content', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeResearcherScreen())));
    expect(find.text('Pressure'), findsOneWidget);
    expect(find.text('Find extreme weather events'), findsOneWidget);
    expect(find.text('Ask something else...'), findsOneWidget);
  });

  testWidgets('voice listening screen renders the waveform and mic',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: VoiceListeningScreen(autoStart: false)),
    ));
    expect(find.text('Listening...'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('result screen renders a reusable irrigation card',
      (tester) async {
    const response = VoiceResponse(
      transcript: 'Should I irrigate today?',
      type: ResultType.irrigation,
      accent: Color(0xFFFBBF24),
      label: 'Irrigation Recommendation',
      verdict: 'Not recommended today',
      explanation: 'Rain is likely tomorrow.',
      stats: [ResultStat('Rain', '12 mm'), ResultStat('Moisture', 'Adequate')],
      forecast: [ForecastDay('Tue', Icons.wb_sunny_outlined, '24°', '0 mm')],
      ctaLabel: 'View Detailed Forecast',
    );
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: ConversationalResultScreen(response: response)),
    ));
    expect(find.text('Not recommended today'), findsOneWidget);
    expect(find.text('Next 3 Days'), findsOneWidget);
  });

  testWidgets('farm profile shows farm details and crop tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: FarmProfileScreen()),
    ));
    expect(find.text('My Farm'), findsOneWidget);
    expect(find.text('Anand, Gujarat'), findsOneWidget);
    expect(find.text('Edit Farm Profile'), findsOneWidget);

    await tester.tap(find.text('Crops'));
    await tester.pumpAndSettle();
    expect(find.text('Flowering stage'), findsOneWidget);
  });

  testWidgets('action windows updates when changing tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: ActionWindowsScreen()),
    ));
    expect(find.text('Farm Action Windows'), findsOneWidget);
    expect(find.text('Good day for field work'), findsOneWidget);
    expect(find.text('Best: 6–10 AM'), findsOneWidget);

    await tester.tap(find.text('Tomorrow'));
    await tester.pump();
    expect(find.text('A workable day with caution'), findsOneWidget);
    expect(find.text('Plan for afternoon'), findsOneWidget);
  });

  testWidgets('researcher analytical screens render their charts and stats',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: HistoricalDataScreen()),
    ));
    expect(find.text('Historical Weather'), findsOneWidget);
    expect(find.text('Total Rainfall (2026)'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: ComparisonScreen()));
    expect(find.text('Compare Locations'), findsOneWidget);
    expect(find.text('Total Rainfall (mm)'), findsOneWidget);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: AnomalyTrendsScreen()),
    ));
    expect(find.text('Anomaly & Trends'), findsOneWidget);
    expect(find.text('2026 Average'), findsOneWidget);
  });

  testWidgets('settings renders profile and every setting row', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: SettingsScreen()),
    ));
    expect(find.text('Om Jalia'), findsOneWidget);
    for (final label in [
      'Language',
      'User Type',
      'Saved Locations',
      'Units',
      'Voice Settings',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    for (final label in [
      'Notifications',
      'Data & Export',
      'Help & Support',
      'About WeatherGPT',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
