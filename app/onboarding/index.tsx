import React, { useState } from "react";
import { View, Text, Pressable, StyleSheet, ScrollView } from "react-native";
import { router } from "expo-router";
import { MaterialCommunityIcons } from "@expo/vector-icons";

import { GlassCard } from "../../src/ui/components/GlassCard";
import { PrimaryButton, OutlinedPillButton } from "../../src/ui/components/Buttons";
import { AppColors } from "../../src/ui/appColors";
import { Radius, Spacing, TextStyles } from "../../src/ui/theme";
import { SUPPORTED_LANGUAGES, LANGUAGE_META, LanguageCode } from "../../src/i18n";
import { useOnboardingStore } from "../../src/features/onboarding/onboardingStore";
import { useSettingsStore } from "../../src/features/settings/settingsStore";
import { FARM_CROPS, GROWTH_STAGES, IRRIGATION_TYPES, SOIL_TYPES } from "../../src/features/farm/models/farmOptions";
import { FarmProfile } from "../../src/features/farm/models/farmProfile";
import { useFarmProfileStore } from "../../src/features/farm/farmStores";
import { useLocationStore } from "../../src/features/location/locationStore";
import { GeocodingService } from "../../src/core/services/geocodingService";

type Step = "splash" | "language" | "persona" | "farmChoice" | "farmDetails";

const PERSONAS: Array<{ id: string; label: string; description: string; icon: keyof typeof MaterialCommunityIcons.glyphMap }> = [
  { id: "everyone", label: "Everyone", description: "Current weather, forecasts and everyday information.", icon: "account-outline" },
  { id: "farmer", label: "Farmer", description: "Crop-specific advice, alerts and action windows.", icon: "sprout" },
  { id: "researcher", label: "Researcher", description: "Historical data, analysis and advanced insights.", icon: "flask-outline" },
];

export default function OnboardingScreen(): React.ReactElement {
  const [step, setStep] = useState<Step>("splash");
  const [farmDraft, setFarmDraft] = useState<FarmProfile>({
    location: "",
    crop: "Wheat",
    growthStage: "Flowering",
    farmSizeAcres: 4,
    irrigationType: "Borewell",
    soilType: "Loamy",
  });

  const onboarding = useOnboardingStore();
  const settings = useSettingsStore;

  async function finish(): Promise<void> {
    await onboarding.completeOnboarding();
    void useLocationStore.getState().maybeAutoLocate();
    router.replace("/(tabs)");
  }

  function skipFarm(): Promise<void> {
    return finish();
  }

  async function saveFarm(): Promise<void> {
    if (farmDraft.location.trim() === "" || !(farmDraft.farmSizeAcres > 0)) return;
    await useFarmProfileStore.getState().save(farmDraft);
    await finish();
  }

  async function useGps(): Promise<void> {
    const loc = await useLocationStore.getState().selectFromGps();
    if (loc !== null) setFarmDraft((d) => ({ ...d, location: loc.name }));
  }

  async function searchPlace(query: string): Promise<void> {
    setFarmDraft((d) => ({ ...d, location: query }));
    if (query.trim().length < 3) return;
    const match = await GeocodingService.search(query);
    if (match !== null) setFarmDraft((d) => ({ ...d, location: match.name }));
  }

  if (step === "splash") {
    return (
      <View style={styles.center}>
        <MaterialCommunityIcons name="weather-partly-snowy-rainy" size={72} color={AppColors.accent} />
        <Text style={styles.appName}>WeatherGPT</Text>
        <Text style={styles.tagline}>Real weather. Brighter tomorrows.</Text>
        <Text style={styles.footer}>Powered by real data.{"\n"}Built for India.</Text>
        <PrimaryButton label="Continue" onPress={() => setStep("language")} style={{ marginTop: Spacing.xxl, minWidth: 220 }} />
      </View>
    );
  }

  if (step === "language") {
    return (
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.heading}>Choose your language</Text>
        <Text style={styles.hint}>You can change this anytime.</Text>
        <View style={styles.wrap}>
          {SUPPORTED_LANGUAGES.map((code: LanguageCode) => {
            const meta = LANGUAGE_META[code];
            const selected = onboarding.selectedLanguage === code;
            return (
              <OutlinedPillButton
                key={code}
                label={`${meta.native}  ·  ${meta.english}`}
                selected={selected}
                onPress={() => onboarding.selectLanguage(code)}
                style={{ minWidth: "48%", flexGrow: 1 }}
              />
            );
          })}
        </View>
        <PrimaryButton label="Continue" onPress={() => setStep("persona")} style={{ marginTop: Spacing.xl }} />
      </ScrollView>
    );
  }

  if (step === "persona") {
    return (
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.heading}>What best describes you?</Text>
        <Text style={styles.hint}>Get a personalized experience.</Text>
        <View style={styles.wrap}>
          {PERSONAS.map((persona) => {
            const selected = onboarding.selectedPersona === persona.id;
            return (
              <Pressable key={persona.id} onPress={() => onboarding.selectPersona(persona.id)}>
                <GlassCard strong style={[styles.personaCard, selected && { borderColor: AppColors.accent }]}>
                  <MaterialCommunityIcons name={persona.icon} size={26} color={selected ? AppColors.accent : AppColors.textSecondary} />
                  <Text style={styles.personaTitle}>{persona.label}</Text>
                  <Text style={styles.personaBody}>{persona.description}</Text>
                </GlassCard>
              </Pressable>
            );
          })}
        </View>
        {onboarding.selectedPersona === "farmer" ? (
          <PrimaryButton label="Continue" onPress={() => setStep("farmChoice")} style={{ marginTop: Spacing.lg }} />
        ) : (
          <PrimaryButton label="Continue" onPress={skipFarm} style={{ marginTop: Spacing.lg }} />
        )}
        <Pressable onPress={skipFarm}>
          <Text style={styles.skip}>Skip for now</Text>
        </Pressable>
      </ScrollView>
    );
  }

  if (step === "farmChoice") {
    return (
      <View style={styles.center}>
        <Text style={styles.heading}>Tell us about your farm</Text>
        <Text style={styles.hint}>Crop advice is tuned to your field.</Text>
        <PrimaryButton label="Type it myself" onPress={() => setStep("farmDetails")} style={{ minWidth: 240, marginTop: Spacing.lg }} />
        <Text style={styles.hintSmall}>
          (Voice onboarding needs the native speech module — unavailable in this build.)
        </Text>
        <Pressable onPress={skipFarm}>
          <Text style={styles.skip}>Skip for now</Text>
        </Pressable>
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.heading}>Tell us about your farm</Text>
      <Text style={styles.hint}>Crop advice is tuned to these details.</Text>
      <GlassCard style={{ gap: Spacing.md, marginTop: Spacing.lg }}>
        <Field label="Location (village or city)" value={farmDraft.location} onChangeText={searchPlace} />
        <Field label="Farm size (acres)" value={String(farmDraft.farmSizeAcres)} keyboardType="numbers-and-punctuation" onChangeText={(v) => setFarmDraft((d) => ({ ...d, farmSizeAcres: Number(v) || 0 }))} />
        <PickerRow
          label="Crop"
          options={[...FARM_CROPS]}
          value={farmDraft.crop}
          onSelect={(crop) => setFarmDraft((d) => ({ ...d, crop }))}
        />
        <PickerRow
          label="Growth stage"
          options={[...GROWTH_STAGES]}
          value={farmDraft.growthStage}
          onSelect={(growthStage) => setFarmDraft((d) => ({ ...d, growthStage }))}
        />
        <PickerRow
          label="Irrigation"
          options={[...IRRIGATION_TYPES]}
          value={farmDraft.irrigationType}
          onSelect={(irrigationType) => setFarmDraft((d) => ({ ...d, irrigationType }))}
        />
        <PickerRow
          label="Soil"
          options={[...SOIL_TYPES]}
          value={farmDraft.soilType}
          onSelect={(soilType) => setFarmDraft((d) => ({ ...d, soilType }))}
        />
      </GlassCard>
      <PrimaryButton label="Save and continue" onPress={saveFarm} style={{ marginTop: Spacing.lg }} />
      <Pressable onPress={skipFarm}>
        <Text style={styles.skip}>Skip for now</Text>
      </Pressable>
    </ScrollView>
  );
}

function Field(props: { label: string; value: string; onChangeText: (v: string) => void; keyboardType?: "default" | "numbers-and-punctuation" }): React.ReactElement {
  const [focused, setFocused] = useState(false);
  return (
    <View style={{ gap: 4 }}>
      <Text style={styles.fieldLabel}>{props.label}</Text>
      <TextInput
        value={props.value}
        onChangeText={props.onChangeText}
        keyboardType={props.keyboardType}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={[styles.input, focused && { borderColor: AppColors.accent }]}
        placeholderTextColor={AppColors.textTertiary}
      />
    </View>
  );
}

import { TextInput } from "react-native";

function PickerRow(props: { label: string; options: string[]; value: string; onSelect: (v: string) => void }): React.ReactElement {
  return (
    <View style={{ gap: 6 }}>
      <Text style={styles.fieldLabel}>{props.label}</Text>
      <View style={{ flexDirection: "row", flexWrap: "wrap", gap: Spacing.sm }}>
        {props.options.map((option) => (
          <OutlinedPillButton
            key={option}
            label={option}
            selected={props.value === option}
            onPress={() => props.onSelect(option)}
            style={{ paddingVertical: 6, paddingHorizontal: 12 }}
          />
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: Spacing.xl,
    gap: Spacing.sm,
  },
  scroll: {
    padding: Spacing.xl,
    paddingBottom: Spacing.xxl * 2,
    gap: Spacing.sm,
  },
  wrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Spacing.md,
    marginTop: Spacing.md,
  },
  appName: {
    fontSize: 34,
    fontWeight: "800",
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  },
  tagline: {
    ...TextStyles.body,
    fontSize: 15,
  },
  footer: {
    ...TextStyles.tiny,
    textAlign: "center",
    lineHeight: 16,
  },
  heading: {
    fontSize: 24,
    fontWeight: "800",
    color: AppColors.textPrimary,
  },
  hint: {
    ...TextStyles.body,
    marginTop: 2,
  },
  hintSmall: {
    ...TextStyles.tiny,
    textAlign: "center",
    marginTop: Spacing.md,
  },
  personaCard: {
    width: 260,
    gap: Spacing.xs + 2,
  },
  personaTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: AppColors.textPrimary,
  },
  personaBody: {
    ...TextStyles.small,
    lineHeight: 17,
  },
  skip: {
    ...TextStyles.small,
    textAlign: "center",
    marginTop: Spacing.lg,
    textDecorationLine: "underline",
  },
  fieldLabel: {
    fontSize: 11,
    fontWeight: "700",
    letterSpacing: 0.8,
    color: AppColors.textTertiary,
    textTransform: "uppercase",
  },
  input: {
    borderRadius: Radius.sm,
    borderWidth: 1,
    borderColor: AppColors.borderSubtle,
    backgroundColor: AppColors.glassFill,
    color: AppColors.textPrimary,
    paddingHorizontal: Spacing.md,
    paddingVertical: 10,
    fontSize: 14,
  },
});
