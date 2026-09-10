# Web App API contract audit

Audited source: `../Web App/backend/main.py` and `../Web App/frontend/src/api.js`.
No `WeatherGPT_Architecture.md` file was present. The web client configures its base URL as `VITE_API_URL`, falling back to `http://localhost:8888`; it sends no authentication header. The mobile app uses `BACKEND_URL` in `.env`.

## Backend endpoints

| Method | Path | Request | Response |
|---|---|---|---|
| POST | `/chat` | `{ message: string = "", messages: [{ role: string, content: string }] = [], location: string = "", language: string = "English", farmer_mode: bool = false, crop: string = "" }` | `{ response: string }` |
| POST | `/dev/sandbox` and `/dev/sandbox/` | `{ prompt: string, location: string = "New Delhi", language: string = "English" }` | Success: `{ status: "success", duration_ms: number, prompt: string, location: string, language: string, response: string, model_used: string, timestamp: string }`; failure: `{ status: "error", duration_ms: number, error: string, timestamp: string }` (HTTP 500). |
| GET | `/health` and `/health/` | None | `{ status: "ok" }` |
| GET | `/dev` and `/dev/` | None | Diagnostics including `status`, `timestamp`, `server_start_time`, `uptime_seconds`, `system`, `llm_config`, `provider_keys_status`, `registered_endpoints`, `registered_ai_tools`, and `recent_logs`. |

## Client-only external calls

The existing web app fetches Open-Meteo data directly rather than through the FastAPI backend:

- `https://air-quality-api.open-meteo.com/v1/air-quality` with `latitude`, `longitude`, `current`, and `timezone=auto`.
- `https://geocoding-api.open-meteo.com/v1/search` with `name`, `count=1`, and `language=en`.

Its weather forecast is assembled client-side by `getEnsembleWeather`, not a FastAPI route. The backend `.env.example` defines `GROQ_API_KEY`, optional `GROQ_MODEL`, provider keys (`WEATHERAPI_KEY`, `TOMORROW_KEY`, `OPENWEATHER_KEY`, `ACCUWEATHER_KEY`), plus `IMD_API_KEY` and `IMD_JWT_TOKEN` for future official IMD integration.
