import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/explore/providers/map_provider.dart';

/// Floating pill navigation bar shared by all main app routes.
class NavigationShell extends ConsumerWidget {
  const NavigationShell({super.key, required this.child});
  final Widget child;

  static const _items = [
    (path: '/home', icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home'),
    (path: '/chat', icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Chat'),
    (path: '/explore', icon: Icons.public_outlined, activeIcon: Icons.public, label: 'Map'),
    (path: '/profile', icon: Icons.tune_rounded, activeIcon: Icons.tune_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    var currentIndex = 0;
    for (var i = 0; i < _items.length; i++) {
      final path = _items[i].path;
      if (location == path || location.startsWith('$path/')) {
        currentIndex = i;
        break;
      }
    }
    // Weather Lab has its own timeline/controls — hide app nav to avoid overlap.
    final hideNav = location.startsWith('/explore') &&
        ref.watch(mapProvider).source == MapSource.weatherLab;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: child,
      extendBody: true,
      bottomNavigationBar: hideNav
          ? null
          : SafeArea(
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
