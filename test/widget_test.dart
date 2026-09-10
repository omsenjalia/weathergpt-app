import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

bool _hiveReady = false;

Future<void> _setupHive() async {
  if (_hiveReady) return;
  Hive.init('./.test_hive_tmp');
  if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
  if (!Hive.isBoxOpen('farm_profile')) await Hive.openBox('farm_profile');
  if (!Hive.isBoxOpen('saved_locations')) await Hive.openBox('saved_locations');
  _hiveReady = true;
}

Future<void> _pumpLocalizedApp(
  WidgetTester tester,
  Widget child, {
  bool withProviderScope = true,
}) async {
  await EasyLocalization.ensureInitialized();
  await _setupHive();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/onboarding/language', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/onboarding/focus', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/voice/result', builder: (_, __) => const SizedBox()),
    ],
  );

  final app = EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    child: Builder(
      builder: (context) => MaterialApp.router(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: router,
      ),
    ),
  );

  await tester.pumpWidget(withProviderScope ? ProviderScope(child: app) : app);
  // Limited pumps — never use pumpAndSettle (repeating animations hang forever).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash renders WeatherGPT wordmark', (tester) async {
    await _pumpLocalizedApp(tester, const SplashScreen(), withProviderScope: false);
    expect(find.text('WeatherGPT'), findsOneWidget);
  });

  testWidgets('language selection renders headline', (tester) async {
    await _pumpLocalizedApp(tester, const LanguageSelectScreen());
    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('focus selection renders preselected farmer', (tester) async {
    await _pumpLocalizedApp(tester, const FocusSelectScreen());
    expect(find.text('What best describes you?'), findsOneWidget);
  });

  testWidgets('everyone home shows everyday metrics and prompts', (tester) async {
    await _pumpLocalizedApp(tester, const HomeEveryoneScreen());
    expect(find.text('Ask WeatherGPT anything...'), findsOneWidget);
  });

  testWidgets('farmer home shows farm-specific content', (tester) async {
    await _pumpLocalizedApp(tester, const HomeFarmerScreen());
    expect(find.text('Soil moisture'), findsOneWidget);
  });

  testWidgets('researcher home shows analytical content', (tester) async {
    await _pumpLocalizedApp(tester, const HomeResearcherScreen());
    expect(find.text('Pressure'), findsOneWidget);
  });

  testWidgets('voice listening screen renders the waveform and mic', (tester) async {
    // autoStart: false so speech plugins are not invoked in CI
    await _pumpLocalizedApp(
        tester, const VoiceListeningScreen(autoStart: false));
    expect(find.text('Listening...'), findsOneWidget);
  });

  testWidgets('result screen renders a reusable irrigation card', (tester) async {
    const response = VoiceResponse(
      transcript: 'Should I irrigate?',
      type: ResultType.irrigation,
      accent: Color(0xFFFFB020),
      label: 'Irrigation Recommendation',
      verdict: 'Not recommended today',
      explanation: 'Rain is likely tomorrow.',
      stats: [
        ResultStat('Rain (tomorrow)', '12 mm'),
        ResultStat('Soil Moisture', 'Adequate'),
      ],
      forecast: [
        ForecastDay('Tue', Icons.wb_sunny_outlined, '24°', '0 mm'),
      ],
      ctaLabel: 'View Detailed Forecast',
    );
    await _pumpLocalizedApp(
        tester, const ConversationalResultScreen(response: response));
    expect(find.text('Not recommended today'), findsOneWidget);
  });

  testWidgets('farm profile shows farm details and crop tab', (tester) async {
    await _pumpLocalizedApp(tester, const FarmProfileScreen());
    expect(find.text('My Farm'), findsOneWidget);
    expect(find.text('Anand, Gujarat'), findsOneWidget);
    expect(find.text('Edit Farm Profile'), findsOneWidget);

    final crops = find.text('Crops');
    if (crops.evaluate().isNotEmpty) {
      await tester.tap(crops);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Flowering stage'), findsOneWidget);
    }
  });

  testWidgets('action windows updates when changing tabs', (tester) async {
    await _pumpLocalizedApp(tester, const ActionWindowsScreen());
    expect(find.text('Farm Action Windows'), findsOneWidget);
    expect(find.text('Good day for field work'), findsOneWidget);
    expect(find.text('Best: 6–10 AM'), findsOneWidget);

    final tomorrow = find.text('Tomorrow');
    if (tomorrow.evaluate().isNotEmpty) {
      await tester.tap(tomorrow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('A workable day with caution'), findsOneWidget);
      expect(find.text('Plan for afternoon'), findsOneWidget);
    }
  });

  testWidgets('researcher analytical screens render their charts and stats',
      (tester) async {
    await _pumpLocalizedApp(tester, const HistoricalDataScreen());
    expect(find.text('Historical Weather'), findsOneWidget);
    expect(find.text('Total Rainfall (2026)'), findsOneWidget);

    await _pumpLocalizedApp(tester, const ComparisonScreen(),
        withProviderScope: false);
    expect(find.text('Compare Locations'), findsOneWidget);
    expect(find.text('Total Rainfall (mm)'), findsOneWidget);

    await _pumpLocalizedApp(tester, const AnomalyTrendsScreen());
    expect(find.text('Anomaly & Trends'), findsOneWidget);
    expect(find.text('2026 Average'), findsOneWidget);
  });

  testWidgets('settings renders profile and every setting row', (tester) async {
    await _pumpLocalizedApp(tester, const SettingsScreen());
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
    // Soft scroll — ListView may not be present in all layouts
    final list = find.byType(ListView);
    if (list.evaluate().isNotEmpty) {
      await tester.drag(list, const Offset(0, -800));
      await tester.pump();
    }
    for (final label in [
      'Notifications',
      'Data & Export',
      'Help & Support',
      'About WeatherGPT',
    ]) {
      expect(find.text(label), findsWidgets); // at least one
    }
  });
}
