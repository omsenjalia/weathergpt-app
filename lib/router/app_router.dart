import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/primary_button.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final completed = Hive.box(
      'settings',
    ).get('onboarding_complete', defaultValue: false) as bool;
    if (state.matchedLocation == '/')
      return completed ? '/home' : '/onboarding/splash';
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding/splash',
      builder: (_, __) => const SplashPlaceholder(),
    ),
    ShellRoute(
      builder: (_, __, child) => NavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const PlaceholderTab(title: 'Home'),
        ),
        GoRoute(
          path: '/explore',
          builder: (_, __) => const PlaceholderTab(title: 'Explore'),
        ),
        GoRoute(
          path: '/saved',
          builder: (_, __) => const PlaceholderTab(title: 'Saved'),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const PlaceholderTab(title: 'Profile'),
        ),
      ],
    ),
  ],
);

class SplashPlaceholder extends StatelessWidget {
  const SplashPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'WeatherGPT',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text('Onboarding placeholder'),
            const Spacer(),
            PrimaryButton(
              label: 'Continue',
              onPressed: () async {
                await Hive.box('settings').put('onboarding_complete', true);
                if (context.mounted) context.go('/home');
              },
            ),
          ],
        ),
      ),
    ),
  );
}

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
    final currentIndex =
        _items
                .indexWhere((item) => item.path == location)
                .clamp(0, _items.length - 1)
            as int;
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
              final color = active
                  ? AppColors.textPrimary
                  : AppColors.textTertiary;
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
