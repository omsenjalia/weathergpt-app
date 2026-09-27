import React from "react";
import { StyleSheet, View } from "react-native";
import { router } from "expo-router";

import { Button, Screen, StateView } from "../src/ui";

export default function NotFoundScreen(): React.ReactElement {
  return (
    <Screen>
      <View style={styles.center}>
        <StateView icon="map-search-outline" title="This page doesn't exist" body="The link may be broken or the page may have moved." />
        <Button label="Go to today's weather" icon="weather-partly-cloudy" onPress={() => router.replace("/home")} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  center: {
    minHeight: 520,
    justifyContent: "center",
    alignItems: "center",
  },
});
