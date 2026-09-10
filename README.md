# WeatherGPT Mobile

WeatherGPT is a multilingual, voice-first weather companion for **SIH 2026**, problem statement **SIH26068** under the Disaster Management theme.

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
