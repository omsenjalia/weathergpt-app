import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/theme/app_colors.dart';
import '../features/home/screens/home_router_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/explore/screens/saved_locations_screen.dart';
import '../features/onboarding/screens/focus_select_screen.dart';
import '../features/onboarding/screens/language_select_screen.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/voice/providers/voice_provider.dart';
import '../features/voice/screens/conversational_result_screen.dart';
import '../features/voice/screens/voice_listening_screen.dart';
import '../features/farmer/screens/action_windows_screen.dart';
import '../features/farmer/screens/farm_profile_screen.dart';
import '../features/researcher/screens/anomaly_trends_screen.dart';
import '../features/researcher/screens/comparison_screen.dart';
import '../features/researcher/screens/historical_data_screen.dart';
import '../features/researcher/providers/anomaly_trends_provider.dart';
import '../features/settings/screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final completed = Hive.box(
      'settings',
    ).get('onboarding_complete', defaultValue: false) as bool;
    if (state.matchedLocation == '/') {
      return completed ? '/home' : '/onboarding/splash';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding/language',
      builder: (_, __) => const LanguageSelectScreen(),
    ),
    GoRoute(
      path: '/onboarding/focus',
      builder: (_, __) => const FocusSelectScreen(),
    ),
    GoRoute(
      path: '/voice/listening',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return VoiceListeningScreen(
          prompt: extra?['prompt'] as String?,
          accent: extra?['accent'] as Color? ?? AppColors.farmerGreen,
        );
      },
    ),
    GoRoute(
      path: '/voice/result',
      builder: (_, state) => ConversationalResultScreen(
        response: state.extra! as VoiceResponse,
      ),
    ),
    GoRoute(
      path: '/farmer/farm-profile',
      builder: (_, __) => const FarmProfileScreen(),
    ),
    GoRoute(
      path: '/farmer/action-windows',
      builder: (_, __) => const ActionWindowsScreen(),
    ),
    GoRoute(
        path: '/researcher/historical',
        builder: (_, __) => const HistoricalDataScreen()),
    GoRoute(
        path: '/researcher/comparison',
        builder: (_, __) => const ComparisonScreen()),
    GoRoute(
      path: '/researcher/trends',
      builder: (_, state) => ProviderScope(
        overrides: state.uri.queryParameters['metric'] == 'rainfall'
            ? [
                anomalyTrendsProvider.overrideWith(
                    (ref) => TrendNotifier(initial: TrendMetric.rainfall))
              ]
            : const [],
        child: const AnomalyTrendsScreen(),
      ),
    ),
    ShellRoute(
      builder: (_, __, child) => NavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, state) => HomeRouterScreen(
            locationName:
                state.uri.queryParameters['location'] ?? 'Ahmedabad, Gujarat',
          ),
        ),
        GoRoute(
          path: '/explore',
          builder: (_, __) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/saved',
          builder: (_, __) => const SavedLocationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
      );
}

class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key, required this.child});
  final Widget child;

  static const _items = [
    (path: '/home', icon: Icons.home_outlined, label: 'Home'),
    (path: '/explore', icon: Icons.search, label: 'Explore'),
    (path: '/saved', icon: Icons.bookmark_outline, label: 'Saved'),
    (path: '/profile', icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _items
        .indexWhere((item) => item.path == location)
        .clamp(0, _items.length - 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => context.go(_items[index].path),
            backgroundColor: AppColors.surfaceCard,
            indicatorColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: _items.map((item) {
              final active = _items.indexOf(item) == currentIndex;
              final color =
                  active ? AppColors.textPrimary : AppColors.textTertiary;
              return NavigationDestination(
                icon: Icon(item.icon, color: color),
                selectedIcon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: color),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                label: item.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
