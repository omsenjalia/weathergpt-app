import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weathergpt_mobile/features/onboarding/screens/splash_screen.dart';
import 'package:weathergpt_mobile/features/onboarding/screens/language_select_screen.dart';
import 'package:weathergpt_mobile/features/onboarding/screens/focus_select_screen.dart';
import 'package:weathergpt_mobile/features/home/screens/home_everyone_screen.dart';
import 'package:weathergpt_mobile/features/home/screens/home_farmer_screen.dart';
import 'package:weathergpt_mobile/features/home/screens/home_researcher_screen.dart';
import 'package:weathergpt_mobile/features/settings/screens/settings_screen.dart';
import 'package:weathergpt_mobile/features/farmer/screens/farm_profile_screen.dart';
import 'package:weathergpt_mobile/features/farmer/screens/action_windows_screen.dart';
import 'package:weathergpt_mobile/features/researcher/screens/historical_data_screen.dart';
import 'package:weathergpt_mobile/features/researcher/screens/comparison_screen.dart';
import 'package:weathergpt_mobile/features/researcher/screens/anomaly_trends_screen.dart';

/// Minimal harness that does not start Hive, GoRouter, or plugin side-effects.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: ProviderScope(
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: child,
          ),
        ),
      ),
    ),
  );
  // Exactly two frames — enough for build, never wait for animations.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash builds', (tester) async {
    await _pump(tester, const SplashScreen());
    expect(find.byType(Scaffold), findsOneWidget);
    // Key or translated text
    expect(find.textContaining('Weather'), findsWidgets);
  });

  testWidgets('language select builds', (tester) async {
    await _pump(tester, const LanguageSelectScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('focus select builds', (tester) async {
    await _pump(tester, const FocusSelectScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('home everyone builds', (tester) async {
    await _pump(tester, const HomeEveryoneScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('home farmer builds', (tester) async {
    await _pump(tester, const HomeFarmerScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('home researcher builds', (tester) async {
    await _pump(tester, const HomeResearcherScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('settings builds', (tester) async {
    await _pump(tester, const SettingsScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('farm profile builds', (tester) async {
    await _pump(tester, const FarmProfileScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('action windows builds', (tester) async {
    await _pump(tester, const ActionWindowsScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('historical data builds', (tester) async {
    await _pump(tester, const HistoricalDataScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('comparison builds', (tester) async {
    await _pump(tester, const ComparisonScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('anomaly trends builds', (tester) async {
    await _pump(tester, const AnomalyTrendsScreen());
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
