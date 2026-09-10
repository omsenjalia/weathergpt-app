import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final done = Hive.isBoxOpen('settings') &&
        (Hive.box('settings').get('onboarding_complete', defaultValue: false)
            as bool);
    _timer = Timer(Duration(seconds: done ? 0 : 2), () {
      if (mounted) context.go(done ? '/home' : '/onboarding/language');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            const Positioned(
              left: -100,
              right: -100,
              top: 480,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0x26FFFFFF), Color(0x00000000)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    const Icon(Icons.eco_outlined,
                        color: AppColors.farmerGreen, size: 48),
                    const SizedBox(height: 14),
                    Text('common.weather_gpt'.tr(),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                )),
                    const SizedBox(height: 8),
                    Text('onboarding.splash_tagline'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const Spacer(flex: 3),
                    const SizedBox(
                      width: 76,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.textPrimary,
                        backgroundColor: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(flex: 3),
                    Text('onboarding.splash_footer'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
