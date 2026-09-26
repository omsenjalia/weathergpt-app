/// Weather store — port of `lib/features/home/providers/weather_provider.dart`.
/// Fetches `/v2/weather` (WeatherNext-capable) with an honest legacy
/// `/weather` fallback, records exactly what was sent for the Debug screen,
/// and derives the app-wide atmosphere palette from the live snapshot.

import { create } from "zustand";

import { ApiEndpoints } from "../../core/config/apiEndpoints";
import { AppMode } from "../../core/models/appMode";
import { apiErrorMessage, ServerError } from "../../core/errors/appErrors";
import { ApiClient } from "../../core/services/apiClient";
import { useRequestLogStore } from "../../core/services/requestLog";
import { WeatherSnapshot } from "./models/weather";
import { parseWeatherSnapshot } from "./models/weatherParser";
import { parseWeatherSnapshotV2 } from "./models/weatherV2Parser";
import {
  AtmospherePalette,
  conditionFromWeather,
  paletteFor,
  parseWeatherTime,
  periodFromLocalTime,
  SkyCondition,
  SkyPeriod,
} from "./theme/atmosphereTheme";
import { DEFAULT_DEVELOPER_OPTIONS, DevSourcePin, DevWnModel, DEV_SOURCE_PIN_WIRE, DEV_WN_MODEL_WIRE, DeveloperOptions } from "../settings/developerOptionsStore";
import { AppLocation, DEFAULT_LOCATION } from "../location/locationStore";

export const DEFAULT_HOURLY_HOURS = 48;
export const DEFAULT_FORECAST_DAYS = 7;

/// Exactly what the app sent for the current snapshot, so the Debug screen
/// can show the request next to the response.
export interface WeatherRequestInfo {
  endpoint: string;
  query: Record<string, unknown>;
  usedLegacyFallback: boolean;
  v2Error?: string | null;
}

export interface WeatherStatus {
  snapshot: WeatherSnapshot | null;
  loading: boolean;
  error: string | null;
  lastRequest: WeatherRequestInfo | null;
}

/// The query the app will send, derived from mode + developer options.
export function buildWeatherQuery(opts: {
  lat: number;
  lon: number;
  mode: AppMode;
  dev: DeveloperOptions;
}): Record<string, unknown> {
  const { lat, lon, mode, dev } = opts;
  const customise = dev.enabled;
  const pin = customise ? dev.sourcePin : DevSourcePin.Auto;
  // Researcher mode pins WeatherNext by contract unless a developer override
  // explicitly asks for something else.
  const requested =
    pin !== DevSourcePin.Auto
      ? DEV_SOURCE_PIN_WIRE[pin]
      : mode === "researcher"
        ? "weathernext"
        : "auto";
  return {
    lat,
    lon,
    mode,
    requested_source: requested,
    forecast_days: customise ? dev.forecastDays : DEFAULT_FORECAST_DAYS,
    hourly_hours: customise ? dev.hourlyHours : DEFAULT_HOURLY_HOURS,
    ...(customise && !dev.supplementSecondaryFields ? { supplement: false } : {}),
    ...(customise && dev.wnModel !== DevWnModel.Wn3 ? { model: DEV_WN_MODEL_WIRE[dev.wnModel] } : {}),
  };
}

interface WeatherStore extends WeatherStatus {
  generation: number;
  locationRef: AppLocation;
  modeRef: AppMode;
  devRef: DeveloperOptions;
  setContext: (location: AppLocation, mode: AppMode, dev: DeveloperOptions) => void;
  fetchWeather: (location: AppLocation, mode: AppMode, dev: DeveloperOptions) => Promise<void>;
  clear: () => void;
}

export const useWeatherStore = create<WeatherStore>((set, get) => ({
  snapshot: null,
  loading: false,
  error: null,
  lastRequest: null,
  generation: 0,
  locationRef: DEFAULT_LOCATION,
  modeRef: "everyone",
  devRef: DEFAULT_DEVELOPER_OPTIONS,

  setContext: (location, mode, dev) => set({ locationRef: location, modeRef: mode, devRef: dev }),

  fetchWeather: async (location, mode, dev) => {
    const generation = get().generation + 1;
    set({ generation, loading: true, error: null });
    // Keep the ring buffer alive from app start so the Debug screen shows the
    // requests that happened before it was first opened.
    useRequestLogStore.getState().setEnabled(!dev.enabled || dev.logRequests);
    const cityName = location.name.split(",")[0]!.trim();

    const query = buildWeatherQuery({ lat: location.lat, lon: location.lon, mode, dev });

    let v2Error: string | null = null;
    try {
      const data = await ApiClient.get(ApiEndpoints.v2Weather, query);
      if (data["status"] === "unavailable") {
        // The backend answered honestly that nothing could serve this request
        // (typically a pinned source). Surface that instead of falling back.
        const reasons = Array.isArray(data["fallback_reasons"])
          ? (data["fallback_reasons"] as unknown[])
              .map((r) => (r !== null && typeof r === "object" ? `${(r as Record<string, unknown>)["provider"]}: ${(r as Record<string, unknown>)["reason"]}` : String(r)))
              .join("; ")
          : "";
        const err = data["error"] ?? "No forecast provider available";
        throw new ServerError(reasons === "" ? String(err) : `${String(err)} (${reasons})`);
      }
      if (get().generation !== generation) return;
      set({
        loading: false,
        snapshot: parseWeatherSnapshotV2(data, { cityName }),
        lastRequest: { endpoint: ApiEndpoints.v2Weather, query, usedLegacyFallback: false },
      });
      return;
    } catch (error) {
      v2Error = apiErrorMessage(error);
      if (dev.enabled && dev.disableV2Fallback) {
        if (get().generation === generation) {
          set({ loading: false, error: v2Error, lastRequest: { endpoint: ApiEndpoints.v2Weather, query, usedLegacyFallback: false, v2Error } });
        }
        return;
      }
      if (
        error instanceof ServerError &&
        (error.message.includes("unavailable") || error.message.includes("provider")) &&
        query["requested_source"] !== "auto"
      ) {
        // A pinned source that is honestly unavailable must not be replaced by
        // a silent legacy call to a different provider.
        if (get().generation === generation) set({ loading: false, error: v2Error });
        return;
      }
    }

    const legacyQuery: Record<string, unknown> = {
      lat: location.lat,
      lon: location.lon,
      mode,
      requested_source: query["requested_source"],
    };
    try {
      const data = await ApiClient.get(ApiEndpoints.weather, legacyQuery);
      if (get().generation !== generation) return;
      set({
        loading: false,
        snapshot: parseWeatherSnapshot(data, { cityName }),
        lastRequest: { endpoint: ApiEndpoints.weather, query: legacyQuery, usedLegacyFallback: true, v2Error },
      });
    } catch (error) {
      if (get().generation !== generation) return;
      set({
        loading: false,
        error: apiErrorMessage(error),
        lastRequest: { endpoint: ApiEndpoints.weather, query: legacyQuery, usedLegacyFallback: true, v2Error },
      });
    }
  },

  clear: () => set({ snapshot: null, error: null, lastRequest: null, loading: false }),
}));

/// Computes the app-wide sky palette from wall-clock time and the live
/// snapshot — port of `atmosphere_provider.dart` (`atmospherePaletteProvider`).
export function atmospherePalette(
  now: Date,
  snapshot: WeatherSnapshot | null,
  dev?: { forcePeriod: SkyPeriod | null; forceSky: SkyCondition | null },
): AtmospherePalette {
  if (dev?.forcePeriod !== undefined && dev.forcePeriod !== null && dev.forceSky !== undefined && dev.forceSky !== null) {
    return paletteFor(dev.forcePeriod, dev.forceSky);
  }
  const sunrise = snapshot === null ? null : parseWeatherTime(snapshot.sunrise);
  const sunset = snapshot === null ? null : parseWeatherTime(snapshot.sunset);
  const sky =
    dev?.forceSky !== undefined && dev.forceSky !== null
      ? dev.forceSky
      : snapshot === null
        ? SkyCondition.Clear
        : conditionFromWeather(snapshot);
  const period =
    dev?.forcePeriod !== undefined && dev.forcePeriod !== null
      ? dev.forcePeriod
      : periodFromLocalTime(now, sunrise, sunset);
  return paletteFor(period, sky);
}
