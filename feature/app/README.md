# App files — use with omsenjalia/weathergpt-app

[Back to feature guide](../README.md) · [Backend files](../backend/README.md)

**Target:** this Flutter repository, from its root. This folder contains an implementation plan and a public configuration example, not new Dart feature code.

## Required final step: remove completed planning artifacts

The user requires the implementing AI to remove the temporary files in `feature/app/` **after this component is implemented and verified**. First preserve its lasting contracts, setup instructions, test/evaluation records and non-secret configuration examples in the owning repository, then update incoming links. Do not remove unfinished work or the other component's plans. Do not delete application code, tests, real environment/credential files or unrelated integration bundles. See the [cleanup policy](../README.md#mandatory-cleanup-after-implementation).

If these files are handed to an AI working in another checkout, carry this requirement with them. Copying templates or writing code without passing the required acceptance gates does not complete the plan. Report the cleanup and permanent documentation destinations in the final handoff.

## File-by-file instructions

| File | Purpose | Run or copy? |
|---|---|---|
| [implementation_plan.md](implementation_plan.md) | Everyone/Farmer/Researcher behaviour, models/providers/UI, backend contracts and tests | Read/use as the Flutter implementation specification. Do not execute. |
| [app.env.example](app.env.example) | Non-secret `BACKEND_URL` setting | Create or edit the app-root `.env` and set this value to your actual backend URL. Keep any other legitimate non-secret settings; do not overwrite blindly. |

**Do not copy anything from the backend environment templates into the app.** The current Flutter build bundles `.env` as an asset. Google credentials, OAuth secrets/refresh tokens, IMD/AccuWeather keys, Groq keys and `TYPESAFE_API_KEY` must remain server-side.

## What the app needs from the backend

- A reachable backend URL and compatible legacy/versioned weather/chat endpoints.
- Explicit mode support, real farm-context requests, source/freshness data and nullable fields.
- Structured date/window-specific Jev decisions and real chat/voice cards.
- Authorized capability/catalog/series/profile/ensemble/job contracts for Researcher mode.
- Stable error/permission/expiry behaviour and test fixtures before new screens use proposed endpoints.

Provider priority, scientific calculations, Google authentication, Jev calls and LangGraph execution belong to the backend. The app renders and requests results; Researcher mode is not an authorization bypass.

## Configure and run the existing app

1. Install a Flutter SDK compatible with this repository and the Android/iOS toolchain for your device.
2. In the **app repository root**, create/edit `.env` using [app.env.example](app.env.example). Set `BACKEND_URL` to the actual deployed HTTPS backend address, without adding secrets.
3. Run from the **repository root**, not `feature/app/`:

```bash
flutter pub get
flutter test
flutter analyze
flutter run
```

For an Android release build:

```bash
flutter build apk --release
```

These commands run/build the **current app**. They do not implement the planned WeatherNext/Jev features. New screens must be developed against approved mock fixtures, then a compatible staged backend. Flutter commands were not executed during this documentation split.

### Local device networking

Prefer a deployed HTTPS backend URL. For native local development only:

- Android emulator commonly reaches a backend on the same host through `http://10.0.2.2:8888`.
- iOS simulator can reach a same-Mac backend through `http://localhost:8888`.
- A physical phone needs a reachable computer LAN address, permitted platform network configuration, or a deployed backend URL; its `localhost` is the phone itself.
- A browser/remote preview must use a reachable URL or a configured same-origin proxy, never a sandbox's private localhost address.

## What remains to implement

Follow [the app checklist and tests](implementation_plan.md#4-concrete-app-delivery-checklist). Priorities are typed/nullable models, mode propagation, source/uncertainty display, removal of canned farm/voice data and complete authorized researcher views.

Keep Windy/Weather Lab behaviour unchanged during this split. The later auto-login/custom-map proposal remains withdrawn; no Google web-session credentials should be placed in the app.
