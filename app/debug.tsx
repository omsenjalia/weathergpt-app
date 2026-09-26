import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet, Pressable, ScrollView } from "react-native";

import { GlassCard } from "../src/ui/components/GlassCard";
import { AppColors } from "../src/ui/appColors";
import { Radius, Spacing } from "../src/ui/theme";
import { useWeatherStore } from "../src/features/weather/weatherStore";
import { useRequestLogStore, requestLogOk, requestQueryString } from "../src/core/services/requestLog";
import { ApiEndpoints } from "../src/core/config/apiEndpoints";
import { ApiClient } from "../src/core/services/apiClient";
import { realFailures, skippedUnconfigured, weatherNextFailed } from "../src/core/models/dataProvenance";
import { fieldSourcesContributors, fieldSourcesProviderFor } from "../src/core/models/fieldSources";

type Tab = "snapshot" | "sources" | "providers" | "requests" | "health";

export default function DebugScreen(): React.ReactElement {
  const [tab, setTab] = useState<Tab>("snapshot");
  const snapshot = useWeatherStore((s) => s.snapshot);
  const lastRequest = useWeatherStore((s) => s.lastRequest);
  const v2Error = useWeatherStore((s) => s.error);
  const entries = useRequestLogStore((s) => s.entries);
  const clearLog = useRequestLogStore((s) => s.clear);
  const [health, setHealth] = useState<string>("probe not run");

  async function probeHealth(): Promise<void> {
    setHealth("probing…");
    try {
      const data = await ApiClient.get(ApiEndpoints.v2WeatherHealth);
      setHealth(JSON.stringify(data).slice(0, 400));
    } catch (error) {
      setHealth(`probe failed: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  const tabs: Array<{ id: Tab; label: string }> = [
    { id: "snapshot", label: "Snapshot" },
    { id: "sources", label: "Sources" },
    { id: "providers", label: "Providers" },
    { id: "requests", label: "Requests" },
    { id: "health", label: "Health" },
  ];

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.title}>Debug & state</Text>
      <View style={styles.tabs}>
        {tabs.map((t) => (
          <Pressable key={t.id} onPress={() => setTab(t.id)} style={[styles.tab, tab === t.id && styles.tabActive]}>
            <Text style={[styles.tabLabel, tab === t.id && { color: AppColors.bgPrimary }]}>{t.label}</Text>
          </Pressable>
        ))}
      </View>

      {tab === "snapshot" && (
        <GlassCard style={{ gap: Spacing.sm }}>
          <Row label="Endpoint" value={lastRequest?.endpoint ?? "—"} />
          <Row label="Query" value={lastRequest ? requestQueryString(lastRequest.query) : "—"} />
          <Row label="Legacy fallback" value={lastRequest?.usedLegacyFallback ? "yes" : "no"} />
          <Row label="City" value={snapshot?.cityName ?? "—"} />
          <Row label="Condition" value={snapshot?.condition ?? "—"} />
          <Row label="WMO code" value={snapshot?.weatherCode === null || snapshot?.weatherCode === undefined ? "not reported" : String(snapshot.weatherCode)} />
          <Row label="Hourly points" value={snapshot ? String(snapshot.hourly.length) : "—"} />
          <Row label="Forecast days" value={snapshot ? String(snapshot.forecast.length) : "—"} />
          <Row label="Degraded" value={snapshot?.degraded === null || snapshot?.degraded === undefined ? "not reported" : snapshot.degraded ? "yes" : "no"} />
          {v2Error !== null && <Row label="Last error" value={v2Error} />}
        </GlassCard>
      )}

      {tab === "sources" && snapshot !== null && (
        <GlassCard style={{ gap: Spacing.sm }}>
          <Row label="Selected source" value={snapshot.provenance.selectedSource ?? snapshot.provenance.source ?? "not reported"} />
          <Row label="Requested source" value={snapshot.provenance.requestedSource ?? "—"} />
          <Row label="Run" value={snapshot.provenance.runId ?? "—"} />
          <Row label="Issued at" value={snapshot.provenance.issuedAtUtc?.toISOString() ?? "—"} />
          <Row label="Retrieved at" value={snapshot.provenance.retrievedAtUtc?.toISOString() ?? "—"} />
          <Row label="Contributors" value={fieldSourcesContributors(snapshot.fieldSources).join(", ") || "—"} />
          {Object.entries(snapshot.fieldSources.sources).slice(0, 14).map(([field, provider]) => (
            <Row key={field} label={field} value={provider === null || provider === undefined ? "explicitly missing" : provider} />
          ))}
          {snapshot.fieldSources.supplementFilled.length > 0 && (
            <Row label="Supplemented" value={snapshot.fieldSources.supplementFilled.join(", ")} />
          )}
        </GlassCard>
      )}

      {tab === "providers" && snapshot !== null && (
        <GlassCard style={{ gap: Spacing.sm }}>
          <Row label="Tried providers" value={snapshot.provenance.triedProviders.join(", ") || "—"} />
          <Row label="Real failures" value={realFailures(snapshot.provenance).map((r) => `${r.provider}: ${r.reason}`).join("; ") || "none"} />
          <Row label="Skipped (unconfigured)" value={skippedUnconfigured(snapshot.provenance).map((r) => r.provider).join(", ") || "none"} />
          <Row label="Missing fields" value={snapshot.provenance.missingFields.join(", ") || "none"} />
          <Row label="Policy version" value={snapshot.provenance.selectionPolicyVersion ?? "—"} />
          <Row label="Freshness" value={snapshot.provenance.freshnessStatus ?? "—"} />
          <Row label="WeatherNext failed" value={snapshot.provenance.fallbackReasons.length > 0 ? String(weatherNextFailed(snapshot.provenance)) : "—"} />
        </GlassCard>
      )}

      {tab === "requests" && (
        <GlassCard style={{ gap: Spacing.sm }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
            <Text style={styles.sectionTitle}>Last {entries.length} requests</Text>
            <Pressable onPress={clearLog}>
              <Text style={styles.clear}>Clear</Text>
            </Pressable>
          </View>
          {entries.map((entry) => (
            <View key={entry.id} style={styles.logRow}>
              <Text style={[styles.logStatus, { color: requestLogOk(entry) ? AppColors.statusGreenText : AppColors.statusRed }]}>
                {entry.statusCode ?? "ERR"}
              </Text>
              <View style={{ flex: 1 }}>
                <Text style={styles.logPath} numberOfLines={1}>
                  {entry.method} {entry.path}
                </Text>
                {entry.summary !== null && entry.summary !== undefined && <Text style={styles.logSummary}>{entry.summary}</Text>}
                {entry.error !== null && entry.error !== undefined && <Text style={styles.logError}>{entry.error}</Text>}
              </View>
              <Text style={styles.logMs}>{entry.durationMs ?? "?"} ms</Text>
            </View>
          ))}
        </GlassCard>
      )}

      {tab === "health" && (
        <GlassCard style={{ gap: Spacing.md }}>
          <Text style={styles.sectionTitle}>Backend /v2/weather/health</Text>
          <PrimaryButtonFlat label="Probe now" onPress={() => void probeHealth()} />
          <Text style={styles.healthText}>{health}</Text>
        </GlassCard>
      )}
    </ScrollView>
  );
}

function Row({ label, value }: { label: string; value: string }): React.ReactElement {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={styles.rowValue}>{value}</Text>
    </View>
  );
}

function PrimaryButtonFlat({ label, onPress }: { label: string; onPress: () => void }): React.ReactElement {
  return (
    <Pressable onPress={onPress} style={styles.probe}>
      <Text style={styles.probeLabel}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  scroll: {
    padding: Spacing.lg,
    paddingBottom: 80,
    gap: Spacing.md,
  },
  title: {
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: "800",
  },
  tabs: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Spacing.sm,
  },
  tab: {
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
  },
  tabActive: {
    backgroundColor: AppColors.accent,
    borderColor: AppColors.accent,
  },
  tabLabel: {
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: "600",
  },
  sectionTitle: {
    color: AppColors.textPrimary,
    fontSize: 13.5,
    fontWeight: "700",
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: Spacing.md,
  },
  rowLabel: {
    color: AppColors.textTertiary,
    fontSize: 11.5,
    flexShrink: 1,
  },
  rowValue: {
    color: AppColors.textPrimary,
    fontSize: 11.5,
    fontWeight: "600",
    flexShrink: 2,
    textAlign: "right",
  },
  logRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
    paddingVertical: 5,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: AppColors.borderSubtle,
  },
  logStatus: {
    fontWeight: "800",
    fontSize: 11,
    width: 34,
  },
  logPath: {
    color: AppColors.textPrimary,
    fontSize: 11.5,
    fontWeight: "600",
  },
  logSummary: {
    color: AppColors.textTertiary,
    fontSize: 10,
  },
  logError: {
    color: AppColors.statusRed,
    fontSize: 10,
  },
  logMs: {
    color: AppColors.textTertiary,
    fontSize: 10,
  },
  clear: {
    color: AppColors.statusRed,
    fontSize: 12,
  },
  probe: {
    backgroundColor: AppColors.accent,
    borderRadius: Radius.pill,
    paddingVertical: 10,
    alignItems: "center",
  },
  probeLabel: {
    color: AppColors.bgPrimary,
    fontWeight: "700",
    fontSize: 13,
  },
  healthText: {
    color: AppColors.textSecondary,
    fontSize: 11.5,
  },
});
