/// Developer options store — port of
/// `lib/features/settings/providers/developer_options_provider.dart`.
/// Provider pinning, horizons, provenance display and sky overrides for the
/// Debug screen. All of it is persisted to AsyncStorage.

import { create } from "zustand";

import { SkyCondition, SkyPeriod } from "../weather/theme/atmosphereTheme";
import { loadJson, saveJson, StorageKeys } from "../../lib/persistence";

/// Which provider the app asks the backend to use. `auto` lets the backend
/// run its IMD → WeatherNext → Open-Meteo policy; anything else
/// is an explicit pin and the backend returns that provider or an honest
/// `unavailable` — it never silently substitutes another one.
export enum DevSourcePin {
  Auto = "auto",
  WeatherNext = "weathernext",
  OpenMeteo = "openMeteo",
  Imd = "imd",
}

export const DEV_SOURCE_PIN_WIRE: Record<DevSourcePin, string> = {
  [DevSourcePin.Auto]: "auto",
  [DevSourcePin.WeatherNext]: "weathernext",
  [DevSourcePin.OpenMeteo]: "open_meteo",
  [DevSourcePin.Imd]: "imd",
};

export const DEV_SOURCE_PIN_LABEL: Record<DevSourcePin, string> = {
  [DevSourcePin.Auto]: "Auto (backend policy)",
  [DevSourcePin.WeatherNext]: "WeatherNext (pinned)",
  [DevSourcePin.OpenMeteo]: "Open-Meteo (pinned)",
  [DevSourcePin.Imd]: "IMD (pinned)",
};

/// WeatherNext model generation to request when the source is pinned or auto.
export enum DevWnModel {
  Wn3 = "wn3",
  Wn2 = "wn2",
}

export const DEV_WN_MODEL_WIRE: Record<DevWnModel, string> = {
  [DevWnModel.Wn3]: "weathernext_3",
  [DevWnModel.Wn2]: "weathernext_2",
};

export const DEV_WN_MODEL_LABEL: Record<DevWnModel, string> = {
  [DevWnModel.Wn3]: "WeatherNext 3 (0.1°)",
  [DevWnModel.Wn2]: "WeatherNext 2",
};

export interface DeveloperOptions {
  enabled: boolean;
  forcePeriod: SkyPeriod | null;
  forceSky: SkyCondition | null;
  forceTtsLocale: string | null;
  forceTtsSpeed: number | null;
  disableVideoSky: boolean;
  showProvenanceOnHome: boolean;
  showFieldSourceBadges: boolean;
  sourcePin: DevSourcePin;
  wnModel: DevWnModel;
  hourlyHours: number;
  forecastDays: number;
  supplementSecondaryFields: boolean;
  disableV2Fallback: boolean;
  logRequests: boolean;
}

export const DEFAULT_DEVELOPER_OPTIONS: DeveloperOptions = {
  enabled: false,
  forcePeriod: null,
  forceSky: null,
  forceTtsLocale: null,
  forceTtsSpeed: null,
  disableVideoSky: false,
  showProvenanceOnHome: false,
  showFieldSourceBadges: true,
  sourcePin: DevSourcePin.Auto,
  wnModel: DevWnModel.Wn3,
  hourlyHours: 48,
  forecastDays: 7,
  supplementSecondaryFields: true,
  disableV2Fallback: false,
  logRequests: true,
};

interface DeveloperOptionsStore extends DeveloperOptions {
  hydrated: boolean;
  hydrate: () => Promise<void>;
  patch: (patch: Partial<DeveloperOptions>) => Promise<void>;
  reset: () => Promise<void>;
}

function isDevSourcePin(value: unknown): value is DevSourcePin {
  return Object.values(DevSourcePin).includes(value as DevSourcePin);
}

function isDevWnModel(value: unknown): value is DevWnModel {
  return Object.values(DevWnModel).includes(value as DevWnModel);
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function persist(state: DeveloperOptions): void {
  void saveJson(StorageKeys.developerOptions, state);
}

export const useDeveloperOptionsStore = create<DeveloperOptionsStore>((set, get) => ({
  ...DEFAULT_DEVELOPER_OPTIONS,
  hydrated: false,

  hydrate: async () => {
    if (get().hydrated) return;
    const raw = await loadJson<Partial<DeveloperOptions> | null>(StorageKeys.developerOptions);
    set({
      ...(raw ?? {}),
      // A stale pin (e.g. AccuWeather, which the backend no longer ships) falls back to auto.
      sourcePin: isDevSourcePin(raw?.sourcePin) ? raw.sourcePin : DEFAULT_DEVELOPER_OPTIONS.sourcePin,
      wnModel: isDevWnModel(raw?.wnModel) ? raw.wnModel : DEFAULT_DEVELOPER_OPTIONS.wnModel,
      hourlyHours: clamp(Math.round(Number(raw?.hourlyHours ?? 48)), 1, 168),
      forecastDays: clamp(Math.round(Number(raw?.forecastDays ?? 7)), 1, 15),
      hydrated: true,
    });
  },

  patch: async (patch) => {
    const next: DeveloperOptions = {
      ...get(),
      ...patch,
      hourlyHours: patch.hourlyHours !== undefined ? clamp(patch.hourlyHours, 1, 168) : get().hourlyHours,
      forecastDays: patch.forecastDays !== undefined ? clamp(patch.forecastDays, 1, 15) : get().forecastDays,
    };
    set(next);
    persist(next);
  },

  reset: async () => {
    const next: DeveloperOptions = { ...DEFAULT_DEVELOPER_OPTIONS, enabled: get().enabled };
    set(next);
    persist(next);
  },
}));

/// Options that affect the weather request itself. Only these apply when
/// developer mode is *on*; with it off the app always uses defaults.
export function devOptionsRequestCustomised(dev: DeveloperOptions): boolean {
  return (
    dev.sourcePin !== DevSourcePin.Auto ||
    dev.wnModel !== DevWnModel.Wn3 ||
    dev.hourlyHours !== 48 ||
    dev.forecastDays !== 7 ||
    !dev.supplementSecondaryFields
  );
}
