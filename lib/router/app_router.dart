import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/theme/app_colors.dart';
import '../features/home/screens/weather_home_screen.dart';
import '../features/chat/screens/chat_screen.dart';
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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
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
      parentNavigatorKey: rootNavigatorKey,
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
      parentNavigatorKey: rootNavigatorKey,
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
          builder: (_, __) => const WeatherHomeScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (_, state) {
            final extra = state.extra;
            final prompt = extra is String ? extra : null;
            return ChatScreen(initialPrompt: prompt);
          },
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
    (path: '/home', icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home'),
    (path: '/chat', icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Chat'),
    (path: '/explore', icon: Icons.public_outlined, activeIcon: Icons.public, label: 'Map'),
    (path: '/profile', icon: Icons.tune_rounded, activeIcon: Icons.tune_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    var currentIndex = 0;
    for (var i = 0; i < _items.length; i++) {
      final path = _items[i].path;
      if (location == path || location.startsWith('$path/')) {
        currentIndex = i;
        break;
      }
    }
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: child,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.bgElevated.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.go(item.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        size: 22,
                        color: active ? AppColors.accent : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? AppColors.accent : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
