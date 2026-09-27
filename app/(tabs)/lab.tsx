import { useTranslation } from "../../src/i18n/useTranslation";
import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet, Pressable, ScrollView } from "react-native";
import { MaterialCommunityIcons } from "@expo/vector-icons";

import { GlassCard } from "../../src/ui/components/GlassCard";
import { LineChart } from "../../src/ui/components/LineChart";
import { AppColors } from "../../src/ui/appColors";
import { Radius, Spacing } from "../../src/ui/theme";
import { useLocationStore } from "../../src/features/location/locationStore";
import { useSavedLocationsStore } from "../../src/features/explore/exploreStores";
import { AppLocation } from "../../src/features/models/location";
import {
  anomalyPercent,
  ArchiveStatus,
  AsyncComparison,
  AsyncSeries,
  COMPARISON_PALETTE,
  comparisonLastTwoYears,
  comparedTotal,
  comparedValueFor,
  fetchComparison,
  fetchHistoricalSeries,
  HistoricalMetric,
  historicalRangeLabel,
  longTermAverage,
  metricLabel,
  metricUnit,
  TrendMetric,
  useAnomalyTrendsStore,
} from "../../src/features/research/researchStores";

export default function LabScreen(): React.ReactElement {
  const t = useTranslation();
  const location = useLocationStore((s) => s.location);
  const [metric, setMetric] = useState<HistoricalMetric>(HistoricalMetric.Rainfall);
  const [series, setSeries] = useState<AsyncSeries>({ kind: "loading" });
  const [comparison, setComparison] = useState<AsyncComparison>({ kind: "loading" });
  const trend = useAnomalyTrendsStore((s) => s.metric);

  useEffect(() => {
    setSeries({ kind: "loading" });
    fetchHistoricalSeries({ metric, monthly: false }, location)
      .then((s) => setSeries({ kind: "data", series: s }))
      .catch((e: Error) => setSeries({ kind: "error", message: e.message }));
  }, [metric, location.lat, location.lon, location.name]);

  useEffect(() => {
    const saved = useSavedLocationsStore.getState().locations;
    setComparison({ kind: "loading" });
    fetchComparison(saved)
      .then((r) => setComparison({ kind: "data", result: r }))
      .catch((e: Error) => setComparison({ kind: "error", message: e.message }));
  }, []);

  const unit = metricUnit(metric);

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <View style={styles.headerRow}>
        <MaterialCommunityIcons name="flask-outline" size={24} color={AppColors.researcherBlue} />
        <Text style={styles.title}>Lab</Text>
      </View>

      <GlassCard style={{ gap: Spacing.md }}>
        <Text style={styles.sectionTitle}>Historical weather</Text>
        <View style={styles.metricRow}>
          {[HistoricalMetric.Rainfall, HistoricalMetric.Temperature, HistoricalMetric.Humidity].map((m) => (
            <Pressable key={m} onPress={() => setMetric(m)} style={[styles.metricPill, metric === m && styles.metricActive]}>
              <Text style={[styles.metricLabel, metric === m && { color: AppColors.bgPrimary }]}>{metricLabel(m)}</Text>
            </Pressable>
          ))}
        </View>
        {series.kind === "loading" && <Text style={styles.note}>Loading archive…</Text>}
        {series.kind === "error" && <Text style={styles.errorText}>{series.message}</Text>}
        {series.kind === "data" && (
          <>
            {series.series.status === ArchiveStatus.Unsupported && <Text style={styles.note}>{series.series.detail}</Text>}
            {series.series.status === ArchiveStatus.Empty && (
              <Text style={styles.note}>The archive has no data for this location.</Text>
            )}
            {series.series.status === ArchiveStatus.Available && (
              <>
                <LineChart points={series.series.points} color={AppColors.researcherBlue} unit={unit} />
                <View style={styles.statRow}>
                  <Text style={styles.stat}>Long-term mean: {longTermAverage(series.series.points).toFixed(1)}{unit}</Text>
                  <Text style={styles.stat}>Latest vs mean: {anomalyPercent(series.series.points).toFixed(1)}%</Text>
                </View>
                <Text style={styles.note}>Coverage {historicalRangeLabel(series.series) ?? "—"} · {series.series.source ?? "source not reported"}</Text>
              </>
            )}
          </>
        )}
      </GlassCard>

      <GlassCard style={{ gap: Spacing.md }}>
        <Text style={styles.sectionTitle}>{t("settings.comparison")}</Text>
        {comparison.kind === "loading" && <Text style={styles.note}>Loading comparison…</Text>}
        {comparison.kind === "error" && <Text style={styles.errorText}>{comparison.message}</Text>}
        {comparison.kind === "data" && comparison.result.detail !== null && <Text style={styles.note}>{comparison.result.detail}</Text>}
        {comparison.kind === "data" && comparison.result.detail === null && (
          <>
            <LineChart
              points={comparison.result.locations[0]?.points ?? []}
              color={comparison.result.locations[0]?.colorValue ?? AppColors.researcherBlue}
              unit=" mm"
            />
            <View style={{ gap: 4 }}>
              {comparisonLastTwoYears(comparison.result).map((year) => (
                <View key={year} style={styles.compareRow}>
                  <Text style={styles.compareYear}>{year}</Text>
                  {comparison.kind === "data" &&
                    comparison.result.locations.map((loc) => (
                      <Text key={loc.name} style={[styles.compareValue, { color: loc.colorValue }]}>
                        {comparedValueFor(loc, year) === null ? "—" : `${Math.round(comparedValueFor(loc, year) ?? 0)}`}
                      </Text>
                    ))}
                </View>
              ))}
              <View style={styles.compareRow}>
                <Text style={styles.compareYear}>Σ</Text>
                {comparison.result.locations.map((loc) => (
                  <Text key={loc.name} style={[styles.compareValue, { color: loc.colorValue }]}>
                    {comparedTotal(loc) === null ? "—" : `${Math.round(comparedTotal(loc) ?? 0)}`}
                  </Text>
                ))}
              </View>
            </View>
            <Text style={styles.note}>Rainfall totals, mm, per saved place.</Text>
          </>
        )}
      </GlassCard>

      <GlassCard style={{ gap: Spacing.md }}>
        <Text style={styles.sectionTitle}>Anomaly & trends</Text>
        <View style={styles.metricRow}>
          {[TrendMetric.Temperature, TrendMetric.Rainfall].map((m) => (
            <Pressable key={m} onPress={() => useAnomalyTrendsStore.getState().select(m)} style={[styles.metricPill, trend === m && styles.metricActive]}>
              <Text style={[styles.metricLabel, trend === m && { color: AppColors.bgPrimary }]}>{m === TrendMetric.Temperature ? "Temperature" : "Rainfall"}</Text>
            </Pressable>
          ))}
        </View>
        {series.kind === "data" && series.series.status === ArchiveStatus.Available && (
          <Text style={styles.note}>
            Deviation of the latest year from the mean of the returned window: {anomalyPercent(series.series.points).toFixed(1)}% — a display statistic, not a 30-year climate normal.
          </Text>
        )}
      </GlassCard>
    </ScrollView>
  );
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
  sectionTitle: {
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: "700",
  },
  metricRow: {
    flexDirection: "row",
    gap: Spacing.sm,
  },
  metricPill: {
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
  },
  metricActive: {
    backgroundColor: AppColors.accent,
    borderColor: AppColors.accent,
  },
  metricLabel: {
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: "600",
  },
  statRow: {
    gap: 2,
  },
  stat: {
    color: AppColors.textSecondary,
    fontSize: 12,
  },
  note: {
    color: AppColors.textTertiary,
    fontSize: 11.5,
    lineHeight: 17,
  },
  errorText: {
    color: AppColors.statusRed,
    fontSize: 12.5,
  },
  compareRow: {
    flexDirection: "row",
    gap: Spacing.lg,
  },
  compareYear: {
    color: AppColors.textSecondary,
    fontSize: 12.5,
    width: 44,
  },
  compareValue: {
    fontSize: 12.5,
    fontWeight: "700",
    width: 70,
  },
});
