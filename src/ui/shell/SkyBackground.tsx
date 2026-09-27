/// Live sky behind every screen: the atmosphere palette gradient
/// (time-of-day × weather), a soft sun/moon, horizon warmth at dawn/dusk and
/// a vertical scrim that keeps white text legible from midday to midnight.

import React from "react";
import { StyleSheet, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import Svg, { Defs, RadialGradient, Rect, Stop } from "react-native-svg";

import { AtmospherePalette } from "../../features/weather/theme/atmosphereTheme";
import { Colors } from "../theme/tokens";

interface SkyBackgroundProps {
  palette: AtmospherePalette;
  children?: React.ReactNode;
}

export function SkyBackground({ palette, children }: SkyBackgroundProps): React.ReactElement {
  const showOrb = palette.showSun || palette.showMoon;
  const orbY = palette.showSun ? palette.sunY : palette.moonY;
  const orbColor = palette.showSun ? palette.orbEnd : palette.orbStart;

  return (
    <View style={styles.root}>
      <LinearGradient colors={[palette.top, palette.mid, palette.bottom]} locations={[0, 0.55, 1]} style={StyleSheet.absoluteFill} />

      {palette.horizonWarmth > 0 && (
        <LinearGradient
          colors={["transparent", `rgba(251, 146, 60, ${0.3 * palette.horizonWarmth})`, `rgba(234, 88, 12, ${0.45 * palette.horizonWarmth})`]}
          style={styles.horizon}
        />
      )}

      <LinearGradient pointerEvents="none" colors={[Colors.scrimTop, Colors.scrimBottom]} locations={[0.1, 0.85]} style={StyleSheet.absoluteFill} />

      {/* Ambient sun/moon light: a soft radial glow, not a solid disk, so it
          never reads as an object sitting behind translucent cards. */}
      {showOrb && orbY < 1.1 && (
        <Svg pointerEvents="none" style={StyleSheet.absoluteFill} width="100%" height="100%">
          <Defs>
            <RadialGradient id="sky-glow" cx="80%" cy={`${Math.round(orbY * 100)}%`} r="45%" fx="80%" fy={`${Math.round(orbY * 100)}%`}>
              <Stop offset="0" stopColor={orbColor} stopOpacity={0.35} />
              <Stop offset="1" stopColor={orbColor} stopOpacity={0} />
            </RadialGradient>
          </Defs>
          <Rect x="0" y="0" width="100%" height="100%" fill="url(#sky-glow)" />
        </Svg>
      )}
      <View style={StyleSheet.absoluteFill}>{children}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Colors.canvas,
  },
  horizon: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    height: "55%",
  },
});
