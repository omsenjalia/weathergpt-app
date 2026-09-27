import React from "react";
import { router } from "expo-router";

import { Screen, haptic } from "../src/ui";
import { useTranslation } from "../src/i18n/useTranslation";
import { useFarmProfileStore } from "../src/features/farm/farmStores";
import { FarmProfileForm } from "../src/features/farm/components/FarmProfileForm";

export default function FarmProfileScreen(): React.ReactElement {
  const t = useTranslation();
  const profile = useFarmProfileStore((s) => s.profile);

  return (
    <Screen back keyboardAware title={t("farmer.farm_profile")} subtitle={t("farmer.profile_complete_hint")}>
      <FarmProfileForm
        initial={profile}
        submitLabel={t("farmer.save_changes")}
        onSaved={() => {
          haptic("success");
          router.back();
        }}
      />
    </Screen>
  );
}
