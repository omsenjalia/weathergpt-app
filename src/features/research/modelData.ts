/// Researcher "Models" tab data: one forecast variable as an hourly series
/// (`/v2/weather/series`, with the WeatherNext ensemble spread when the
/// source has one) and the provider catalog (`/v2/weather/catalog`).

import { ApiEndpoints } from "../../core/config/apiEndpoints";
import { jsonBool, jsonDouble, jsonInt, jsonList, jsonMap, jsonString } from "../../core/models/jsonValues";
import { ApiClient } from "../../core/services/apiClient";
import { AppLocation } from "../../models/location";
import { ChartPoint } from "./researchStores";

export enum SeriesVariable {
  Temperature = "temperature_2m",
  Rainfall = "total_precipitation_1hr",
  Wind = "wind_speed_10m",
}

export interface ForecastSeries {
  /// "ok" when values came back; anything else carries `detail`.
  status: string;
  detail: string | null;
  units: string;
  source: string | null;
  model: string | null;
  members: number | null;
  initTimeUtc: Date | null;
  /// Epoch ms of the first value; chart x is hours after it.
  startMs: number;
  mean: ChartPoint[];
  p10: ChartPoint[];
  p90: ChartPoint[];
}

export interface CatalogProvider {
  id: string;
  name: string;
  coverage: string;
  products: string[];
  hourly: boolean;
  ensemble: boolean;
}

export function forecastSeriesFromJson(data: Record<string, unknown>): ForecastSeries {
  const provenance = jsonMap(data["provenance"]);
  const rows = jsonList(data["values"])
    .map((item) => jsonMap(item))
    .filter((row): row is Record<string, unknown> => row !== null)
    .map((row) => ({ ms: Date.parse(jsonString(row["time_utc"]) ?? ""), row }))
    .filter(({ ms }) => !Number.isNaN(ms));
  const startMs = rows[0]?.ms ?? Date.now();
  const pick = (key: string): ChartPoint[] =>
    rows.flatMap(({ ms, row }) => {
      const value = jsonDouble(row[key]);
      return value === null ? [] : [{ x: (ms - startMs) / 3_600_000, value }];
    });
  const mean = pick("mean");
  const init = jsonString(provenance?.["init_time_utc"]);
  const status = jsonString(data["status"]) ?? "unavailable";
  return {
    status,
    detail: status === "ok" ? null : (jsonString(data["error"]) ?? status.replace(/_/g, " ")),
    units: jsonString(data["units"]) ?? "",
    source: jsonString(data["source"]),
    model: jsonString(provenance?.["model"]),
    members: jsonInt(data["members"]),
    initTimeUtc: init === null ? null : new Date(init),
    startMs,
    // Deterministic sources only send `value`.
    mean: mean.length > 0 ? mean : pick("value"),
    p10: pick("p10"),
    p90: pick("p90"),
  };
}

export function catalogFromJson(data: Record<string, unknown>): CatalogProvider[] {
  return jsonList(data["providers"]).flatMap((item) => {
    const row = jsonMap(item);
    const id = jsonString(row?.["id"]);
    if (row === null || id === null) return [];
    return [
      {
        id,
        name: jsonString(row["name"]) ?? id,
        coverage: jsonString(row["coverage"]) ?? "",
        products: jsonList(row["products"]).flatMap((p) => jsonString(p) ?? []),
        hourly: jsonBool(row["hourly"]) ?? false,
        ensemble: jsonBool(row["ensemble"]) ?? false,
      },
    ];
  });
}

/// Researcher mode pins WeatherNext; the backend falls back and says so.
export async function fetchForecastSeries(variable: SeriesVariable, location: AppLocation): Promise<ForecastSeries> {
  const data = await ApiClient.get(ApiEndpoints.v2WeatherSeries, {
    lat: location.lat,
    lon: location.lon,
    variable,
    requested_source: "weathernext",
  });
  return forecastSeriesFromJson(data);
}

export async function fetchCatalog(): Promise<CatalogProvider[]> {
  return catalogFromJson(await ApiClient.get(ApiEndpoints.v2WeatherCatalog));
}

/// "C" → "°" for chart ticks; other units print as sent.
export function tickUnit(units: string): string {
  return units === "C" ? "°" : "";
}

export function displayUnit(units: string): string {
  return units === "C" ? "°C" : units;
}

export function sourceLabel(series: ForecastSeries): string {
  if (series.model !== null && series.model.startsWith("weathernext_")) {
    const major = series.model.split("_")[1];
    return `WeatherNext ${major ?? ""}`.trim();
  }
  if (series.source === "open_meteo") return "Open-Meteo";
  if (series.source === "imd") return "IMD";
  return series.source ?? "—";
}
