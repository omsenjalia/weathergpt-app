import React, { useState } from "react";
import { StyleSheet, View } from "react-native";

import { AppText, Card, CardHeader, Colors, Icon, Space, Touchable } from "../../../ui";
import { useTranslation } from "../../../i18n/useTranslation";
import { AlertSeverity, AlertsStatus, OfficialAlert } from "../../../core/models/officialAlerts";
import { providerLabel } from "../format";

const COLLAPSED = 2;

const SEVERITY_COLOR: Record<AlertSeverity, string> = {
  red: Colors.danger,
  orange: Colors.warning,
  yellow: Colors.caution,
  info: Colors.info,
};

const SEVERITY_KEY: Record<AlertSeverity, string> = {
  red: "alerts.red",
  orange: "alerts.orange",
  yellow: "alerts.yellow",
  info: "alerts.title",
};

/// Official IMD / NDMA warnings for the location. Renders nothing when there are
/// none; when no official channel answered it says the status is unavailable
/// instead of implying the all-clear.
export function OfficialAlertsCard({ alerts, status }: { alerts: OfficialAlert[]; status: AlertsStatus | null }): React.ReactElement | null {
  const t = useTranslation();
  const [expanded, setExpanded] = useState(false);

  if (alerts.length === 0) {
    if (status !== "unknown") return null;
    return (
      <View style={styles.unknown} accessibilityRole="text">
        <Icon name="shield-alert-outline" size={16} color={Colors.textTertiary} />
        <AppText variant="footnote" tone="tertiary">
          {t("alerts.unknown")}
        </AppText>
      </View>
    );
  }

  const visible = expanded ? alerts : alerts.slice(0, COLLAPSED);
  const hidden = alerts.length - visible.length;
  const top = alerts[0]!.severity;

  return (
    <Card style={[styles.card, { borderColor: SEVERITY_COLOR[top] }]}>
      <CardHeader icon="alert-octagon-outline" title={t("alerts.title")} />
      {visible.map((alert) => (
        <AlertRow key={alert.id} alert={alert} />
      ))}
      {(hidden > 0 || expanded) && alerts.length > COLLAPSED && (
        <Touchable onPress={() => setExpanded((v) => !v)} haptics="selection" style={styles.more}
          accessibilityLabel={expanded ? t("alerts.show_less") : t("alerts.more", { n: hidden })}>
          <AppText variant="footnote" tone="accent">
            {expanded ? t("alerts.show_less") : t("alerts.more", { n: hidden })}
          </AppText>
        </Touchable>
      )}
    </Card>
  );
}

function AlertRow({ alert }: { alert: OfficialAlert }): React.ReactElement {
  const t = useTranslation();
  const color = SEVERITY_COLOR[alert.severity];
  const when = alert.date ?? (alert.validUntilIst ? t("alerts.until", { time: formatHhmm(alert.validUntilIst) }) : null);
  const meta = [t(SEVERITY_KEY[alert.severity]), when, providerLabel(alert.source)].filter(Boolean).join(" · ");
  return (
    <View style={styles.row} accessible accessibilityRole="alert" accessibilityLabel={`${meta}. ${alert.headline}`}>
      <View style={[styles.stripe, { backgroundColor: color }]} />
      <View style={styles.flex}>
        <AppText variant="caption" color={color}>
          {meta}
        </AppText>
        <AppText variant="callout" numberOfLines={4}>
          {alert.headline}
        </AppText>
      </View>
    </View>
  );
}

/// IMD nowcast validity comes as "1900" (IST).
function formatHhmm(raw: string): string {
  const m = /^(\d{1,2}):?(\d{2})$/.exec(raw.trim());
  if (m === null) return raw;
  const h = parseInt(m[1]!, 10);
  return `${h % 12 === 0 ? 12 : h % 12}:${m[2]} ${h < 12 ? "AM" : "PM"}`;
}

const styles = StyleSheet.create({
  card: {
    gap: Space.sm,
    borderWidth: 1,
  },
  row: {
    flexDirection: "row",
    gap: Space.sm,
  },
  stripe: {
    width: 3,
    borderRadius: 2,
  },
  flex: {
    flex: 1,
    gap: 2,
  },
  more: {
    alignSelf: "flex-start",
    minHeight: 32,
    justifyContent: "center",
  },
  unknown: {
    flexDirection: "row",
    alignItems: "center",
    gap: Space.xs,
    paddingHorizontal: Space.xs,
  },
});
