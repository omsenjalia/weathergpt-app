import { useTranslation } from "../../src/i18n/useTranslation";
import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet, Pressable, ScrollView, Platform, TextInput, ActivityIndicator } from "react-native";

import { WebView } from "react-native-webview";

import { GlassCard } from "../../src/ui/components/GlassCard";
import { AppColors } from "../../src/ui/appColors";
import { Radius, Spacing } from "../../src/ui/theme";
import {
  MAP_ALL_LAYERS,
  MAP_LAYER_LABEL,
  MapLayer,
  useMapStore,
  useSavedLocationsStore,
  windyEmbedUrl,
} from "../../src/features/explore/exploreStores";
import { useLocationStore } from "../../src/features/location/locationStore";
import { SavedLocation } from "../../src/features/models/location";
import { GeocodingService } from "../../src/core/services/geocodingService";

export default function ExploreScreen(): React.ReactElement {
  const t = useTranslation();
  const map = useMapStore();
  const saved = useSavedLocationsStore((s) => s.locations);
  const currentLocation = useLocationStore((s) => s.location);
  const [query, setQuery] = useState("");
  const [busy, setBusy] = useState(false);
  const [results, setResults] = useState<SavedLocation[]>([]);

  useEffect(() => {
    map.setCenter(currentLocation.lat, currentLocation.lon, 8);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentLocation.lat, currentLocation.lon]);

  async function search(): Promise<void> {
    if (query.trim().length < 2) return;
    setBusy(true);
    const places = await GeocodingService.searchMany(query, 5);
    setResults(places.map((p) => new SavedLocation(p.name, p.lat, p.lon)));
    setBusy(false);
  }

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.title}>{t("map.title")}</Text>

      <GlassCard style={styles.mapCard}>
        {Platform.OS === "web" ? (
          <iframe
            src={windyEmbedUrl(map)}
            title="Windy map"
            style={{ width: "100%", height: 360, border: "none", borderRadius: 12 }}
          />
        ) : (
          <WebView
            source={{ uri: windyEmbedUrl(map) }}
            style={{ height: 360, backgroundColor: "transparent" }}
            originWhitelist={["https://*"]}
            mixedContentMode="never"
            startInLoadingState
            renderError={() => <Text style={styles.nativeNoteText}>Map unavailable. Check your connection.</Text>}
          />
        )}
      </GlassCard>

      <View style={styles.layers}>
        {MAP_ALL_LAYERS.map((layer) => (
          <Pressable
            key={layer}
            onPress={() => map.setLayer(layer)}
            style={[styles.layerPill, map.activeLayer === layer && styles.layerActive]}
          >
            <Text style={[styles.layerLabel, map.activeLayer === layer && { color: AppColors.bgPrimary }]}>{MAP_LAYER_LABEL[layer]}</Text>
          </Pressable>
        ))}
      </View>

      <GlassCard style={{ gap: Spacing.md }}>
        <Text style={styles.sectionTitle}>Add a place</Text>
        <View style={{ flexDirection: "row", gap: Spacing.sm }}>
          <TextInput
            value={query}
            onChangeText={setQuery}
            onSubmitEditing={() => void search()}
            placeholder={t("location.search_hint")}
            placeholderTextColor={AppColors.textTertiary}
            style={styles.input}
          />
          <Pressable style={styles.add} onPress={() => void search()}>
            {busy ? <ActivityIndicator size="small" color={AppColors.bgPrimary} /> : <Text style={styles.addLabel}>{t("location.save")}</Text>}
          </Pressable>
        </View>
        {results.map((place) => (
          <Pressable
            key={`${place.name}-${place.lat}`}
            style={styles.resultRow}
            onPress={() => {
              void useSavedLocationsStore.getState().add(place);
              setResults((r) => r.filter((x) => x !== place));
              setQuery("");
            }}
          >
            <Text style={styles.resultText} numberOfLines={1}>{place.name}</Text>
            <Text style={styles.resultSave}>{t("location.save")}</Text>
          </Pressable>
        ))}
      </GlassCard>

      <GlassCard style={{ gap: Spacing.sm }}>
        <Text style={styles.sectionTitle}>Saved locations ({saved.length})</Text>
        {saved.length === 0 && <Text style={styles.empty}>Save places to compare them in the Lab tab.</Text>}
        {saved.map((place) => (
          <View key={place.name} style={styles.savedRow}>
            <Pressable onPress={() => map.setCenter(place.lat, place.lon, 9)} style={{ flex: 1 }}>
              <Text style={styles.savedName} numberOfLines={1}>{place.name}</Text>
            </Pressable>
            <Pressable hitSlop={8} onPress={() => void useSavedLocationsStore.getState().remove(place)}>
              <Text style={styles.remove}>Remove</Text>
            </Pressable>
          </View>
        ))}
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
  title: {
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: "800",
  },
  mapCard: {
    padding: 6,
  },
  nativeNote: {
    height: 200,
    alignItems: "center",
    justifyContent: "center",
    padding: Spacing.lg,
  },
  nativeNoteText: {
    color: AppColors.textSecondary,
    fontSize: 12.5,
    textAlign: "center",
    lineHeight: 18,
  },
  layers: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Spacing.sm,
  },
  layerPill: {
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    backgroundColor: AppColors.glassFill,
  },
  layerActive: {
    backgroundColor: AppColors.accent,
    borderColor: AppColors.accent,
  },
  layerLabel: {
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: "600",
  },
  sectionTitle: {
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: "700",
  },
  input: {
    flex: 1,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    backgroundColor: AppColors.glassFill,
    color: AppColors.textPrimary,
    paddingHorizontal: Spacing.lg,
    paddingVertical: 9,
    fontSize: 13.5,
  },
  add: {
    borderRadius: Radius.pill,
    backgroundColor: AppColors.accent,
    paddingHorizontal: Spacing.lg,
    alignItems: "center",
    justifyContent: "center",
  },
  addLabel: {
    color: AppColors.bgPrimary,
    fontWeight: "700",
    fontSize: 13,
  },
  resultRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: 8,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: AppColors.borderSubtle,
  },
  resultText: {
    color: AppColors.textPrimary,
    fontSize: 13,
    flex: 1,
  },
  resultSave: {
    color: AppColors.accent,
    fontWeight: "700",
    fontSize: 12.5,
  },
  savedRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: 6,
  },
  savedName: {
    color: AppColors.textPrimary,
    fontSize: 13.5,
  },
  remove: {
    color: AppColors.statusRed,
    fontSize: 12,
  },
  empty: {
    color: AppColors.textTertiary,
    fontSize: 12.5,
  },
});
