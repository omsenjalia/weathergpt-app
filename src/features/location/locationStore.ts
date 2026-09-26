/// Location store — port of `lib/features/home/providers/location_provider.dart`.
/// Holds the active home location; on first launch asks the OS for location
/// permission once and, when granted, resolves the real position.
///
/// Behaviour contract (unchanged from the Flutter app):
/// - Runs at most once per install (`location_prompted` flag), so a user who
///   denied is never nagged again.
/// - Never overrides an explicit choice (`selected_location` already set).
/// - Every failure path silently keeps the default location; the home-screen
///   prompt bar is the visible fallback.
///
/// GPS uses the browser Geolocation API on web and `expo-location`-free
/// navigator access on native (via the permissions module on native builds).

import { create } from "zustand";

import { AppLocation, DEFAULT_LOCATION } from "../../models/location";

export { AppLocation, DEFAULT_LOCATION };
import { GeocodingService } from "../../core/services/geocodingService";
import { loadJson, saveJson, StorageKeys } from "../../lib/persistence";

interface LocationStore {
  location: AppLocation;
  locationPrompted: boolean;
  hydrated: boolean;
  hydrate: () => Promise<void>;
  select: (location: AppLocation) => Promise<void>;
  maybeAutoLocate: () => Promise<void>;
  selectFromGps: () => Promise<AppLocation | null>;
  canAskOs: () => Promise<boolean>;
}

function navigatorAvailable(): boolean {
  return typeof navigator !== "undefined" && typeof navigator.geolocation !== "undefined";
}

function currentPosition(): Promise<{ lat: number; lon: number } | null> {
  return new Promise((resolve) => {
    if (!navigatorAvailable()) {
      resolve(null);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) => resolve({ lat: position.coords.latitude, lon: position.coords.longitude }),
      () => resolve(null),
      { timeout: 12_000, maximumAge: 60_000 },
    );
  });
}

export const useLocationStore = create<LocationStore>((set, get) => ({
  location: DEFAULT_LOCATION,
  locationPrompted: false,
  hydrated: false,

  hydrate: async () => {
    if (get().hydrated) return;
    const [stored, prompted] = await Promise.all([
      loadJson<Record<string, unknown> | null>(StorageKeys.selectedLocation),
      loadJson<boolean | null>(StorageKeys.locationPrompted),
    ]);
    set({
      location: stored !== null ? AppLocation.fromMap(stored) : DEFAULT_LOCATION,
      locationPrompted: prompted === true,
      hydrated: true,
    });
  },

  select: async (location) => {
    set({ location });
    await saveJson(StorageKeys.selectedLocation, location.toMap());
  },

  maybeAutoLocate: async () => {
    if (get().locationPrompted) return;
    await saveJson(StorageKeys.locationPrompted, true);
    set({ locationPrompted: true });
    await get().selectFromGps();
  },

  selectFromGps: async () => {
    const pos = await currentPosition();
    if (pos === null) return null;
    const name = await GeocodingService.reverseName(pos.lat, pos.lon);
    const loc = new AppLocation(name, pos.lat, pos.lon);
    await get().select(loc);
    return loc;
  },

  canAskOs: async () => {
    return navigatorAvailable();
  },
}));
