import { useEffect } from "react";
import { Redirect } from "expo-router";

import { loadJson, StorageKeys } from "../src/lib/persistence";
import { useLocationStore } from "../src/features/location/locationStore";

export default function Index(): React.ReactElement | null {
  const [target, setTarget] = useRouteTarget();

  useEffect(() => {
    if (target === undefined) return;
    if (target === "/(tabs)") {
      // First launch after onboarding: ask the OS for location permission once.
      void useLocationStore.getState().maybeAutoLocate();
    }
  }, [target]);

  if (target === undefined) return null;
  return <Redirect href={target} />;
}

import { useState } from "react";

function useRouteTarget(): ["/(tabs)" | "/onboarding" | undefined, unknown] {
  const [target, setTarget] = useState<"/(tabs)" | "/onboarding" | undefined>(undefined);
  useEffect(() => {
    void loadJson<boolean | null>(StorageKeys.onboardingComplete).then((complete) => {
      setTarget(complete === true ? "/(tabs)" : "/onboarding");
    });
  }, []);
  return [target, null];
}
