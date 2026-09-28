import { describe, expect, it } from "vitest";

import {
  alertsStatusFromJson,
  localClockLabel,
  officialAlertsFromJson,
  stationObservationFromJson,
} from "../src/core/models/officialAlerts";
import { parseWeatherSnapshot } from "../src/features/weather/models/weatherParser";
import { parseWeatherSnapshotV2 } from "../src/features/weather/models/weatherV2Parser";
import { providerLabel } from "../src/features/weather/format";

// Shapes as served by the unified backend (IMD live-verified 2026-09-28).
const alerts = [
  { id: "imd:nowcast:157", source: "imd", type: "nowcast", severity: "yellow", event: "Light rain",
    headline: "Light rain likely", area: "MUMBAI SUBURBAN", valid_until_ist: "1900" },
  { id: "sachet:1", source: "ndma_sachet", type: "cap_alert", severity: "orange", event: "Thunderstorm",
    headline: "Thunderstorm with lightning likely", onset: "2026-09-28T06:30:00+00:00", expires: "2026-09-28T12:30:00+00:00" },
  { id: "imd:district_warning:1:2026-09-29", source: "imd", severity: "red", event: "Heavy rain",
    headline: "Red warning for X: Heavy rain", date: "2026-09-29" },
  { id: "green", source: "imd", severity: "green", headline: "No warning" },
  { source: "imd", severity: "purple", headline: "Unknown scale" },
  { source: "imd", severity: "red" },
];

const v2 = {
  status: "ok",
  selected_source: "imd",
  location: { timezone: "Asia/Kolkata", utc_offset_seconds: 19800 },
  current: {
    time_utc: "2026-09-28T12:00:00+00:00", temperature_c: 32, condition: "Smoke Fog", weather_code: 45,
    kind: "observation", station: { code: "42647", name: "Ahmedabad", distance_km: 8.3 },
  },
  daily: [{ date: "2026-09-28", high_c: 35, low_c: 25, condition: "Partly cloudy",
            forecast_text: "Partly cloudy sky", field_sources: { high_c: "imd", rain_probability: "open_meteo" } }],
  hourly: [],
  alerts,
  alerts_status: "ok",
  provenance: { selected_source: "imd" },
};

describe("official alerts", () => {
  it("parses, drops green / headline-less rows, maps unknown severities to info, sorts by severity", () => {
    const parsed = officialAlertsFromJson(alerts);
    expect(parsed.map((a) => a.severity)).toEqual(["red", "orange", "yellow", "info"]);
    expect(parsed[0]!.date).toBe("2026-09-29");
    expect(parsed[1]!.expiresUtc?.toISOString()).toBe("2026-09-28T12:30:00.000Z");
    expect(parsed[2]!.validUntilIst).toBe("1900");
    expect(officialAlertsFromJson(undefined)).toEqual([]);
  });

  it("keeps 'unknown' distinct from 'no alerts'", () => {
    expect(alertsStatusFromJson("unknown")).toBe("unknown");
    expect(alertsStatusFromJson("ok")).toBe("ok");
    expect(alertsStatusFromJson("weird")).toBeNull();
  });

  it("only reports a station observation when the backend says so", () => {
    expect(stationObservationFromJson(v2.current)).toEqual({
      stationName: "Ahmedabad", distanceKm: 8.3, observedAtUtc: new Date("2026-09-28T12:00:00Z"),
    });
    expect(stationObservationFromJson({ ...v2.current, kind: "model" })).toBeNull();
    expect(stationObservationFromJson(null)).toBeNull();
  });

  it("formats clocks in the location's time", () => {
    expect(localClockLabel(new Date("2026-09-28T12:00:00Z"), 19800)).toBe("5:30 PM");
    expect(localClockLabel(new Date("2026-09-28T18:30:00Z"), 19800)).toBe("12:00 AM");
  });
});

describe("weather parsers carry the new fields", () => {
  it("v2", () => {
    const s = parseWeatherSnapshotV2(v2, { cityName: "Ahmedabad" });
    expect(s.alerts).toHaveLength(4);
    expect(s.alertsStatus).toBe("ok");
    expect(s.observation?.stationName).toBe("Ahmedabad");
    expect(s.forecast[0]!.forecastText).toBe("Partly cloudy sky");
    expect(s.forecast[0]!.fieldSources["rain_probability"]).toBe("open_meteo");
  });

  it("legacy /weather (same payload)", () => {
    const s = parseWeatherSnapshot({ ...v2, forecast: v2.daily, temperature_c: 32 }, { cityName: "Ahmedabad" });
    expect(s.alerts?.[0]?.severity).toBe("red");
    expect(s.observation?.stationName).toBe("Ahmedabad");
    expect(s.forecast[0]!.forecastText).toBe("Partly cloudy sky");
  });

  it("older payloads without the fields still parse", () => {
    const s = parseWeatherSnapshotV2({ current: { temperature_c: 20 }, daily: [] }, { cityName: "X" });
    expect(s.alerts).toEqual([]);
    expect(s.alertsStatus).toBeNull();
    expect(s.observation).toBeNull();
  });
});

describe("provider labels", () => {
  it("names providers for people", () => {
    expect(providerLabel("imd")).toBe("IMD");
    expect(providerLabel("open_meteo")).toBe("Open-Meteo");
    expect(providerLabel("weathernext")).toBe("Google WeatherNext");
    expect(providerLabel("ndma_sachet")).toBe("NDMA");
    expect(providerLabel(null)).toBeNull();
  });
});
