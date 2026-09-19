# WeatherGPT Mobile

WeatherGPT is a multilingual, voice-first weather companion for **SIH 2026**, problem statement **SIH26068** under the Disaster Management theme.

## TypeSafe System One (Jev)

Farm Action Windows and chat routing are backed by [TypeSafe AI](https://docs.typesafe.ai)'s
System One decision model (Jev) running **in the backend** — typed Choice/Score/Noul
questions over fused weather state return calibrated answers with confidence, and the app
renders a "System One · NN% confident" badge when the AI shaped a verdict. The integration
is fully backward-compatible: without a backend key everything falls back to deterministic
thresholds. The ready-to-apply backend change lives in `backend-integration/` (see its
README); API keys stay server-side.

## WeatherNext and Jev feature plans

Start with the [feature handoff guide](feature/README.md):

- **Backend — `omsenjalia/weathergpt/backend`:** [setup and file guide](feature/backend/README.md),
  [WeatherNext plan](feature/backend/weathernext_3_integration_plan.md),
  [45-feature Jev plan](feature/backend/jev_backend_plan.md), and backend-only environment templates.
  **Not implemented** — those plans remain in place.
- **Flutter app — this repository:** [setup and file guide](feature/app/README.md),
  [implementation plan](feature/app/implementation_plan.md), and a non-secret backend URL template.
  The app-only work in that plan is implemented; what is still blocked on the
  backend is listed in [the app status and remaining work](feature/app/README.md#status-and-remaining-work).

Durable app-side contracts — mode propagation, null semantics, provenance, the
optional chat/voice card, advisory per-day decisions and the researcher archive
views — live in [docs/app_data_contracts.md](docs/app_data_contracts.md).

Google/IMD/AccuWeather/Jev credentials belong only on the backend, never in the Flutter `.env`.


## Run locally

1. Start the API: follow `Web App/backend/README.md`.
2. Create `Mobile App/weathergpt_mobile/.env` (ignored by Git): `BACKEND_URL=http://10.0.2.2:8888`.
   Use `http://localhost:8888` for iOS simulator/desktop Flutter, or your computer's LAN IP for a physical device.
3. Run `flutter pub get` then `flutter run` in this directory.

For Render, deploy the backend first, then replace `BACKEND_URL` with its `https://…onrender.com` URL. API keys belong only in Render environment variables, never in the Flutter app.

## Pushing changes (required)

This repository links the backend as a git submodule, so changes go to **two remote repositories**:

| Where the change lives | Remote it is pushed to |
|---|---|
| Files under `backend/` (the `omsenjalia/weathergpt` submodule) | `github.com/omsenjalia/weathergpt` |
| Everything else, plus the `backend/` submodule pointer | `github.com/omsenjalia/weathergpt-app` |

**Always publish with [`scripts/push-all.sh`](scripts/push-all.sh) — never a bare `git push`:**

```bash
./scripts/push-all.sh "describe your change"
```

A bare `git push` only updates `weathergpt-app`. It would leave backend commits
unpushed inside `backend/` and would not move the submodule pointer that other
contributors and clones rely on.

On a fresh clone, initialise the submodule first (the script does this for you
too if it is missing):

```bash
git clone https://github.com/omsenjalia/weathergpt-app.git
cd weathergpt-app
git submodule update --init --recursive
```

## Stack and release

Flutter, Riverpod, Dio, Hive, Easy Localization, FL Chart, Open-Meteo, FastAPI, and Groq. Run `flutter test`, `flutter analyze`, then `flutter build apk --release` (output: `build/app/outputs/flutter-apk/app-release.apk`).

Set the `BACKEND_URL` repository secret in **Settings → Secrets and variables → Actions** for the Android build workflow.

## Team

Om Senjalia — mobile + backend; Om Vaghela — frontend/UI reference; Chaitanya Ghodasara — beta testing; Nidhi Patel — data curation; Vishrut Gandhi — presentations; Prachi — research.

## Developer options & Debug screen

Settings → Developer → *Enable developer options* unlocks:

| Control | Effect |
|---|---|
| Debug & state | Opens `/debug`: parsed snapshot, per-field sources, provider chain & fallback reasons, request log (last 60 calls), `/v2/weather/health` |
| Pin forecast source | Sends `requested_source=<pin>`; an unavailable pin surfaces the backend error instead of silently falling back |
| WeatherNext model | Pins `model=` (WN3 0.1° default, WN2) |
| Hourly horizon / Forecast days | `hourly_hours` (6–168) and `forecast_days` (1–15) request parameters and the number of rows shown |
| Fill missing fields from Open-Meteo | `supplement=` toggle; off = raw provider only, so "—" shows exactly what the primary source lacks |
| Disable legacy /weather fallback | Surface `/v2/weather` errors instead of retrying `/weather` |
| Show provenance bar on Home | Brings the source/run/freshness chip row back under the hero card (off by default; the compact status line is shown instead) |
| Per-field source badges | "via Open-Meteo" pills on supplemented tiles |
| Record request log | Feed the Debug screen's Requests tab |

Everything in this section is developer-only: none of it changes what users
see unless developer options are enabled.
