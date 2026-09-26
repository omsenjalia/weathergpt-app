/// Atmospheric sky background — port of
/// `lib/core/widgets/atmosphere_background.dart`. A vertical gradient driven
/// by the live palette (time-of-day × weather), with sun/moon orb and horizon
/// warmth. Video skies from `assets/videos/` are a native-only enhancement;
/// the gradient canvas renders everywhere.

import React, { useMemo } from "react";
import { View, StyleSheet, Platform, ViewStyle } from "react-native";
import { LinearGradient } from "expo-linear-gradient";

import { AtmospherePalette } from "../../features/weather/theme/atmosphereTheme";
import { AppColors } from "../appColors";

interface AtmosphereBackgroundProps {
  palette: AtmospherePalette;
  children?: React.ReactNode;
}

export function AtmosphereBackground({ palette, children }: AtmosphereBackgroundProps): React.ReactElement {
  const orbTop = useMemo(() => `${Math.round(palette.sunY * 100)}%`, [palette.sunY]);
  return (
    <View style={styles.root}>
      <LinearGradient
        colors={[palette.top, palette.mid, palette.bottom]}
        style={StyleSheet.absoluteFill}
      />
      {/* Horizon warmth band (sunset/sunrise) */}
      {palette.horizonWarmth > 0 && (
        <LinearGradient
          colors={["transparent", `rgba(251, 146, 60, ${0.35 * palette.horizonWarmth})`, `rgba(234, 88, 12, ${0.5 * palette.horizonWarmth})`]}
          style={[StyleSheet.absoluteFill, { height: "55%", top: "45%" }]}
        />
      )}
      {/* Sun / moon orb */}
      {(palette.showSun || palette.showMoon) && (
        <View
          pointerEvents="none"
          style={[
            styles.orb,
            {
              top: palette.showSun ? orbTop : `${Math.round((palette.moonY ?? 0.25) * 100)}%`,
              backgroundColor: palette.showSun ? palette.orbEnd : palette.orbStart,
              shadowColor: palette.showSun ? palette.orbEnd : palette.orbStart,
            } as ViewStyle,
          ]}
        />
      )}
      {/* Readability scrim */}
      <View style={[StyleSheet.absoluteFill, { backgroundColor: AppColors.scrim }]} />
      <View style={StyleSheet.absoluteFill}>{children}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  orb: {
    position: "absolute",
    width: 64,
    height: 64,
    borderRadius: 32,
    opacity: 0.9,
    ...Platform.select({
      web: { filter: "blur(0.5px)", boxShadow: "0 0 60px 24px rgba(255,255,255,0.25)" },
      default: { shadowOpacity: 0.4, shadowRadius: 40, shadowOffset: { width: 0, height: 0 } },
    }),
  },
});
