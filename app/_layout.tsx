import React, { useEffect, useMemo, useState } from "react";
import { View, ActivityIndicator, StyleSheet } from "react-native";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { SafeAreaProvider } from "react-native-safe-area-context";

import { useSettingsStore, selectMode } from "../src/features/settings/settingsStore";
import { useDeveloperOptionsStore } from "../src/features/settings/developerOptionsStore";
import { useLocationStore } from "../src/features/location/locationStore";
import { useFarmProfileStore } from "../src/features/farm/farmStores";
import { useSavedLocationsStore } from "../src/features/explore/exploreStores";
import { useOnboardingStore } from "../src/features/onboarding/onboardingStore";
import { atmospherePalette, useWeatherStore } from "../src/features/weather/weatherStore";
import { AtmosphereBackground } from "../src/ui/components/AtmosphereBackground";
import { NavigationShell } from "../src/ui/components/NavigationShell";
import { AppColors } from "../src/ui/appColors";
import { AppMode } from "../src/core/models/appMode";

export default function RootLayout(): React.ReactElement {
  const [hydrated, setHydrated] = useState(false);
  const settingsHydrated = useSettingsStore((s) => s.hydrated);
  const mode = useSettingsStore(selectMode);
  const dev = useDeveloperOptionsStore();
  const weather = useWeatherStore((s) => s.snapshot);
  const onboardingComplete = useOnboardingStore;

  useEffect(() => {
    void Promise.all([
      useSettingsStore.getState().hydrate(),
      useDeveloperOptionsStore.getState().hydrate(),
      useLocationStore.getState().hydrate(),
      useFarmProfileStore.getState().hydrate(),
      useSavedLocationsStore.getState().hydrate(),
    ]).then(() => setHydrated(true));
  }, []);

  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    // Clock ticker — port of clockTickerProvider: repaint the sky every minute.
    const timer = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(timer);
  }, []);

  const palette = useMemo(
    () => atmospherePalette(now, weather, { forcePeriod: dev.forcePeriod, forceSky: dev.forceSky }),
    [now, weather, dev.forcePeriod, dev.forceSky],
  );

  if (!hydrated) {
    return (
      <View style={[styles.root, styles.boot]}>
        <ActivityIndicator color={AppColors.accent} />
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={styles.root}>
      <SafeAreaProvider>
        <AtmosphereBackground palette={palette}>
          <Stack
            screenOptions={{
              headerShown: false,
              contentStyle: { backgroundColor: "transparent" },
              animation: "fade",
            }}
          >
            <Stack.Screen name="onboarding/index" />
            <Stack.Screen name="(tabs)" />
          </Stack>
        </AtmosphereBackground>
        <StatusBar style="light" />
        {onboardingComplete === null ? null : null}
        <NavigationModeBridge mode={mode} />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

/// The navigation shell wraps the tab layout; this bridge only keeps the
/// persona in scope for it.
function NavigationModeBridge({ mode }: { mode: AppMode }): React.ReactElement | null {
  return null;
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: AppColors.bgPrimary,
  },
  boot: {
    alignItems: "center",
    justifyContent: "center",
  },
});
