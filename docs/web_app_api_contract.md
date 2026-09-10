# API contract (audited 2026-09-10)

Audited source: `../Web App/backend/main.py` and `../Web App/frontend/src/api.js`.
No `WeatherGPT_Architecture.md` file was present. The web client configures its base URL as `VITE_API_URL`, falling back to `http://localhost:8888`; it sends no authentication header. The mobile app uses `BACKEND_URL` in `.env`.

## Backend endpoints

| Method | Path | Request | Response |
|---|---|---|---|
| POST | `/chat` | `{ message: string = "", messages: [{ role: string, content: string }] = [], location: string = "", language: string = "English", farmer_mode: bool = false, crop: string = "" }` | `{ response: string }` |
| POST | `/voice` | multipart: `audio?`, `transcript`, `language`, `lat`, `lon`, `crop` | `{ response: string }` |
| GET | `/weather` | `lat`, `lon`, `language?` | current conditions, current-day highs/lows and a 3-day forecast |
| GET | `/advisory` | `lat`, `lon`, `crop?`, `days?` | action-window suitability arrays plus a summary |
| GET | `/historical` | `lat`, `lon`, `metric`, `start_year?`, `end_year?` | `{ metric, points: [{ year, value }] }` |
| GET | `/comparison` | `locations=name,lat,lon;…`, `metric?`, years | `{ metric, locations: [{ name, points }] }` |
| POST | `/dev/sandbox` and `/dev/sandbox/` | `{ prompt: string, location: string = "New Delhi", language: string = "English" }` | Success: `{ status: "success", duration_ms: number, prompt: string, location: string, language: string, response: string, model_used: string, timestamp: string }`; failure: `{ status: "error", duration_ms: number, error: string, timestamp: string }` (HTTP 500). |
| GET | `/health` and `/health/` | None | `{ status: "ok" }` |
| GET | `/dev` and `/dev/` | None | Diagnostics including `status`, `timestamp`, `server_start_time`, `uptime_seconds`, `system`, `llm_config`, `provider_keys_status`, `registered_endpoints`, `registered_ai_tools`, and `recent_logs`. |

## Client-only external calls

The backend now proxies Open-Meteo for its mobile weather and research endpoints; the existing web app still makes its direct calls:

- `https://air-quality-api.open-meteo.com/v1/air-quality` with `latitude`, `longitude`, `current`, and `timezone=auto`.
- `https://geocoding-api.open-meteo.com/v1/search` with `name`, `count=1`, and `language=en`.

Its weather forecast is assembled client-side by `getEnsembleWeather`, not a FastAPI route. The backend `.env.example` defines `GROQ_API_KEY`, optional `GROQ_MODEL`, provider keys (`WEATHERAPI_KEY`, `TOMORROW_KEY`, `OPENWEATHER_KEY`, `ACCUWEATHER_KEY`), plus `IMD_API_KEY` and `IMD_JWT_TOKEN` for future official IMD integration.
