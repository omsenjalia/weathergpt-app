/// Frosted-glass surface primitive — port of
/// `lib/core/widgets/glass_card.dart`.

import React from "react";
import { View, ViewProps, StyleSheet, ViewStyle, StyleProp } from "react-native";

import { AppColors } from "../appColors";
import { Radius } from "../theme";

interface GlassCardProps extends ViewProps {
  children?: React.ReactNode;
  strong?: boolean;
  style?: StyleProp<ViewStyle>;
}

export function GlassCard({ children, strong = false, style, ...rest }: GlassCardProps): React.ReactElement {
  return (
    <View
      {...rest}
      style={[
        styles.card,
        { backgroundColor: strong ? AppColors.glassFillStrong : AppColors.glassFill, borderColor: AppColors.glassBorder },
        style,
      ]}
    >
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: Radius.lg,
    borderWidth: StyleSheet.hairlineWidth,
    padding: 16,
  },
});
