import React, { useCallback, useEffect, useRef } from "react";
import { FlatList, StyleSheet, View } from "react-native";
import { router, useFocusEffect, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { AppText, Colors, Icon, IconButton, InlineBanner, Layout, Screen, Space, Touchable } from "../../src/ui";
import { useKeyboardVisible } from "../../src/ui/shell/useKeyboardVisible";
import { useTranslation } from "../../src/i18n/useTranslation";
import { ChatMessage, useChatStore } from "../../src/features/chat/chatStore";
import { useVoiceStore, VoiceStatus } from "../../src/features/voice/voiceStore";
import { useSettingsStore, selectMode } from "../../src/features/settings/settingsStore";
import { MessageItem, TypingIndicator } from "../../src/features/chat/components/MessageItem";
import { Composer } from "../../src/features/chat/components/Composer";
import { VoicePanel } from "../../src/features/chat/components/VoicePanel";

export default function ChatScreen(): React.ReactElement {
  const t = useTranslation();
  const insets = useSafeAreaInsets();
  const keyboard = useKeyboardVisible();
  const messages = useChatStore((s) => s.messages);
  const sending = useChatStore((s) => s.sending);
  const error = useChatStore((s) => s.error);
  const voiceStatus = useVoiceStore((s) => s.status);
  const listRef = useRef<FlatList<ChatMessage>>(null);

  // Questions handed over from Home arrive as ?q=… and are sent once.
  const { q } = useLocalSearchParams<{ q?: string }>();
  useEffect(() => {
    if (typeof q !== "string" || q.trim() === "") return;
    void useChatStore.getState().send(q);
    router.setParams({ q: undefined });
  }, [q]);

  // Leaving the tab stops any live recognition or speech (tabs stay mounted,
  // so this runs on blur rather than unmount).
  useFocusEffect(useCallback(() => () => useVoiceStore.getState().cancel(), []));

  const newConversation = () => {
    useChatStore.getState().clear();
    useVoiceStore.getState().cancel();
  };

  const toggleMic = () => {
    const voice = useVoiceStore.getState();
    if (voice.status === VoiceStatus.Listening) void voice.stopListening();
    else void voice.startListening();
  };

  const bottom = keyboard ? Space.sm : Layout.tabBarHeight + 8 + Math.max(insets.bottom, Space.md) + Space.md;

  return (
    <Screen
      scroll={false}
      keyboardAware
      title={t("common.weather_gpt")}
      trailing={
        messages.length > 0 ? <IconButton icon="square-edit-outline" variant="filled" accessibilityLabel={t("chat.new_conversation")} onPress={newConversation} /> : undefined
      }
    >
      {messages.length === 0 && !sending ? (
        <EmptyChat />
      ) : (
        <FlatList
          ref={listRef}
          data={messages}
          keyExtractor={(item, index) => `${index}-${item.at.getTime()}`}
          renderItem={({ item }) => <MessageItem message={item} />}
          contentContainerStyle={styles.list}
          onContentSizeChange={() => listRef.current?.scrollToEnd({ animated: true })}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode="interactive"
          ListFooterComponent={sending ? <TypingIndicator label={t("chat.thinking")} /> : null}
        />
      )}

      <View style={[styles.dock, { paddingBottom: bottom }]}>
        {error !== null && <InlineBanner tone="error" message={error} actionLabel={t("chat.retry")} onAction={() => void useChatStore.getState().retryLast()} />}
        <VoicePanel />
        <Composer
          placeholder={t("chat.hint")}
          sending={sending}
          listening={voiceStatus === VoiceStatus.Listening}
          onSend={(text) => void useChatStore.getState().send(text)}
          onMic={toggleMic}
          micLabel={t("chat.voice")}
          sendLabel={t("chat.send")}
        />
      </View>
    </Screen>
  );
}

function EmptyChat(): React.ReactElement {
  const t = useTranslation();
  const mode = useSettingsStore(selectMode);
  const prefix = mode === "farmer" ? "home.farmer" : mode === "researcher" ? "home.researcher" : "home.everyone";
  const prompts = [1, 2, 3].map((n) => t(`${prefix}_prompt_${n}`));

  return (
    <View style={styles.empty}>
      <View style={styles.emptyIcon}>
        <Icon name="weather-partly-cloudy" size={30} color={Colors.onAccent} />
      </View>
      <AppText variant="title" align="center">
        {t("chat.welcome_title")}
      </AppText>
      <AppText variant="subhead" tone="secondary" align="center" style={styles.emptyBody}>
        {t("chat.welcome_subtitle")}
      </AppText>
      <View style={styles.suggestions}>
        {prompts.map((prompt) => (
          <Touchable key={prompt} haptics="selection" onPress={() => void useChatStore.getState().send(prompt)} accessibilityLabel={prompt} style={styles.suggestion}>
            <AppText variant="callout" style={styles.flex}>
              {prompt}
            </AppText>
            <Icon name="arrow-top-right" size={18} color={Colors.textTertiary} />
          </Touchable>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: {
    flex: 1,
  },
  list: {
    paddingHorizontal: Layout.gutter,
    paddingTop: Space.sm,
    paddingBottom: Space.lg,
    gap: Space.xl,
  },
  dock: {
    paddingHorizontal: Layout.gutter,
    gap: Space.sm,
  },
  empty: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: Layout.gutter,
    gap: Space.sm,
  },
  emptyIcon: {
    width: 60,
    height: 60,
    borderRadius: 20,
    backgroundColor: Colors.accent,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: Space.sm,
  },
  emptyBody: {
    maxWidth: 320,
  },
  suggestions: {
    alignSelf: "stretch",
    gap: Space.sm,
    marginTop: Space.xl,
  },
  suggestion: {
    flexDirection: "row",
    alignItems: "center",
    gap: Space.md,
    minHeight: 52,
    paddingHorizontal: Space.lg,
    borderRadius: 16,
    backgroundColor: Colors.surface,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: Colors.hairline,
  },
});
