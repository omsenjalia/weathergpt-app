/// Floating glass pill navigation — port of
/// `lib/core/widgets/navigation_shell.dart`. Persona-aware tab set.

import React from "react";
import { View, Text, Pressable, StyleSheet } from "react-native";
import { MaterialCommunityIcons } from "@expo/vector-icons";
import { useRouter, usePathname } from "expo-router";

import { AppColors } from "../appColors";
import { Radius } from "../theme";
import { AppMode } from "../../core/models/appMode";

interface TabDef {
  href: string;
  icon: keyof typeof MaterialCommunityIcons.glyphMap;
  label: string;
}

const BASE_TABS: readonly TabDef[] = [
  { href: "/(tabs)/home", icon: "home-variant-outline", label: "Home" },
  { href: "/(tabs)/chat", icon: "chat-outline", label: "Chat" },
  { href: "/(tabs)/explore", icon: "map-outline", label: "Explore" },
  { href: "/(tabs)/profile", icon: "account-circle-outline", label: "Profile" },
];

const FARM_TAB: TabDef = { href: "/(tabs)/farm", icon: "sprout", label: "Farm" };
const LAB_TAB: TabDef = { href: "/(tabs)/lab", icon: "flask-outline", label: "Lab" };

function tabsForMode(mode: AppMode): readonly TabDef[] {
  // Persona-aware tab set: Farmer gains Farm, Researcher gains Lab.
  const tabs = [...BASE_TABS];
  if (mode === "farmer") tabs.splice(2, 0, FARM_TAB);
  if (mode === "researcher") tabs.splice(2, 0, LAB_TAB);
  return tabs;
}

interface NavigationShellProps {
  mode: AppMode;
  children: React.ReactNode;
}

export function NavigationShell({ mode, children }: NavigationShellProps): React.ReactElement {
  const router = useRouter();
  const pathname = usePathname();
  const tabs = tabsForMode(mode);
  return (
    <View style={styles.root}>
      <View style={styles.content}>{children}</View>
      <View style={styles.barWrap} pointerEvents="box-none">
        <View style={styles.bar}>
          {tabs.map((tab) => {
            const active = pathname.startsWith(tab.href.replace("/(tabs)", ""));
            const color = active ? AppColors.accent : AppColors.textTertiary;
            return (
              <Pressable key={tab.href} onPress={() => router.navigate(tab.href)} style={styles.tab}>
                <MaterialCommunityIcons name={tab.icon} size={22} color={color} />
                <Text style={[styles.tabLabel, { color: active ? AppColors.accent : AppColors.textTertiary }]}>
                  {tab.label}
                </Text>
              </Pressable>
            );
          })}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  content: {
    flex: 1,
  },
  barWrap: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    alignItems: "center",
    paddingBottom: 18,
  },
  bar: {
    flexDirection: "row",
    backgroundColor: AppColors.glassFillStrong,
    borderColor: AppColors.glassBorderStrong,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: Radius.pill,
    paddingHorizontal: 8,
    paddingVertical: 8,
    gap: 2,
  },
  tab: {
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 12,
    paddingVertical: 4,
    minWidth: 60,
    gap: 2,
  },
  tabLabel: {
    fontSize: 10,
    fontWeight: "600",
  },
});
