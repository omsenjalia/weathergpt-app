import React, { useEffect, useMemo, useState } from "react";
import { View, ActivityIndicator, StyleSheet } from "react-native";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

import { useSettingsStore, selectMode } from "../src/features/settings/settingsStore";
import { useDeveloperOptionsStore } from "../src/features/settings/developerOptionsStore";
import { useLocationStore } from "../src/features/location/locationStore";
import { useFarmProfileStore } from "../src/features/farm/farmStores";
import { useSavedLocationsStore } from "../src/features/explore/exploreStores";
import { useChatStore } from "../src/features/chat/chatStore";
import { useVoiceStore } from "../src/features/voice/voiceStore";
import { atmospherePalette, useWeatherStore } from "../src/features/weather/weatherStore";
import { AtmosphereBackground } from "../src/ui/components/AtmosphereBackground";
import { AppColors } from "../src/ui/appColors";

export default function RootLayout(): React.ReactElement {
  const [hydrated, setHydrated] = useState(false);
  const settings = useSettingsStore();
  const location = useLocationStore((s) => s.location);
  const profileCompleted = useFarmProfileStore((s) => s.completed);
  const profile = useFarmProfileStore((s) => s.profile);
  const dev = useDeveloperOptionsStore();
  const weather = useWeatherStore((s) => s.snapshot);
  useEffect(() => {
    if (!hydrated) return;
    const context = { language: settings.language, userPersona: selectMode(settings), location, profile, profileCompleted };
    useChatStore.getState().setContext(context);
    useVoiceStore.getState().setContext({ ...context, ttsVoiceLocale: settings.ttsVoiceLocale, ttsSpeed: settings.ttsSpeed });
  }, [hydrated, settings.language, settings.userPersona, settings.ttsVoiceLocale, settings.ttsSpeed, location, profile, profileCompleted]);

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
          <SafeAreaView style={styles.fill}>
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
          </SafeAreaView>
        </AtmosphereBackground>
        <StatusBar style="light" />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  root: {
    flex: 1,
    backgroundColor: AppColors.bgPrimary,
  },
  boot: {
    alignItems: "center",
    justifyContent: "center",
  },
});
