import { useTranslation } from "../../src/i18n/useTranslation";
import React, { useCallback, useEffect, useMemo, useState, useRef } from "react";
import { ScrollView, View, Text, StyleSheet, RefreshControl, Pressable, TextInput, ActivityIndicator } from "react-native";
import { MaterialCommunityIcons } from "@expo/vector-icons";
import { router } from "expo-router";

import { formatTemperature } from "../../src/core/utils/temperature";

import { GlassCard } from "../../src/ui/components/GlassCard";
import { ApiErrorView } from "../../src/ui/components/ApiErrorView";
import { MetricChip } from "../../src/ui/components/Chips";
import { PrimaryButton } from "../../src/ui/components/Buttons";
import { AppColors } from "../../src/ui/appColors";
import { Radius, Spacing } from "../../src/ui/theme";
import { useSettingsStore, selectMode } from "../../src/features/settings/settingsStore";
import { useLocationStore } from "../../src/features/location/locationStore";
import { useDeveloperOptionsStore } from "../../src/features/settings/developerOptionsStore";
import { atmospherePalette, useWeatherStore } from "../../src/features/weather/weatherStore";
import { WeatherSnapshot } from "../../src/features/weather/models/weather";
import { AppLocation } from "../../src/features/models/location";
import { GeocodingService } from "../../src/core/services/geocodingService";
import { conditionFromWeather } from "../../src/features/weather/theme/atmosphereTheme";

type Segment = "overview" | "hourly" | "daily";

export default function HomeScreen(): React.ReactElement {
  const t = useTranslation();
  const settings = useSettingsStore();
  const mode = useSettingsStore(selectMode);
  const dev = useDeveloperOptionsStore();
  const location = useLocationStore((s) => s.location);
  const { snapshot, loading, error, lastRequest, fetchWeather } = useWeatherStore();
  const [segment, setSegment] = useState<Segment>("overview");
  const searchGeneration = useRef(0);
  const [search, setSearch] = useState("");
  const [searching, setSearching] = useState(false);
  const [suggest, setSuggest] = useState<AppLocation[]>([]);

  const load = useCallback(
    () => fetchWeather(location, mode, dev),
    [fetchWeather, location, mode, dev],
  );

  useEffect(() => {
    void load();
  }, [load]);

  const palette = useMemo(
    () => atmospherePalette(new Date(), snapshot, { forcePeriod: dev.forcePeriod, forceSky: dev.forceSky }),
    [snapshot, dev.forcePeriod, dev.forceSky],
  );

  async function runSearch(query: string): Promise<void> {
    const generation = ++searchGeneration.current;
    setSearch(query);
    if (query.trim().length < 2) {
      setSearching(false);
      setSuggest([]);
      return;
    }
    setSearching(true);
    const results = await GeocodingService.searchMany(query, 5);
    if (generation !== searchGeneration.current) return;
    setSuggest(results);
    setSearching(false);
  }

  if (error !== null && snapshot === null) {
    return <ApiErrorView message={error} onRetry={load} />;
  }

  if (snapshot === null) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={AppColors.accent} />
        <Text style={styles.loadingText}>Loading…</Text>
      </View>
    );
  }

  return (
    <ScrollView
      contentContainerStyle={styles.scroll}
      refreshControl={<RefreshControl refreshing={loading} onRefresh={load} tintColor={AppColors.accent} />}
    >
      {/* Location + search */}
      <View style={styles.locationRow}>
        <MaterialCommunityIcons name="map-marker" size={18} color={palette.accent} />
        <Text style={[styles.locationName, { color: palette.text }]}>{location.name}</Text>
        <Pressable onPress={() => router.push("/(tabs)/profile")}>
          <MaterialCommunityIcons name="tune-vertical" size={18} color={palette.textMuted} />
        </Pressable>
      </View>
      <View style={styles.searchWrap}>
        <TextInput
          value={search}
          onChangeText={(v) => void runSearch(v)}
          placeholder={t("home.search_hint")}
          placeholderTextColor={AppColors.textTertiary}
          style={styles.search}
        />
        {searching && <ActivityIndicator color={AppColors.accent} style={{ position: "absolute", right: 12, top: 12 }} />}
        {suggest.length > 0 && (
          <View style={styles.suggest}>
            {suggest.map((place) => (
              <Pressable
                key={`${place.name}-${place.lat}`}
                style={styles.suggestRow}
                onPress={() => {
                  searchGeneration.current++;
                  setSearching(false);
                  void useLocationStore.getState().select(place);
                  setSuggest([]);
                  setSearch("");
                }}
              >
                <Text style={styles.suggestText} numberOfLines={1}>
                  {place.name}
                </Text>
              </Pressable>
            ))}
          </View>
        )}
      </View>

      <SegmentTabs segment={segment} onChange={setSegment} />

      {segment === "overview" && <Overview snapshot={snapshot} palette={palette} />}
      {segment === "hourly" && <HourlyStrip snapshot={snapshot} palette={palette} />}
      {segment === "daily" && <DailyList snapshot={snapshot} palette={palette} />}

      {/* Ask bar */}
      <Pressable style={styles.askBar} onPress={() => router.push("/(tabs)/chat")}>
        <MaterialCommunityIcons name="microphone-outline" size={20} color={AppColors.textTertiary} />
        <Text style={styles.askText}>
          {mode === "farmer" ? "How can I help you?" : mode === "researcher" ? "Ask a research question" : "Ask WeatherGPT anything..."}
        </Text>
      </Pressable>

      {mode === "farmer" && (
        <View style={styles.farmRow}>
          <PrimaryButton label={t("home.my_farm")} onPress={() => router.push("/(tabs)/farm")} style={{ flex: 1 }} />
          <PrimaryButton label={t("home.action_windows")} onPress={() => router.push("/(tabs)/farm")} variant="white" style={{ flex: 1 }} />
        </View>
      )}

      {dev.enabled && lastRequest !== null && (
        <Text style={styles.debugNote}>
          {lastRequest.endpoint}
          {lastRequest.usedLegacyFallback ? " (legacy fallback)" : ""}
        </Text>
      )}
    </ScrollView>
  );
}

function Overview({ snapshot, palette }: { snapshot: WeatherSnapshot; palette: ReturnType<typeof atmospherePalette> }): React.ReactElement {
  const t = useTranslation();
  const units = useSettingsStore((s) => s.units);
  const uvLabel = uvBand(snapshot.uvIndex ?? null);
  return (
    <View style={{ gap: Spacing.md }}>
      <GlassCard strong style={styles.hero}>
        <Text style={styles.heroTemp}>{formatTemperature(snapshot.temperatureC, units)}</Text>
        <Text style={styles.heroCondition}>{snapshot.condition}</Text>
        <Text style={styles.heroRange}>
          H: {formatTemperature(snapshot.highC, units)}  L:{" "}
          {formatTemperature(snapshot.lowC, units)}
        </Text>
        {snapshot.feelsLikeC !== null && snapshot.feelsLikeC !== undefined && (
          <Text style={styles.heroFeels}>Feels like {formatTemperature(snapshot.feelsLikeC, units)}</Text>
        )}
      </GlassCard>

      <View style={styles.chips}>
        <MetricChip icon="💧" value={snapshot.rainProbability === null || snapshot.rainProbability === undefined ? "—" : `${Math.round(snapshot.rainProbability)}%`} label={t("map.layer_rain")} />
        <MetricChip icon="🌬️" value={snapshot.windKmh === null || snapshot.windKmh === undefined ? "—" : `${Math.round(snapshot.windKmh)} km/h`} label={t("home.wind")} />
      </View>
      <View style={styles.chips}>
        <MetricChip icon="💦" value={snapshot.humidity === null || snapshot.humidity === undefined ? "—" : `${Math.round(snapshot.humidity)}%`} label={t("home.humidity")} />
        <MetricChip icon="🧭" value={snapshot.pressureHpa === null || snapshot.pressureHpa === undefined ? "—" : `${Math.round(snapshot.pressureHpa)} hPa`} label={t("home.pressure")} />
      </View>
      <View style={styles.chips}>
        <MetricChip icon="🌅" value={formatClockShort(snapshot.sunrise)} label={t("home.sunrise")} />
        <MetricChip icon="🌇" value={formatClockShort(snapshot.sunset)} label={t("home.sunset")} />
      </View>
      <View style={styles.chips}>
        <MetricChip icon={uvLabel === null ? "☀️" : "🕶️"} value={snapshot.uvIndex === null || snapshot.uvIndex === undefined ? "—" : `${snapshot.uvIndex}`} label={`UV${uvLabel !== null ? ` · ${uvLabel}` : ""}`} />
        <MetricChip icon="🌫️" value={snapshot.aqi === null || snapshot.aqi === undefined ? "—" : `${Math.round(snapshot.aqi)}`} label={t("weather.aqi")} />
      </View>

      {/* Developer-only provenance row (never shown to regular users) */}
      {snapshot.provenance !== null && (snapshot.provenance.selectedSource ?? snapshot.provenance.source) !== null && devProvenanceVisible(snapshot) && (
        <GlassCard style={styles.provCard}>
          <Text style={styles.provText}>
            Source: {(snapshot.provenance.selectedSource ?? snapshot.provenance.source) ?? "—"}
            {snapshot.provenance.runId !== null && snapshot.provenance.runId !== undefined ? ` · run ${snapshot.provenance.runId}` : ""}
          </Text>
        </GlassCard>
      )}
    </View>
  );
}

function devProvenanceVisible(_snapshot: WeatherSnapshot): boolean {
  // Provenance display is gated by dev options in the Debug screen; keep the
  // home surface clean by default.
  return false;
}

function HourlyStrip({ snapshot, palette }: { snapshot: WeatherSnapshot; palette: ReturnType<typeof atmospherePalette> }): React.ReactElement {
  const t = useTranslation();
  const units = useSettingsStore((s) => s.units);
  if (snapshot.hourly.length === 0) {
    return (
      <GlassCard>
        <Text style={styles.emptyText}>{t("home.hourly_unavailable")}</Text>
      </GlassCard>
    );
  }
  const temps = snapshot.hourly.map((h) => h.tempC);
  const min = Math.min(...temps);
  const max = Math.max(...temps);
  return (
    <GlassCard>
      <Text style={styles.sectionTitle}>Next {snapshot.hourly.length} hours</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: Spacing.md, paddingVertical: Spacing.sm }}>
        {snapshot.hourly.map((h, i) => {
          const ratio = (h.tempC - min) / Math.max(max - min, 0.1);
          return (
            <View key={i} style={styles.hourCell}>
              <Text style={styles.hourLabel}>{i === 0 ? "Now" : h.label}</Text>
              <View
                style={{
                  width: 6,
                  height: 18 + ratio * 34,
                  borderRadius: 3,
                  backgroundColor: palette.accent,
                  opacity: 0.55 + ratio * 0.45,
                }}
              />
              <Text style={styles.hourTemp}>{formatTemperature(h.tempC, units)}</Text>
              {h.rainProbability !== null && h.rainProbability !== undefined && (
                <Text style={styles.hourRain}>{Math.round(h.rainProbability)}%</Text>
              )}
            </View>
          );
        })}
      </ScrollView>
    </GlassCard>
  );
}

function DailyList({ snapshot, palette }: { snapshot: WeatherSnapshot; palette: ReturnType<typeof atmospherePalette> }): React.ReactElement {
  const t = useTranslation();
  const units = useSettingsStore((s) => s.units);
  if (snapshot.forecast.length === 0) {
    return (
      <GlassCard>
        <Text style={styles.emptyText}>{t("home.forecast_unavailable")}</Text>
      </GlassCard>
    );
  }
  return (
    <GlassCard>
      <Text style={styles.sectionTitle}>{snapshot.forecast.length}-day forecast</Text>
      <View style={{ gap: Spacing.sm }}>
        {snapshot.forecast.map((day, i) => {
          const icon = conditionIcon(conditionFromWeather({ weatherCode: day.weatherCode ?? null, condition: day.condition, windKmh: day.windKmhMax ?? null }));
          return (
            <View key={`${day.date}-${i}`} style={styles.dayRow}>
              <Text style={styles.dayName}>{i === 0 ? "Today" : weekdayLabel(day.date, i)}</Text>
              <MaterialCommunityIcons name={icon} size={20} color={palette.accent} />
              <View style={styles.dayTemps}>
                <Text style={styles.dayHigh}>{formatTemperature(day.highC, units)}</Text>
                <Text style={styles.dayLow}>{formatTemperature(day.lowC, units)}</Text>
              </View>
              <Text style={styles.dayRain}>
                {day.rainProbability === null || day.rainProbability === undefined ? "—" : `${Math.round(day.rainProbability)}%`}
              </Text>
            </View>
          );
        })}
      </View>
    </GlassCard>
  );
}

function SegmentTabs({ segment, onChange }: { segment: Segment; onChange: (s: Segment) => void }): React.ReactElement {
  const tabs: Array<{ id: Segment; label: string }> = [
    { id: "overview", label: "Overview" },
    { id: "hourly", label: "Hourly" },
    { id: "daily", label: "7-Day" },
  ];
  return (
    <View style={styles.tabs}>
      {tabs.map((tab) => (
        <Pressable key={tab.id} onPress={() => onChange(tab.id)} style={[styles.tab, segment === tab.id && styles.tabActive]}>
          <Text style={[styles.tabLabel, segment === tab.id && { color: AppColors.bgPrimary, fontWeight: "700" }]}>{tab.label}</Text>
        </Pressable>
      ))}
    </View>
  );
}

function uvBand(uv: number | null): string | null {
  if (uv === null) return null;
  if (uv < 3) return "Low";
  if (uv < 6) return "Moderate";
  if (uv < 8) return "High";
  if (uv < 11) return "Very high";
  return "Extreme";
}

function formatClockShort(raw: string | null | undefined): string {
  if (!raw) return "—";
  const m = /T(\d{2}):(\d{2})/.exec(raw);
  if (m === null) return "—";
  const h = parseInt(m[1], 10);
  const min = m[2];
  const period = h >= 12 ? "PM" : "AM";
  const h12 = h === 0 ? 12 : h > 12 ? h - 12 : h;
  return `${h12}:${min} ${period}`;
}

function weekdayLabel(date: string, index: number): string {
  const parsed = new Date(`${date}T12:00:00Z`);
  if (Number.isNaN(parsed.getTime())) return date;
  return parsed.toLocaleDateString(undefined, { weekday: "short" });
}

function conditionIcon(condition: string): keyof typeof MaterialCommunityIcons.glyphMap {
  switch (condition) {
    case "thunder":
      return "weather-lightning";
    case "snow":
      return "weather-snowy";
    case "heavyRain":
    case "rain":
      return "weather-pouring";
    case "drizzle":
      return "weather-partly-rainy";
    case "fog":
      return "weather-fog";
    case "overcast":
      return "weather-cloudy";
    case "partlyCloudy":
      return "weather-partly-cloudy";
    case "cloudy":
      return "weather-cloudy";
    case "windy":
      return "weather-windy";
    default:
      return "weather-sunny";
  }
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    gap: Spacing.md,
  },
  loadingText: {
    color: AppColors.textSecondary,
    fontSize: 13,
  },
  scroll: {
    padding: Spacing.lg,
    paddingBottom: 120,
    gap: Spacing.md,
  },
  locationRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  locationName: {
    fontSize: 16,
    fontWeight: "700",
    flex: 1,
  },
  searchWrap: {
    position: "relative",
  },
  search: {
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    backgroundColor: AppColors.glassFill,
    color: AppColors.textPrimary,
    paddingHorizontal: Spacing.lg,
    paddingVertical: 10,
    fontSize: 14,
  },
  suggest: {
    position: "absolute",
    top: 46,
    left: 0,
    right: 0,
    zIndex: 20,
    borderRadius: Radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: AppColors.glassBorderStrong,
    backgroundColor: AppColors.bgElevated,
    overflow: "hidden",
  },
  suggestRow: {
    paddingHorizontal: Spacing.md,
    paddingVertical: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: AppColors.borderSubtle,
  },
  suggestText: {
    color: AppColors.textPrimary,
    fontSize: 13,
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
  hero: {
    alignItems: "center",
    paddingVertical: Spacing.xl,
    gap: 2,
  },
  heroTemp: {
    fontSize: 84,
    fontWeight: "300",
    color: AppColors.textPrimary,
    letterSpacing: -2,
  },
  heroCondition: {
    fontSize: 15,
    color: AppColors.textSecondary,
    fontWeight: "600",
  },
  heroRange: {
    fontSize: 13,
    color: AppColors.textTertiary,
    marginTop: 2,
  },
  heroFeels: {
    fontSize: 12,
    color: AppColors.textTertiary,
  },
  chips: {
    flexDirection: "row",
    gap: Spacing.sm,
  },
  sectionTitle: {
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: "700",
    marginBottom: Spacing.xs,
  },
  hourCell: {
    alignItems: "center",
    gap: 4,
    minWidth: 42,
  },
  hourLabel: {
    color: AppColors.textTertiary,
    fontSize: 10,
  },
  hourTemp: {
    color: AppColors.textPrimary,
    fontSize: 12.5,
    fontWeight: "700",
  },
  hourRain: {
    color: AppColors.sky,
    fontSize: 9.5,
  },
  dayRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.md,
  },
  dayName: {
    color: AppColors.textPrimary,
    fontSize: 13,
    width: 52,
    fontWeight: "600",
  },
  dayTemps: {
    flex: 1,
    flexDirection: "row",
    justifyContent: "flex-end",
    gap: Spacing.md,
  },
  dayHigh: {
    color: AppColors.textPrimary,
    fontSize: 13.5,
    fontWeight: "700",
    width: 34,
    textAlign: "right",
  },
  dayLow: {
    color: AppColors.textTertiary,
    fontSize: 13,
    width: 34,
    textAlign: "right",
  },
  dayRain: {
    color: AppColors.sky,
    fontSize: 11.5,
    width: 38,
    textAlign: "right",
  },
  askBar: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    backgroundColor: AppColors.glassFill,
    paddingHorizontal: Spacing.lg,
    paddingVertical: 12,
  },
  askText: {
    color: AppColors.textTertiary,
    fontSize: 13.5,
  },
  farmRow: {
    flexDirection: "row",
    gap: Spacing.sm,
  },
  provCard: {
    paddingVertical: Spacing.sm,
  },
  provText: {
    color: AppColors.textTertiary,
    fontSize: 11,
  },
  debugNote: {
    color: AppColors.textTertiary,
    fontSize: 10,
    textAlign: "center",
  },
  emptyText: {
    color: AppColors.textSecondary,
    fontSize: 13,
  },
});
