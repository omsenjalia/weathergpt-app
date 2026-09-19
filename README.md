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

## Stack and release

Flutter, Riverpod, Dio, Hive, Easy Localization, FL Chart, Open-Meteo, FastAPI, and Groq. Run `flutter test`, `flutter analyze`, then `flutter build apk --release` (output: `build/app/outputs/flutter-apk/app-release.apk`).

Set the `BACKEND_URL` repository secret in **Settings → Secrets and variables → Actions** for the Android build workflow.

## Team

Om Senjalia — mobile + backend; Om Vaghela — frontend/UI reference; Chaitanya Ghodasara — beta testing; Nidhi Patel — data curation; Vishrut Gandhi — presentations; Prachi — research.
