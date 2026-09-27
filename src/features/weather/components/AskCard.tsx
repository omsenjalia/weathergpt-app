import React from "react";
import { ScrollView, StyleSheet, View } from "react-native";
import { router } from "expo-router";

import { AppText, Card, Colors, Icon, Radius, Space, Touchable } from "../../../ui";
import { useTranslation } from "../../../i18n/useTranslation";
import { AppMode } from "../../../core/models/appMode";

/// Entry point into the assistant: a search-style bar plus persona-specific
/// suggested questions that open Chat pre-filled and sent.
export function AskCard({ mode }: { mode: AppMode }): React.ReactElement {
  const t = useTranslation();
  const prefix = mode === "farmer" ? "home.farmer" : mode === "researcher" ? "home.researcher" : "home.everyone";
  const prompts = [1, 2, 3].map((n) => t(`${prefix}_prompt_${n}`));

  const open = (q?: string) => router.push(q === undefined ? "/chat" : { pathname: "/chat", params: { q } });

  return (
    <Card padded={false} style={styles.card}>
      <Touchable onPress={() => open()} haptics="light" accessibilityLabel={t(`${prefix}_hint`)} style={styles.bar}>
        <View style={styles.spark}>
          <Icon name="creation" size={18} color={Colors.onAccent} />
        </View>
        <AppText variant="callout" tone="secondary" style={styles.flex} numberOfLines={1}>
          {t(`${prefix}_hint`)}
        </AppText>
        <Icon name="microphone-outline" size={20} color={Colors.textSecondary} />
      </Touchable>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.prompts}>
        {prompts.map((prompt) => (
          <Touchable key={prompt} onPress={() => open(prompt)} haptics="selection" accessibilityLabel={prompt} style={styles.prompt}>
            <AppText variant="footnote" numberOfLines={1}>
              {prompt}
            </AppText>
          </Touchable>
        ))}
      </ScrollView>
    </Card>
  );
}

const styles = StyleSheet.create({
  card: {
    paddingVertical: Space.md,
    gap: Space.md,
  },
  flex: {
    flex: 1,
  },
  bar: {
    flexDirection: "row",
    alignItems: "center",
    gap: Space.md,
    marginHorizontal: Space.md,
    minHeight: 48,
    paddingLeft: 6,
    paddingRight: Space.md,
    borderRadius: Radius.pill,
    backgroundColor: Colors.surfaceInset,
  },
  spark: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.accent,
    alignItems: "center",
    justifyContent: "center",
  },
  prompts: {
    gap: Space.sm,
    paddingHorizontal: Space.md,
  },
  prompt: {
    minHeight: 36,
    justifyContent: "center",
    paddingHorizontal: 14,
    borderRadius: Radius.pill,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: Colors.hairlineStrong,
  },
});
