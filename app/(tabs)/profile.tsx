import React, { useState } from "react";
import { View, Text, StyleSheet, Pressable, ScrollView, Switch } from "react-native";
import { MaterialCommunityIcons } from "@expo/vector-icons";
import { router } from "expo-router";

import { GlassCard } from "../../src/ui/components/GlassCard";
import { AppColors } from "../../src/ui/appColors";
import { Radius, Spacing } from "../../src/ui/theme";
import { TemperatureUnit, useSettingsStore } from "../../src/features/settings/settingsStore";
import { useDeveloperOptionsStore, DevSourcePin, DEV_SOURCE_PIN_LABEL } from "../../src/features/settings/developerOptionsStore";
import { SUPPORTED_LANGUAGES, LANGUAGE_META } from "../../src/i18n";
import { appModeFromName } from "../../src/core/models/appMode";

const PERSONAS = [
  { id: "everyone", label: "Everyone", icon: "account-outline" },
  { id: "farmer", label: "Farmer", icon: "sprout" },
  { id: "researcher", label: "Researcher", icon: "flask-outline" },
] as const;

export default function ProfileScreen(): React.ReactElement {
  const settings = useSettingsStore();
  const dev = useDeveloperOptionsStore();
  const [showDev, setShowDev] = useState(dev.enabled);

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.title}>Settings</Text>

      <GlassCard style={{ gap: Spacing.md }}>
        <Text style={styles.section}>LANGUAGE</Text>
        <View style={styles.pillWrap}>
          {SUPPORTED_LANGUAGES.map((code) => (
            <Pressable
              key={code}
              onPress={() => void settings.updateLanguage(code)}
              style={[styles.pill, settings.language === code && styles.pillActive]}
            >
              <Text style={[styles.pillLabel, settings.language === code && { color: AppColors.bgPrimary }]}>
                {LANGUAGE_META[code].native}
              </Text>
            </Pressable>
          ))}
        </View>
      </GlassCard>

      <GlassCard style={{ gap: Spacing.md }}>
        <Text style={styles.section}>EXPERIENCE</Text>
        <View style={styles.pillWrap}>
          {PERSONAS.map((persona) => (
            <Pressable
              key={persona.id}
              onPress={() => void settings.updatePersona(persona.id)}
              style={[styles.pill, settings.userPersona === persona.id && styles.pillActive]}
            >
              <MaterialCommunityIcons
                name={persona.icon}
                size={14}
                color={settings.userPersona === persona.id ? AppColors.bgPrimary : AppColors.textSecondary}
              />
              <Text style={[styles.pillLabel, settings.userPersona === persona.id && { color: AppColors.bgPrimary }]}>
                {persona.label}
              </Text>
            </Pressable>
          ))}
        </View>
        {settings.userPersona === "farmer" && (
          <Pressable onPress={() => router.push("/farm-profile")}>
            <Text style={styles.link}>Farm profile →</Text>
          </Pressable>
        )}
      </GlassCard>

      <GlassCard style={{ gap: Spacing.md }}>
        <Text style={styles.section}>UNITS</Text>
        <View style={styles.switchRow}>
          <Text style={styles.switchLabel}>Use Fahrenheit</Text>
          <Switch
            value={settings.units === TemperatureUnit.Fahrenheit}
            onValueChange={(v) => void settings.updateUnits(v ? TemperatureUnit.Fahrenheit : TemperatureUnit.Celsius)}
            trackColor={{ true: AppColors.accent, false: AppColors.borderStrong }}
            thumbColor={AppColors.textPrimary}
          />
        </View>
      </GlassCard>

      <GlassCard style={{ gap: Spacing.md }}>
        <Text style={styles.section}>VOICE</Text>
        <Text style={styles.note}>
          Speech speed {settings.ttsSpeed.toFixed(2)} · voice locale {settings.ttsVoiceLocale}
        </Text>
        <View style={styles.switchRow}>
          <Text style={styles.switchLabel}> slower</Text>
          <Pressable onPress={() => void settings.updateTtsSpeed(Math.max(0.3, settings.ttsSpeed - 0.05))}>
            <Text style={styles.link}>−</Text>
          </Pressable>
          <Pressable onPress={() => void settings.updateTtsSpeed(Math.min(1.0, settings.ttsSpeed + 0.05))}>
            <Text style={styles.link}>＋</Text>
          </Pressable>
        </View>
      </GlassCard>

      <GlassCard style={{ gap: Spacing.md }}>
        <View style={styles.switchRow}>
          <Text style={styles.section}>DEVELOPER</Text>
          <Switch
            value={dev.enabled}
            onValueChange={(v) => {
              void dev.patch({ enabled: v });
              setShowDev(v);
            }}
            trackColor={{ true: AppColors.accent, false: AppColors.borderStrong }}
            thumbColor={AppColors.textPrimary}
          />
        </View>
        {showDev && (
          <View style={{ gap: Spacing.md }}>
            <Pressable onPress={() => router.push("/debug")}>
              <Text style={styles.link}>Debug & state →</Text>
            </Pressable>
            <Text style={styles.note}>Source pin: {DEV_SOURCE_PIN_LABEL[dev.sourcePin]}</Text>
            <View style={styles.pillWrap}>
              {Object.values(DevSourcePin).map((pin) => (
                <Pressable key={pin} onPress={() => void dev.patch({ sourcePin: pin })} style={[styles.pill, dev.sourcePin === pin && styles.pillActive]}>
                  <Text style={[styles.pillLabel, dev.sourcePin === pin && { color: AppColors.bgPrimary }]}>{pin}</Text>
                </Pressable>
              ))}
            </View>
          </View>
        )}
      </GlassCard>

      <Text style={styles.footer}>WeatherGPT · keys stay on the server</Text>
      <Text style={styles.footer}>Mode: {appModeFromName(settings.userPersona) ?? "everyone (de-escalated)"} · language {settings.language}</Text>
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
  section: {
    color: AppColors.textTertiary,
    fontSize: 11,
    fontWeight: "700",
    letterSpacing: 1.2,
  },
  pillWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Spacing.sm,
  },
  pill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    paddingHorizontal: Spacing.md,
    paddingVertical: 7,
  },
  pillActive: {
    backgroundColor: AppColors.accent,
    borderColor: AppColors.accent,
  },
  pillLabel: {
    color: AppColors.textSecondary,
    fontSize: 12.5,
    fontWeight: "600",
  },
  switchRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  switchLabel: {
    color: AppColors.textPrimary,
    fontSize: 13.5,
  },
  link: {
    color: AppColors.accent,
    fontSize: 13.5,
    fontWeight: "600",
  },
  note: {
    color: AppColors.textTertiary,
    fontSize: 12,
  },
  footer: {
    color: AppColors.textTertiary,
    fontSize: 10.5,
    textAlign: "center",
  },
});
