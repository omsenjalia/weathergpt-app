import React, { useState } from "react";
import { StyleSheet, TextInput, View } from "react-native";

import { Colors, FontFamily, IconButton, Radius, Space } from "../../../ui";

interface ComposerProps {
  placeholder: string;
  sending: boolean;
  listening: boolean;
  onSend: (text: string) => void;
  onMic: () => void;
  micLabel: string;
  sendLabel: string;
}

export function Composer({ placeholder, sending, listening, onSend, onMic, micLabel, sendLabel }: ComposerProps): React.ReactElement {
  const [draft, setDraft] = useState("");
  const canSend = draft.trim() !== "" && !sending;

  const submit = () => {
    if (!canSend) return;
    onSend(draft.trim());
    setDraft("");
  };

  return (
    <View style={styles.wrap}>
      <View style={styles.box}>
        <TextInput
          value={draft}
          onChangeText={setDraft}
          placeholder={placeholder}
          placeholderTextColor={Colors.textTertiary}
          selectionColor={Colors.accent}
          style={styles.input}
          multiline
          maxLength={2000}
          accessibilityLabel={placeholder}
          onSubmitEditing={submit}
          blurOnSubmit={false}
          submitBehavior="submit"
          returnKeyType="send"
        />
        {canSend ? (
          <IconButton icon="arrow-up" variant="accent" size={36} accessibilityLabel={sendLabel} onPress={submit} />
        ) : (
          <IconButton
            icon={listening ? "stop" : "microphone"}
            variant={listening ? "accent" : "plain"}
            size={36}
            accessibilityLabel={micLabel}
            onPress={onMic}
            color={listening ? undefined : Colors.textSecondary}
          />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    paddingTop: Space.sm,
  },
  box: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: Space.sm,
    paddingLeft: Space.lg,
    paddingRight: 6,
    paddingVertical: 6,
    borderRadius: Radius.xl,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: Colors.hairlineStrong,
    backgroundColor: "rgba(8, 13, 26, 0.86)",
  },
  input: {
    flex: 1,
    minHeight: 36,
    maxHeight: 132,
    paddingTop: 8,
    paddingBottom: 8,
    color: Colors.text,
    fontFamily: FontFamily.medium,
    fontSize: 15,
    lineHeight: 20,
    outlineStyle: "none",
  } as never,
});
