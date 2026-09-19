# Pending backend patches

Patches here are backend (`omsenjalia/weathergpt`) commits that accompany an
app change but could not be pushed to the backend repository from the
environment that produced them (no write access). The `backend/` submodule
pointer stays on the last published backend commit so clones never dangle.

Apply on a backend checkout:

```bash
cd backend
git checkout -b feat/v2-weather-supplement master
git am ../docs/patches/0001-backend-v2-weather-open-meteo-supplement.patch
cd ..
./scripts/push-all.sh "feat(v2/weather): Open-Meteo supplement with per-field attribution"
```

Then delete the patch from this folder in the same change.

| Patch | What it does | Tests |
|---|---|---|
| `0001-backend-v2-weather-open-meteo-supplement.patch` | `/v2/weather` and `/weather`: fill null secondary fields (humidity, pressure, wind dir, cloud, feels-like, UV, sunrise/sunset, AQI) from Open-Meteo with `field_sources` per-field attribution and `_supplement` metadata; `forecast_days` (1–15), `hourly_hours` (1–168), `supplement` params; `degraded` flag that ignores not-configured providers; hourly starts at the current UTC hour; daily rows gain weather_code, wind_kmh_max, sunrise, sunset, uv_index_max; env `WEATHER_SUPPLEMENT_ENABLED`. | `tests/test_forecast_supplement.py` (9) — full suite 129 passing |
