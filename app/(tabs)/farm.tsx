import React, { useEffect } from "react";
import { View, Text, StyleSheet, Pressable, ScrollView, ActivityIndicator } from "react-native";
import { MaterialCommunityIcons } from "@expo/vector-icons";
import { router } from "expo-router";

import { GlassCard } from "../../src/ui/components/GlassCard";
import { TimeWindowBar } from "../../src/ui/components/TimeWindowBar";
import { PrimaryButton } from "../../src/ui/components/Buttons";
import { AppColors } from "../../src/ui/appColors";
import { Radius, Spacing } from "../../src/ui/theme";
import { useSettingsStore } from "../../src/features/settings/settingsStore";
import { useFarmProfileStore } from "../../src/features/farm/farmStores";
import {
  AdvisoryStatus,
  actionWindowsHasData,
  useActionWindowsStore,
} from "../../src/features/farm/farmStores";
import { ActionWindowTab } from "../../src/features/farm/models/advisoryModels";
import { useLocationStore } from "../../src/features/location/locationStore";

export default function FarmScreen(): React.ReactElement {
  const settings = useSettingsStore();
  const profile = useFarmProfileStore((s) => s.profile);
  const completed = useFarmProfileStore((s) => s.completed);
  const location = useLocationStore((s) => s.location);
  const advisory = useActionWindowsStore((s) => s.state);
  const generation = useActionWindowsStore((s) => s.generation);

  useEffect(() => {
    useActionWindowsStore.getState().setContext({ location, profile, mode: settings.userPersona });
    useActionWindowsStore.getState().selectTab(advisory.selectedTab);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location.lat, location.lon, profile.crop, profile.growthStage, profile.soilType, profile.irrigationType, settings.userPersona]);

  const unavailable = advisory.status === AdvisoryStatus.Unavailable || !actionWindowsHasData(advisory);

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <View style={styles.headerRow}>
        <MaterialCommunityIcons name="sprout" size={24} color={AppColors.farmerGreen} />
        <Text style={styles.title}>Farm</Text>
        <Pressable onPress={() => router.push("/farm-profile")}>
          <Text style={styles.edit}>Edit profile</Text>
        </Pressable>
      </View>

      <GlassCard>
        <Text style={styles.sectionTitle}>Farm profile</Text>
        {completed ? (
          <View style={{ gap: 4 }}>
            <Text style={styles.profileLine}>📍 {profile.location || location.name}</Text>
            <Text style={styles.profileLine}>🌾 {profile.crop} · {profile.growthStage}</Text>
            <Text style={styles.profileLine}>📏 {profile.farmSizeAcres} acres · {profile.soilType} soil · {profile.irrigationType}</Text>
          </View>
        ) : (
          <View style={{ gap: Spacing.sm }}>
            <Text style={styles.empty}>Complete your farm profile — crop advice is tuned to these details.</Text>
            <PrimaryButton label="Complete profile" onPress={() => router.push("/farm-profile")} />
          </View>
        )}
      </GlassCard>

      <View style={styles.tabs}>
        {(["today", "tomorrow", "sevenDay"] as ActionWindowTab[]).map((tab) => (
          <Pressable
            key={tab}
            onPress={() => useActionWindowsStore.getState().selectTab(tab)}
            style={[styles.tab, advisory.selectedTab === tab && styles.tabActive]}
          >
            <Text style={[styles.tabLabel, advisory.selectedTab === tab && { color: AppColors.bgPrimary }]}>{tabLabel(tab)}</Text>
          </Pressable>
        ))}
      </View>

      {advisory.status === AdvisoryStatus.Loading ? (
        <View style={styles.center}>
          <ActivityIndicator color={AppColors.accent} />
        </View>
      ) : unavailable ? (
        <GlassCard strong style={styles.unavailableCard}>
          <MaterialCommunityIcons name="cloud-off-outline" size={30} color={AppColors.statusAmber} />
          <Text style={styles.unavailableTitle}>Advisory unavailable</Text>
          <Text style={styles.unavailableBody}>
            No verified action windows for this field right now. Nothing is shown rather than guessed — tap retry to try again.
          </Text>
          <PrimaryButton label="Retry" onPress={() => void useActionWindowsStore.getState().refresh()} style={{ marginTop: Spacing.md, minWidth: 140 }} />
        </GlassCard>
      ) : (
        <GlassCard style={{ gap: Spacing.lg }}>
          <View style={styles.verdictRow}>
            <Text style={styles.verdict}>{advisory.summaryVerdict}</Text>
            {advisory.source === ("systemOne" as never) && advisory.aiConfidence !== null && (
              <View style={styles.confidenceBadge}>
                <Text style={styles.confidenceText}>System One · {Math.round((advisory.aiConfidence ?? 0) * 100)}% confident</Text>
              </View>
            )}
          </View>
          <TimeWindowBar title="Irrigation" windows={advisory.irrigationWindows} />
          <TimeWindowBar title="Spraying" windows={advisory.sprayingWindows} />
          <TimeWindowBar title="Field work" windows={advisory.fieldWorkWindows} />
          {advisory.fieldWorkStatus !== "" && <Text style={styles.bestWindow}>{advisory.fieldWorkStatus}</Text>}
          {advisory.summaryExplanation !== "" && <Text style={styles.explanation}>{advisory.summaryExplanation}</Text>}
          {advisory.asOfUtc !== null && (
            <Text style={styles.asOf}>Last verified {advisory.asOfUtc.toLocaleString()}</Text>
          )}
        </GlassCard>
      )}

      {generation < 0 ? null : null}
    </ScrollView>
  );
}

function tabLabel(tab: ActionWindowTab): string {
  switch (tab) {
    case ActionWindowTab.Today:
      return "Today";
    case ActionWindowTab.Tomorrow:
      return "Tomorrow";
    default:
      return "7 Days";
  }
}

const styles = StyleSheet.create({
  scroll: {
    padding: Spacing.lg,
    paddingBottom: 120,
    gap: Spacing.md,
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
  },
  title: {
    flex: 1,
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: "800",
  },
  edit: {
    color: AppColors.accent,
    fontSize: 13,
    fontWeight: "600",
  },
  sectionTitle: {
    color: AppColors.textTertiary,
    fontSize: 11,
    fontWeight: "700",
    letterSpacing: 1,
    textTransform: "uppercase",
    marginBottom: 6,
  },
  profileLine: {
    color: AppColors.textPrimary,
    fontSize: 13.5,
    lineHeight: 20,
  },
  tabs: {
    flexDirection: "row",
    backgroundColor: AppColors.glassFill,
    borderRadius: Radius.pill,
    padding: 3,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: AppColors.glassBorder,
  },
  tab: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: Radius.pill,
    alignItems: "center",
  },
  tabActive: {
    backgroundColor: AppColors.accent,
  },
  tabLabel: {
    color: AppColors.textSecondary,
    fontSize: 12.5,
    fontWeight: "600",
  },
  center: {
    paddingVertical: Spacing.xxl,
    alignItems: "center",
  },
  unavailableCard: {
    alignItems: "center",
    paddingVertical: Spacing.xl,
    gap: Spacing.sm,
  },
  unavailableTitle: {
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: "700",
  },
  unavailableBody: {
    color: AppColors.textSecondary,
    fontSize: 12.5,
    textAlign: "center",
    lineHeight: 18,
  },
  verdictRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    flexWrap: "wrap",
    gap: Spacing.sm,
  },
  verdict: {
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: "800",
    flexShrink: 1,
  },
  confidenceBadge: {
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.farmerGreen,
    backgroundColor: `${AppColors.farmerGreen}1A`,
    paddingHorizontal: Spacing.md,
    paddingVertical: 4,
  },
  confidenceText: {
    color: AppColors.farmerGreen,
    fontSize: 10.5,
    fontWeight: "700",
  },
  bestWindow: {
    color: AppColors.accent,
    fontSize: 13,
    fontWeight: "700",
  },
  explanation: {
    color: AppColors.textSecondary,
    fontSize: 13,
    lineHeight: 19,
  },
  asOf: {
    color: AppColors.textTertiary,
    fontSize: 10.5,
  },
  empty: {
    color: AppColors.textSecondary,
    fontSize: 13,
  },
});
