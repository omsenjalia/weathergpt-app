/// Error surface — port of `lib/core/widgets/api_error_view.dart`.

import React from "react";
import { View, Text, StyleSheet } from "react-native";

import { GlassCard } from "./GlassCard";
import { PrimaryButton } from "./Buttons";
import { AppColors } from "../appColors";
import { Spacing } from "../theme";

interface ApiErrorViewProps {
  message: string;
  onRetry?: () => void;
}

export function ApiErrorView({ message, onRetry }: ApiErrorViewProps): React.ReactElement {
  return (
    <View style={styles.wrap}>
      <GlassCard strong style={styles.card}>
        <Text style={styles.icon}>⚠️</Text>
        <Text style={styles.title}>Could not load weather</Text>
        <Text style={styles.body}>{message}</Text>
        {onRetry !== undefined && (
          <PrimaryButton label="Try again" onPress={onRetry} style={{ marginTop: Spacing.lg }} />
        )}
      </GlassCard>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: Spacing.xl,
  },
  card: {
    width: "100%",
    maxWidth: 420,
    alignItems: "center",
    paddingVertical: Spacing.xxl,
    gap: Spacing.sm,
  },
  icon: {
    fontSize: 34,
  },
  title: {
    fontSize: 17,
    fontWeight: "700",
    color: AppColors.textPrimary,
  },
  body: {
    fontSize: 13,
    color: AppColors.textSecondary,
    textAlign: "center",
    lineHeight: 19,
  },
});
