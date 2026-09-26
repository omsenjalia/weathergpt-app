/// Chips — ports of `lib/core/widgets/metric_chip.dart` and
/// `lib/core/widgets/persona_badge.dart`.

import React from "react";
import { View, Text, StyleSheet } from "react-native";

import { AppColors } from "../appColors";
import { Radius, Spacing } from "../theme";

interface MetricChipProps {
  icon: string;
  value: string;
  label: string;
}

export function MetricChip({ icon, value, label }: MetricChipProps): React.ReactElement {
  return (
    <View style={styles.chip}>
      <Text style={styles.icon}>{icon}</Text>
      <View style={{ flex: 1 }}>
        <Text style={styles.value} numberOfLines={1}>
          {value}
        </Text>
        <Text style={styles.label}>{label}</Text>
      </View>
    </View>
  );
}

interface PersonaBadgeProps {
  persona: "everyone" | "farmer" | "researcher";
  label: string;
}

const PERSONA_COLORS = {
  everyone: AppColors.accent,
  farmer: AppColors.farmerGreen,
  researcher: AppColors.researcherBlue,
} as const;

export function PersonaBadge({ persona, label }: PersonaBadgeProps): React.ReactElement {
  const color = PERSONA_COLORS[persona];
  return (
    <View style={[styles.badge, { borderColor: color, backgroundColor: `${color}1A` }]}>
      <Text style={[styles.badgeLabel, { color }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  chip: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
    backgroundColor: AppColors.glassFill,
    borderColor: AppColors.glassBorder,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm + 2,
    flex: 1,
  },
  icon: {
    fontSize: 18,
  },
  value: {
    fontSize: 14,
    fontWeight: "700",
    color: AppColors.textPrimary,
  },
  label: {
    fontSize: 11,
    color: AppColors.textTertiary,
  },
  badge: {
    borderRadius: Radius.pill,
    borderWidth: 1,
    paddingHorizontal: Spacing.md,
    paddingVertical: 3,
    alignSelf: "flex-start",
  },
  badgeLabel: {
    fontSize: 11,
    fontWeight: "700",
    letterSpacing: 0.4,
  },
});
