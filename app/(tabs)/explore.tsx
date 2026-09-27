import React, { useEffect, useState } from "react";
import { Platform, StyleSheet, useWindowDimensions, View } from "react-native";
import { WebView } from "react-native-webview";
import { router } from "expo-router";

import { Card, CardHeader, ChipGroup, Chip, Colors, IconButton, Radius, Screen, Section, Space, StateView } from "../../src/ui";
import { useTranslation } from "../../src/i18n/useTranslation";
import { MAP_ALL_LAYERS, MapLayer, useMapStore, useSavedLocationsStore, windyEmbedUrl } from "../../src/features/explore/exploreStores";
import { useLocationStore } from "../../src/features/location/locationStore";

const LAYER_KEY: Record<MapLayer, string> = {
  [MapLayer.Wind]: "map.layer_wind",
  [MapLayer.Rain]: "map.layer_rain",
  [MapLayer.Temp]: "map.layer_temp",
  [MapLayer.Clouds]: "map.layer_clouds",
  [MapLayer.Radar]: "map.layer_radar",
  [MapLayer.Waves]: "map.layer_waves",
  [MapLayer.Pressure]: "map.layer_pressure",
  [MapLayer.Thunder]: "map.layer_thunder",
  [MapLayer.Snow]: "map.layer_snow",
  [MapLayer.Humidity]: "map.layer_humidity",
  [MapLayer.Cape]: "map.layer_cape",
};

export default function ExploreScreen(): React.ReactElement {
  const t = useTranslation();
  const { height } = useWindowDimensions();
  const activeLayer = useMapStore((s) => s.activeLayer);
  const mapState = useMapStore();
  const saved = useSavedLocationsStore((s) => s.locations);
  const current = useLocationStore((s) => s.location);
  const [focus, setFocus] = useState<string>(current.name);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    useMapStore.getState().setCenter(current.lat, current.lon, 7);
    setFocus(current.name);
  }, [current.lat, current.lon, current.name]);

  const url = windyEmbedUrl(mapState);
  const mapHeight = Math.round(Math.min(Math.max(height * 0.52, 320), 560));

  return (
    <Screen inTabs title={t("map.title")}>
      <Card padded={false} style={[styles.mapCard, { height: mapHeight }]}>
        {failed ? (
          <StateView icon="map-marker-off-outline" tone="error" title={t("map.unavailable")} actionLabel={t("chat.retry")} onAction={() => setFailed(false)} />
        ) : Platform.OS === "web" ? (
          <iframe src={url} title={t("map.title")} style={{ width: "100%", height: "100%", border: "none" }} />
        ) : (
          <WebView
            source={{ uri: url }}
            style={styles.web}
            originWhitelist={["https://*"]}
            mixedContentMode="never"
            startInLoadingState
            onError={() => setFailed(true)}
            onHttpError={() => setFailed(true)}
          />
        )}
      </Card>

      <ChipGroup
        layout="scroll"
        options={MAP_ALL_LAYERS}
        value={activeLayer}
        onChange={(layer) => useMapStore.getState().setLayer(layer)}
        labelFor={(layer) => t(LAYER_KEY[layer])}
      />

      <Section title={t("settings.saved_locations")}>
        <Card>
          <CardHeader
            icon="star-outline"
            title={t("home.choose_location")}
            trailing={<IconButton icon="pencil-outline" size={32} accessibilityLabel={t("home.choose_location")} onPress={() => router.push("/locations")} color={Colors.textSecondary} />}
          />
          <View style={styles.places}>
            <Chip
              icon="crosshairs-gps"
              label={current.name.split(",")[0]!}
              selected={focus === current.name}
              onPress={() => {
                setFocus(current.name);
                useMapStore.getState().setCenter(current.lat, current.lon, 8);
              }}
            />
            {saved
              .filter((p) => p.name !== current.name)
              .map((place) => (
                <Chip
                  key={place.name}
                  icon="star"
                  label={place.name.split(",")[0]!}
                  selected={focus === place.name}
                  onPress={() => {
                    setFocus(place.name);
                    useMapStore.getState().setCenter(place.lat, place.lon, 8);
                  }}
                />
              ))}
          </View>
        </Card>
      </Section>
    </Screen>
  );
}

const styles = StyleSheet.create({
  mapCard: {
    borderRadius: Radius.xl,
  },
  web: {
    flex: 1,
    backgroundColor: "transparent",
  },
  places: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Space.sm,
  },
});
