import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'text_styles.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surfaceCard,
      primary: AppColors.farmerGreen,
      onPrimary: AppColors.ctaTextDark,
    ),
    textTheme: AppTextStyles.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}
