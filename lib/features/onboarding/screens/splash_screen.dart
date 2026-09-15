import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final done = Hive.box('settings')
          .get('onboarding_complete', defaultValue: false) as bool;
      context.go(done ? '/home' : '/onboarding/language');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(Icons.cloud_outlined,
                    size: 36, color: AppColors.statusAmber),
              ),
              const SizedBox(height: 20),
              Text(
                'common.weather_gpt'.tr(),
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'your weather, always clear.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: AppColors.textPrimary,
                  backgroundColor: AppColors.borderSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
