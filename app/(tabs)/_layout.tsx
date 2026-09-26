import React from "react";
import { View, StyleSheet } from "react-native";

import { NavigationShell } from "../../src/ui/components/NavigationShell";
import { useSettingsStore, selectMode } from "../../src/features/settings/settingsStore";

export default function TabsLayout(): React.ReactElement {
  const mode = useSettingsStore(selectMode);
  return (
    <View style={styles.root}>
      <NavigationShell mode={mode}>
        <Slots />
      </NavigationShell>
    </View>
  );
}

/// expo-router slot: renders the matched child route.
import { Slot } from "expo-router";

function Slots(): React.ReactElement {
  return (
    <View style={styles.fill}>
      <Slot />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  fill: {
    flex: 1,
  },
});
