import React, { useEffect, useRef, useState } from "react";
import { View, Text, StyleSheet, FlatList, Pressable, TextInput, KeyboardAvoidingView, Platform } from "react-native";
import { MaterialCommunityIcons } from "@expo/vector-icons";
import * as Clipboard from "expo-clipboard";

import { GlassCard } from "../../src/ui/components/GlassCard";
import { RichText } from "../../src/ui/components/RichText";
import { AppColors } from "../../src/ui/appColors";
import { Radius, Spacing } from "../../src/ui/theme";
import { useChatStore, ChatMessage } from "../../src/features/chat/chatStore";
import { useSettingsStore } from "../../src/features/settings/settingsStore";
import { useVoiceStore } from "../../src/features/voice/voiceStore";
import { MarkdownUtils } from "../../src/core/utils/markdownUtils";
import { voiceCardFromJson } from "../../src/features/voice/models/voiceCard";

export default function ChatScreen(): React.ReactElement {
  const { messages, sending, error, send, retryLast, clear } = useChatStore();
  const settings = useSettingsStore();
  const [draft, setDraft] = useState("");
  const listRef = useRef<FlatList<ChatMessage>>(null);

  useEffect(() => {
    // Keep chat context in sync with settings/location/profile.
    const voice = useVoiceStore.getState();
    voice.setContext({
      ...voice.context,
      language: settings.language,
      userPersona: settings.userPersona,
      ttsVoiceLocale: settings.ttsVoiceLocale,
      ttsSpeed: settings.ttsSpeed,
    });
  }, [settings.language, settings.userPersona, settings.ttsVoiceLocale, settings.ttsSpeed]);

  function submit(): void {
    const text = draft.trim();
    if (text === "" || sending) return;
    setDraft("");
    void send(text);
  }

  return (
    <KeyboardAvoidingView style={styles.root} behavior={Platform.select({ ios: "padding" })}>
      <View style={styles.header}>
        <MaterialCommunityIcons name="chat-outline" size={20} color={AppColors.accent} />
        <Text style={styles.title}>WeatherGPT Chat</Text>
        <Pressable onPress={clear} hitSlop={8}>
          <MaterialCommunityIcons name="pencil-plus" size={18} color={AppColors.textTertiary} />
        </Pressable>
      </View>

      {messages.length === 0 ? (
        <View style={styles.empty}>
          <MaterialCommunityIcons name="weather-sunset" size={44} color={AppColors.accent} />
          <Text style={styles.emptyTitle}>Ask me anything about the sky</Text>
          <Text style={styles.emptyBody}>Forecasts, tables and advice — answered in your language.</Text>
        </View>
      ) : (
        <FlatList
          ref={listRef}
          data={messages}
          keyExtractor={(_, i) => String(i)}
          contentContainerStyle={styles.list}
          onContentSizeChange={() => listRef.current?.scrollToEnd({ animated: true })}
          renderItem={({ item }) => <MessageBubble message={item} />}
        />
      )}

      {sending && (
        <View style={styles.typing}>
          <Text style={styles.typingText}>Thinking…</Text>
        </View>
      )}

      {error !== null && (
        <GlassCard style={styles.errorCard}>
          <Text style={styles.errorText}>{error}</Text>
          <Pressable onPress={() => void retryLast()}>
            <Text style={styles.retry}>Retry</Text>
          </Pressable>
        </GlassCard>
      )}

      <View style={styles.inputRow}>
        <Pressable
          style={styles.mic}
          onPress={() => {
            const voice = useVoiceStore.getState();
            void voice.startListening();
          }}
        >
          <MaterialCommunityIcons name="microphone" size={20} color={AppColors.accent} />
        </Pressable>
        <TextInput
          value={draft}
          onChangeText={setDraft}
          onSubmitEditing={submit}
          returnKeyType="send"
          placeholder="Ask WeatherGPT anything…"
          placeholderTextColor={AppColors.textTertiary}
          style={styles.input}
          multiline
        />
        <Pressable style={styles.send} onPress={submit} disabled={sending}>
          <MaterialCommunityIcons name="send" size={18} color={sending ? AppColors.textTertiary : AppColors.bgPrimary} />
        </Pressable>
      </View>
    </KeyboardAvoidingView>
  );
}

function MessageBubble({ message }: { message: ChatMessage }): React.ReactElement {
  const isUser = message.role === "user";
  const card = !isUser && message.card !== null ? voiceCardFromJson(message.card) : null;
  return (
    <View style={[styles.bubbleRow, isUser && { justifyContent: "flex-end" }]}>
      <View style={[styles.bubble, isUser ? styles.bubbleUser : styles.bubbleAssistant]}>
        {!isUser && message.meta !== null && (
          <Text style={styles.meta}>
            {typeof message.meta?.["intent_engine"] === "string" ? `routing: ${String(message.meta["intent_engine"])}` : ""}
          </Text>
        )}
        {card !== null && card.verdict !== null && (
          <View style={styles.card}>
            <Text style={styles.cardVerdict}>{card.verdict}</Text>
            {card.stats.map((stat) => (
              <View key={stat.label} style={styles.statRow}>
                <Text style={styles.statLabel}>{stat.label}</Text>
                <Text style={[styles.statValue, { color: toneColor(stat.tone) }]}>{stat.value}</Text>
              </View>
            ))}
          </View>
        )}
        <RichText content={message.content} />
        {!isUser && (
          <Pressable
            hitSlop={6}
            onPress={() => {
              void Clipboard.setStringAsync(message.content);
              void useVoiceStore.getState().speak(MarkdownUtils.spokenSummary("", message.content));
            }}
            style={{ marginTop: 6 }}
          >
            <MaterialCommunityIcons name="volume-high" size={16} color={AppColors.textTertiary} />
          </Pressable>
        )}
      </View>
    </View>
  );
}

import { CardTone } from "../../src/features/voice/models/voiceCard";

function toneColor(tone: CardTone): string {
  switch (tone) {
    case CardTone.Good:
      return AppColors.statusGreenText;
    case CardTone.Caution:
      return AppColors.statusAmber;
    case CardTone.Avoid:
      return AppColors.statusRed;
    default:
      return AppColors.researcherBlue;
  }
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.xl,
    paddingBottom: Spacing.sm,
  },
  title: {
    flex: 1,
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: "700",
  },
  empty: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    gap: Spacing.sm,
    padding: Spacing.xl,
  },
  emptyTitle: {
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: "700",
  },
  emptyBody: {
    color: AppColors.textSecondary,
    fontSize: 13,
    textAlign: "center",
  },
  list: {
    padding: Spacing.lg,
    gap: Spacing.md,
  },
  bubbleRow: {
    flexDirection: "row",
  },
  bubble: {
    maxWidth: "88%",
    borderRadius: Radius.lg,
    padding: Spacing.md,
  },
  bubbleUser: {
    backgroundColor: AppColors.accent,
    borderBottomRightRadius: 4,
  },
  bubbleAssistant: {
    backgroundColor: AppColors.glassFillStrong,
    borderColor: AppColors.glassBorder,
    borderWidth: StyleSheet.hairlineWidth,
    borderBottomLeftRadius: 4,
  },
  meta: {
    color: AppColors.textTertiary,
    fontSize: 9.5,
    marginBottom: 4,
    textTransform: "uppercase",
    letterSpacing: 0.6,
  },
  card: {
    borderRadius: Radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: AppColors.glassBorderStrong,
    backgroundColor: AppColors.glassFill,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
    gap: 4,
  },
  cardVerdict: {
    color: AppColors.textPrimary,
    fontWeight: "700",
    fontSize: 14,
    marginBottom: 2,
  },
  statRow: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  statLabel: {
    color: AppColors.textSecondary,
    fontSize: 12,
  },
  statValue: {
    color: AppColors.textPrimary,
    fontSize: 12.5,
    fontWeight: "700",
  },
  typing: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.xs,
  },
  typingText: {
    color: AppColors.textTertiary,
    fontSize: 12,
    fontStyle: "italic",
  },
  errorCard: {
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.sm,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: Spacing.sm,
  },
  errorText: {
    color: AppColors.statusRed,
    fontSize: 12.5,
    flex: 1,
  },
  retry: {
    color: AppColors.accent,
    fontWeight: "700",
    fontSize: 13,
    paddingHorizontal: Spacing.md,
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: Spacing.sm,
    padding: Spacing.lg,
  },
  mic: {
    width: 42,
    height: 42,
    borderRadius: 21,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    backgroundColor: AppColors.glassFill,
    alignItems: "center",
    justifyContent: "center",
  },
  input: {
    flex: 1,
    minHeight: 42,
    maxHeight: 110,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: AppColors.glassBorderStrong,
    backgroundColor: AppColors.glassFill,
    color: AppColors.textPrimary,
    paddingHorizontal: Spacing.lg,
    paddingTop: 11,
    fontSize: 14,
  },
  send: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: AppColors.accent,
    alignItems: "center",
    justifyContent: "center",
  },
});
