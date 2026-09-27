/// Looping sky video for the current period × condition. Bundled clips only
/// (offline-safe); the palette gradient underneath is always visible while a
/// clip loads, fails, or is switched off.

import React, { useEffect, useRef, useState } from "react";
import { Animated, Platform, StyleSheet } from "react-native";
import { useVideoPlayer, VideoView } from "expo-video";

import { SkyCondition, SkyPeriod } from "../../features/weather/theme/atmosphereTheme";

const CLIPS = {
  day: require("../../../assets/sky/day.mp4"),
  night: require("../../../assets/sky/night.mp4"),
  rain: require("../../../assets/sky/rain.mp4"),
  sunrise: require("../../../assets/sky/sunrise.mp4"),
  sunset: require("../../../assets/sky/sunset.mp4"),
  thunder: require("../../../assets/sky/thunder.mp4"),
} as const;

export type SkyClip = keyof typeof CLIPS;

/// Same mapping as the Flutter build: weather first, then time of day.
export function clipFor(period: SkyPeriod, sky: SkyCondition): SkyClip {
  if (sky === SkyCondition.Thunder) return "thunder";
  if (sky === SkyCondition.HeavyRain || sky === SkyCondition.Rain || sky === SkyCondition.Drizzle) return "rain";
  if (
    sky === SkyCondition.Fog ||
    sky === SkyCondition.Overcast ||
    sky === SkyCondition.Cloudy ||
    sky === SkyCondition.PartlyCloudy ||
    sky === SkyCondition.Snow
  ) {
    return isNightPeriod(period) ? "night" : "day";
  }
  switch (period) {
    case SkyPeriod.Sunrise:
    case SkyPeriod.Predawn:
      return "sunrise";
    case SkyPeriod.Sunset:
    case SkyPeriod.GoldenHour:
    case SkyPeriod.Dusk:
      return "sunset";
    case SkyPeriod.Night:
    case SkyPeriod.Midnight:
    case SkyPeriod.Evening:
      return "night";
    default:
      return "day";
  }
}

export function isNightPeriod(period: SkyPeriod): boolean {
  return period === SkyPeriod.Night || period === SkyPeriod.Midnight || period === SkyPeriod.Evening;
}

const VISIBLE_OPACITY = 0.72;
const nativeDriver = Platform.OS !== "web";

export function SkyVideo({ clip }: { clip: SkyClip }): React.ReactElement {
  const opacity = useRef(new Animated.Value(0)).current;
  const [failed, setFailed] = useState(false);
  const player = useVideoPlayer(CLIPS[clip], (p) => {
    p.loop = true;
    p.muted = true;
    p.play();
  });

  // Start playback once the view is mounted: on web, play() only reaches
  // mounted <video> elements, and a remounted view (React dev mode) never
  // re-registers its element. Muted autoplay is allowed before ready.
  useEffect(() => {
    const id = setTimeout(() => player.play(), 0);
    return () => clearTimeout(id);
  }, [player]);

  // Swap clips in place; fade out first so a bright first frame never
  // flashes over the copy during a weather / time-of-day change. Tracks what
  // the player holds, so repeated effect runs never reload the same clip.
  const loadedClip = useRef(clip);
  useEffect(() => {
    if (loadedClip.current === clip) return;
    loadedClip.current = clip;
    Animated.timing(opacity, { toValue: 0, duration: 250, useNativeDriver: nativeDriver }).start(() => {
      void player.replaceAsync(CLIPS[clip]).catch(() => setFailed(true));
    });
  }, [clip, player, opacity]);

  useEffect(() => {
    const sub = player.addListener("statusChange", ({ status }) => {
      if (status === "error") setFailed(true);
    });
    return () => sub.remove();
  }, [player]);

  // Fade in once a frame is actually on screen (reliable on web and native,
  // unlike player status, which can settle before listeners attach).
  const reveal = () => {
    setFailed(false);
    player.play();
    Animated.timing(opacity, { toValue: VISIBLE_OPACITY, duration: 650, useNativeDriver: nativeDriver }).start();
  };

  if (failed) return <></>;
  return (
    <Animated.View pointerEvents="none" style={[StyleSheet.absoluteFill, { opacity }]}>
      <VideoView
        player={player}
        style={styles.video}
        contentFit="cover"
        nativeControls={false}
        allowsFullscreen={false}
        allowsPictureInPicture={false}
        onFirstFrameRender={reveal}
        accessible={false}
      />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  // <video> is a replaced element: offsets alone don't stretch it on web.
  video: {
    position: "absolute",
    top: 0,
    left: 0,
    width: "100%",
    height: "100%",
  },
});
