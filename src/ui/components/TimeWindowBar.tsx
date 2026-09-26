/// 12-bucket time window bars — port of
/// `lib/features/farmer/widgets/time_window_bar.dart`. Renders a suitability
/// track (irrigation / spraying / field work) as colored segments.

import React from "react";
import { View, Text, StyleSheet } from "react-native";

import { HourlySuitability, Suitability } from "../../features/farm/models/advisoryModels";
import { AppColors } from "../appColors";
import { Radius, Spacing } from "../theme";

const BAND_COLORS: Record<Suitability, string> = {
  [Suitability.Good]: AppColors.statusGreenText,
  [Suitability.Caution]: AppColors.statusAmber,
  [Suitability.Avoid]: AppColors.statusRed,
  [Suitability.Neutral]: AppColors.borderStrong,
};

const BAND_LABELS: Record<Suitability, string> = {
  [Suitability.Good]: "Good",
  [Suitability.Caution]: "Caution",
  [Suitability.Avoid]: "Avoid",
  [Suitability.Neutral]: "—",
};

interface TimeWindowBarProps {
  title: string;
  windows: HourlySuitability[];
}

export function TimeWindowBar({ title, windows }: TimeWindowBarProps): React.ReactElement {
  const total = windows.reduce((sum, w) => sum + w.hours, 0) || 1;
  return (
    <View style={styles.wrap}>
      <View style={styles.header}>
        <Text style={styles.title}>{title}</Text>
        <Text style={styles.summary}>
          {windows.map((w, i) => `${BAND_LABELS[w.suitability]}${i < windows.length - 1 ? " · " : ""}`).join("")}
        </Text>
      </View>
      <View style={styles.track}>
        {windows.map((w, i) => (
          <View
            key={i}
            style={{
              flex: w.hours / total,
              backgroundColor: BAND_COLORS[w.suitability],
              marginRight: i < windows.length - 1 ? 2 : 0,
              borderRadius: 3,
              height: 10,
            }}
          />
        ))}
      </View>
      <View style={styles.hours}>
        <Text style={styles.hourLabel}>00</Text>
        <Text style={styles.hourLabel}>06</Text>
        <Text style={styles.hourLabel}>12</Text>
        <Text style={styles.hourLabel}>18</Text>
        <Text style={styles.hourLabel}>24</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: Spacing.xs + 2,
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "baseline",
  },
  title: {
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: "700",
  },
  summary: {
    color: AppColors.textTertiary,
    fontSize: 10.5,
    flexShrink: 1,
    textAlign: "right",
  },
  track: {
    flexDirection: "row",
    borderRadius: Radius.sm,
    overflow: "hidden",
  },
  hours: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  hourLabel: {
    color: AppColors.textTertiary,
    fontSize: 9,
  },
});
