/// Buttons — ports of `lib/core/widgets/primary_button.dart` and
/// `lib/core/widgets/outlined_button_pill.dart`.

import React from "react";
import { Pressable, Text, StyleSheet, ViewStyle } from "react-native";

import { AppColors } from "../appColors";
import { Radius, Spacing } from "../theme";

interface PrimaryButtonProps {
  label: string;
  onPress?: () => void;
  disabled?: boolean;
  variant?: "accent" | "white" | "danger";
  style?: ViewStyle;
}

export function PrimaryButton({ label, onPress, disabled = false, variant = "accent", style }: PrimaryButtonProps): React.ReactElement {
  const background =
    variant === "white" ? AppColors.ctaWhite : variant === "danger" ? AppColors.statusRed : AppColors.accent;
  const color = variant === "white" ? AppColors.ctaTextDark : AppColors.bgPrimary;
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.primary,
        { backgroundColor: background, opacity: disabled ? 0.45 : pressed ? 0.82 : 1 },
        style,
      ]}
    >
      <Text style={[styles.primaryLabel, { color }]}>{label}</Text>
    </Pressable>
  );
}

interface OutlinedButtonProps {
  label: string;
  onPress?: () => void;
  selected?: boolean;
  accentColor?: string;
  style?: ViewStyle;
}

export function OutlinedPillButton({ label, onPress, selected = false, accentColor = AppColors.accent, style }: OutlinedButtonProps): React.ReactElement {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.outlined,
        { borderColor: selected ? accentColor : AppColors.glassBorderStrong, backgroundColor: selected ? `${accentColor}22` : "transparent", opacity: pressed ? 0.8 : 1 },
        style,
      ]}
    >
      <Text style={[styles.outlinedLabel, { color: selected ? accentColor : AppColors.textPrimary }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  primary: {
    borderRadius: Radius.pill,
    paddingVertical: 14,
    paddingHorizontal: 24,
    alignItems: "center",
    justifyContent: "center",
  },
  primaryLabel: {
    fontSize: 15,
    fontWeight: "700",
  },
  outlined: {
    borderRadius: Radius.pill,
    borderWidth: 1,
    paddingVertical: 10,
    paddingHorizontal: 18,
    alignItems: "center",
    justifyContent: "center",
  },
  outlinedLabel: {
    fontSize: 13,
    fontWeight: "600",
  },
});

export { Spacing };
