import React from "react";
import { ScrollView, StyleSheet, View } from "react-native";

import { AppText, Button, Card, Colors, Icon, Space } from "../../../ui";
import { RichText } from "../../../ui/content/RichText";
import { useTranslation } from "../../../i18n/useTranslation";
import { useVoiceStore, VoiceStatus } from "../../voice/voiceStore";
import { InsightCard } from "./InsightCard";

/// Live voice session: listening → processing → answer, with a single
/// dismiss action. Sits above the composer.
export function VoicePanel(): React.ReactElement | null {
  const t = useTranslation();
  const status = useVoiceStore((s) => s.status);
  const transcript = useVoiceStore((s) => s.transcript);
  const response = useVoiceStore((s) => s.response);
  const errorMessage = useVoiceStore((s) => s.errorMessage);

  if (status === VoiceStatus.Idle) return null;

  const listening = status === VoiceStatus.Listening;
  const processing = status === VoiceStatus.Processing;
  const title = listening ? t("voice.listening") : processing ? t("voice.finding_answer") : status === VoiceStatus.Error ? t("voice.error") : t("voice.result_title");

  return (
    <Card strong style={styles.card}>
      <View style={styles.header}>
        <View style={[styles.pulse, { backgroundColor: status === VoiceStatus.Error ? Colors.danger : Colors.accent }]}>
          <Icon name={status === VoiceStatus.Error ? "microphone-off" : "microphone"} size={16} color={Colors.onAccent} />
        </View>
        <AppText variant="headline" style={styles.flex} accessibilityLiveRegion="polite">
          {title}
        </AppText>
        <Button
          label={status === VoiceStatus.Speaking ? t("voice_picker.stop") : t("location.cancel")}
          variant="ghost"
          onPress={() => (status === VoiceStatus.Speaking ? useVoiceStore.getState().stopSpeaking() : useVoiceStore.getState().cancel())}
        />
      </View>
      <ScrollView style={styles.body} contentContainerStyle={styles.bodyContent}>
        {transcript !== "" && (
          <AppText variant="callout" tone="secondary">
            “{transcript}”
          </AppText>
        )}
        {listening && transcript === "" && (
          <AppText variant="subhead" tone="tertiary">
            {t("voice.speak_now")}
          </AppText>
        )}
        {errorMessage !== null && (
          <AppText variant="subhead" tone="danger">
            {errorMessage}
          </AppText>
        )}
        {response !== null && (
          <>
            {(response.stats.length > 0 || response.forecast.length > 0) && (
              <InsightCard insight={{ label: response.label, verdict: response.verdict, accent: response.accent, stats: response.stats, forecast: response.forecast, confidence: null, source: null }} />
            )}
            <RichText content={response.explanation} />
            <Button label={t("chat.read_aloud")} icon="volume-high" variant="secondary" onPress={() => void useVoiceStore.getState().speak(response.explanation)} />
          </>
        )}
      </ScrollView>
    </Card>
  );
}

const styles = StyleSheet.create({
  card: {
    gap: Space.sm,
    paddingVertical: Space.md,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    gap: Space.md,
  },
  flex: {
    flex: 1,
  },
  pulse: {
    width: 30,
    height: 30,
    borderRadius: 15,
    alignItems: "center",
    justifyContent: "center",
  },
  body: {
    maxHeight: 260,
  },
  bodyContent: {
    gap: Space.md,
  },
});
