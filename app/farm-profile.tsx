import { useTranslation } from "../src/i18n/useTranslation";
import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet, ScrollView, TextInput, Alert } from "react-native";

import { GlassCard } from "../src/ui/components/GlassCard";
import { PrimaryButton } from "../src/ui/components/Buttons";
import { AppColors } from "../src/ui/appColors";
import { Radius, Spacing } from "../src/ui/theme";
import { useFarmProfileStore } from "../src/features/farm/farmStores";
import { FarmProfile } from "../src/features/farm/models/farmProfile";
import { FARM_CROPS, GROWTH_STAGES, IRRIGATION_TYPES, SOIL_TYPES, withCurrentOption } from "../src/features/farm/models/farmOptions";
import { useLocationStore } from "../src/features/location/locationStore";

export default function FarmProfileScreen(): React.ReactElement {
  const t = useTranslation();
  const stored = useFarmProfileStore((s) => s.profile);
  const [draft, setDraft] = useState<FarmProfile>(stored);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    setDraft(stored);
  }, [stored]);

  async function save(): Promise<void> {
    if (draft.location.trim() === "" || !(draft.farmSizeAcres > 0)) return;
    try {
      await useFarmProfileStore.getState().save(draft);
      setSaved(true);
    } catch (error) {
      Alert.alert("Could not save farm", error instanceof Error ? error.message : "Please try again.");
    }
  }

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.title}>{t("farmer.farm_profile")}</Text>
      <GlassCard style={{ gap: Spacing.lg }}>
        <Field label={t("farmer.location")} value={draft.location} onChangeText={(location) => setDraft((d) => ({ ...d, location }))} />
        <Field
          label="Farm size (acres)"
          value={String(draft.farmSizeAcres)}
          keyboardType="numbers-and-punctuation"
          onChangeText={(v) => setDraft((d) => ({ ...d, farmSizeAcres: Number(v) || 0 }))}
        />
        <PickerRow label={t("farmer.crop")} options={withCurrentOption(FARM_CROPS, draft.crop)} value={draft.crop} onSelect={(crop) => setDraft((d) => ({ ...d, crop }))} />
        <PickerRow label="Growth stage" options={withCurrentOption(GROWTH_STAGES, draft.growthStage)} value={draft.growthStage} onSelect={(growthStage) => setDraft((d) => ({ ...d, growthStage }))} />
        <PickerRow label={t("farmer.irrigation")} options={withCurrentOption(IRRIGATION_TYPES, draft.irrigationType)} value={draft.irrigationType} onSelect={(irrigationType) => setDraft((d) => ({ ...d, irrigationType }))} />
        <PickerRow label="Soil" options={withCurrentOption(SOIL_TYPES, draft.soilType)} value={draft.soilType} onSelect={(soilType) => setDraft((d) => ({ ...d, soilType }))} />
      </GlassCard>
      <PrimaryButton label={saved ? "Saved ✓" : "Save changes"} onPress={save} variant={saved ? "white" : "accent"} />
      <Text style={styles.hint}>These wire values are sent verbatim to /advisory and /chat farm context.</Text>
    </ScrollView>
  );
}

function Field(props: { label: string; value: string; onChangeText: (v: string) => void; keyboardType?: "default" | "numbers-and-punctuation" }): React.ReactElement {
  return (
    <View style={{ gap: 5 }}>
      <Text style={styles.fieldLabel}>{props.label}</Text>
      <TextInput
        value={props.value}
        onChangeText={props.onChangeText}
        keyboardType={props.keyboardType}
        style={styles.input}
        placeholderTextColor={AppColors.textTertiary}
      />
    </View>
  );
}

function PickerRow(props: { label: string; options: string[]; value: string; onSelect: (v: string) => void }): React.ReactElement {
  return (
    <View style={{ gap: 6 }}>
      <Text style={styles.fieldLabel}>{props.label}</Text>
      <View style={styles.pillWrap}>
        {props.options.map((option) => (
          <Pressable
            key={option}
            onPress={() => props.onSelect(option)}
            style={[styles.pill, props.value === option && styles.pillActive]}
          >
            <Text style={[styles.pillLabel, props.value === option && { color: AppColors.bgPrimary }]}>{option}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

import { Pressable } from "react-native";

const styles = StyleSheet.create({
  scroll: {
    padding: Spacing.lg,
    paddingBottom: 80,
    gap: Spacing.lg,
  },
  title: {
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: "800",
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
  pillWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Spacing.sm,
  },
  pill: {
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
  },
  pillActive: {
    backgroundColor: AppColors.accent,
    borderColor: AppColors.accent,
  },
  pillLabel: {
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: "600",
  },
  hint: {
    color: AppColors.textTertiary,
    fontSize: 10.5,
    textAlign: "center",
  },
});
