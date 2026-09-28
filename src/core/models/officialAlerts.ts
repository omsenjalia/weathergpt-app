/// Official warnings and station observations reported by the backend.
///
/// `/v2/weather` carries `alerts` (IMD district / city warnings, IMD nowcasts and
/// NDMA SACHET CAP alerts for the point) plus `alerts_status`. A status of
/// `unknown` means no official channel answered: the UI must say the status is
/// unavailable, never "no warnings".

import { jsonDate, jsonList, jsonMap, jsonNum, jsonString } from "./jsonValues";

export type AlertSeverity = "red" | "orange" | "yellow" | "info";

export type AlertsStatus = "ok" | "unknown" | "not_covered" | "not_requested" | "disabled";

export interface OfficialAlert {
  id: string;
  /// `imd` or `ndma_sachet`.
  source: string;
  issuer: string | null;
  /// `district_warning`, `city_warning`, `nowcast` or `cap_alert`.
  type: string | null;
  event: string | null;
  headline: string;
  severity: AlertSeverity;
  area: string | null;
  /// Local date a daily warning applies to (`YYYY-MM-DD`).
  date: string | null;
  onsetUtc: Date | null;
  expiresUtc: Date | null;
  /// Nowcast validity as issued by IMD (`HHmm`, IST).
  validUntilIst: string | null;
}

const SEVERITIES: readonly AlertSeverity[] = ["red", "orange", "yellow", "info"];
const RANK: Record<AlertSeverity, number> = { red: 3, orange: 2, yellow: 1, info: 0 };

export function severityRank(severity: AlertSeverity): number {
  return RANK[severity];
}

export function officialAlertsFromJson(raw: unknown): OfficialAlert[] {
  const out: OfficialAlert[] = [];
  for (const item of jsonList(raw)) {
    const row = jsonMap(item);
    if (row === null) continue;
    const headline = jsonString(row["headline"]) ?? jsonString(row["event"]);
    if (headline === null) continue;
    const severityRaw = jsonString(row["severity"])?.toLowerCase();
    // Green means "no warning" on IMD's scales; it is never shown as an alert.
    if (severityRaw === "green") continue;
    const severity = SEVERITIES.includes(severityRaw as AlertSeverity) ? (severityRaw as AlertSeverity) : "info";
    out.push({
      id: jsonString(row["id"]) ?? `${jsonString(row["source"]) ?? "alert"}:${out.length}`,
      source: jsonString(row["source"]) ?? "unknown",
      issuer: jsonString(row["issuer"]),
      type: jsonString(row["type"]),
      event: jsonString(row["event"]),
      headline,
      severity,
      area: jsonString(row["area"]),
      date: jsonString(row["date"]),
      onsetUtc: jsonDate(row["onset"]),
      expiresUtc: jsonDate(row["expires"]),
      validUntilIst: jsonString(row["valid_until_ist"]),
    });
  }
  return out.sort((a, b) => severityRank(b.severity) - severityRank(a.severity));
}

export function alertsStatusFromJson(raw: unknown): AlertsStatus | null {
  const value = jsonString(raw);
  switch (value) {
    case "ok":
    case "unknown":
    case "not_covered":
    case "not_requested":
    case "disabled":
      return value;
    default:
      return null;
  }
}

/// The station behind "now" when it is a real observation (IMD `current_wx`).
export interface StationObservation {
  stationName: string;
  distanceKm: number | null;
  observedAtUtc: Date | null;
}

export function stationObservationFromJson(current: Record<string, unknown> | null): StationObservation | null {
  if (current === null || jsonString(current["kind"]) !== "observation") return null;
  const station = jsonMap(current["station"]);
  const name = jsonString(station?.["name"]);
  if (name === null) return null;
  return {
    stationName: name,
    distanceKm: jsonNum(station?.["distance_km"]),
    observedAtUtc: jsonDate(current["time_utc"]),
  };
}

/// "4:05 PM"-style clock for an instant, in the location's local time when the
/// offset is known (device time otherwise).
export function localClockLabel(utc: Date, utcOffsetSeconds: number | null | undefined): string {
  const shifted = utcOffsetSeconds == null ? utc : new Date(utc.getTime() + utcOffsetSeconds * 1000);
  const hours = utcOffsetSeconds == null ? shifted.getHours() : shifted.getUTCHours();
  const minutes = utcOffsetSeconds == null ? shifted.getMinutes() : shifted.getUTCMinutes();
  return `${hours % 12 === 0 ? 12 : hours % 12}:${String(minutes).padStart(2, "0")} ${hours < 12 ? "AM" : "PM"}`;
}
