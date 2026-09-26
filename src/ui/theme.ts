/// Shared UI primitives — port of `lib/core/theme/text_styles.dart` and the
/// spacing conventions used across the Flutter app.

import { StyleSheet, TextStyle, Platform } from "react-native";
import { AppColors } from "./appColors";

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 28,
} as const;

export const Radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 22,
  pill: 999,
} as const;

export const TextStyles = StyleSheet.create({
  heroTemp: {
    fontSize: 88,
    fontWeight: "300",
    color: AppColors.textPrimary,
    letterSpacing: -2,
  } as TextStyle,
  title: {
    fontSize: 22,
    fontWeight: "700",
    color: AppColors.textPrimary,
  } as TextStyle,
  subtitle: {
    fontSize: 15,
    fontWeight: "600",
    color: AppColors.textPrimary,
  } as TextStyle,
  body: {
    fontSize: 14,
    color: AppColors.textSecondary,
  } as TextStyle,
  small: {
    fontSize: 12,
    color: AppColors.textSecondary,
  } as TextStyle,
  tiny: {
    fontSize: 10.5,
    color: AppColors.textTertiary,
    letterSpacing: 0.3,
  } as TextStyle,
  label: {
    fontSize: 11,
    fontWeight: "700",
    letterSpacing: 1.1,
    color: AppColors.textTertiary,
  } as TextStyle,
});

/// System font stack approximating Inter/Poppins from google_fonts.
export const baseFont = Platform.select({
  web: "'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif",
  default: undefined,
});
