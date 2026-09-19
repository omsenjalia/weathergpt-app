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

## Status and remaining work

Updated 2026-09-19. **This folder is intentionally still here.** The cleanup
policy above forbids deleting a plan whose required verification is incomplete
or whose component is unfinished, and the plan's own Done bar is "implemented and
tested app code **plus a compatible authorized backend**". The backend plan in
`feature/backend/` is unimplemented, so live rollout of the app changes below is
still gated.

### Implemented in this repository

| Plan item | Where |
|---|---|
| 1. Typed provenance, nullable parsing, no `0` defaults | `lib/core/models/json_values.dart`, `lib/core/models/data_provenance.dart`, `lib/models/weather.dart`, `lib/models/weather_parser.dart` |
| 1. Missing weather code is not "clear sky" | `lib/models/weather_parser.dart`, `SkyCondition.unknown` in `lib/features/home/theme/atmosphere_theme.dart` |
| 2. Validated mode propagation on forecast/chat/voice | `lib/core/models/app_mode.dart`, `lib/core/models/request_context.dart`, weather/chat/voice providers |
| 2. Real farm context, hardcoded `Wheat` removed | `lib/core/models/request_context.dart`, `chat_provider.dart`, `voice_provider.dart` |
| 3. Source/freshness bar + the two Everyone enrichments, mode-scoped | `lib/features/home/widgets/weather_provenance_bar.dart` |
| 3. Fixed hourly truncation removed | `lib/models/weather_parser.dart` (UI still shows a compact window) |
| 4. Canned favourable action windows removed; per-day verdict; refetch on location/profile change | `lib/features/farmer/providers/action_windows_provider.dart`, `models/advisory_models.dart`, `screens/action_windows_screen.dart` |
| 5. Canned voice cards removed; structured cards consumed when sent | `lib/features/voice/mappers/voice_response_mapper.dart`, `lib/features/voice/models/voice_card.dart` |
| 6. Real archive APIs replace constant demo charts | `lib/features/researcher/providers/{historical_data,comparison,anomaly_trends}_provider.dart` and their screens |
| 7. Stale-response guards on mode/location/profile change | generation + context-key guards in the chat, voice and advisory providers |
| 8. New loading/stale/unavailable/attribution strings in all 9 locales | `assets/translations/*.json` |

Tests: `test/app_mode_test.dart`, `test/json_values_test.dart`,
`test/weather_parser_test.dart`, `test/request_context_test.dart`,
`test/voice_response_mapper_test.dart`, `test/action_windows_test.dart`,
plus the existing advisory and localization key-set suites. `.github/workflows/ci-test.yml`
now runs `flutter analyze` as well as `flutter test`.

### Still open — blocked on the backend

- [ ] Farmer windows driven by real activity/date/window-scoped backend
      decisions with evidence, warnings and an explicit unavailable status. The
      app renders per-day decisions when they exist and shows unavailable when
      they do not; it does not compute windows itself.
- [ ] Chat/voice evidence and Jev confidence wired to a backend that returns
      typed cards. The parser is in place; no backend currently sends `card`.
- [ ] Researcher capability explorer, full variable/statistic/member/level/run
      selectors, profiles, ensembles, jobs and licensed exports. These need the
      versioned `/v2/...` contracts, which do not exist; the app deliberately
      does not call them.
- [ ] Source-pinned WeatherNext research queries and the IMD → WeatherNext →
      AccuWeather → Open-Meteo selection indicator. The app renders a reported
      source; it cannot select or verify one.
- [ ] Estimated-vs-observed labelling and 15-day horizon selection, which need
      the backend to report estimate flags and real horizons.
- [ ] Energy/marine panels (100 m wind, irradiance, SST) — no authorized fields
      yet.
- [ ] Device/networking, accessibility and large-text passes, and a credentialed
      smoke test against a staged backend.

### Verification performed and its limits

The sandbox used for this change had **no Flutter SDK** and no network route to
`pub.dev` or `storage.googleapis.com`, so `flutter test`/`flutter analyze` could
not be run locally. Verification ran through this repository's own CI
(`.github/workflows/ci-test.yml`, Flutter 3.44.0 stable) on the pull request.
Widget-level tests for the new screens were not added: the existing suite
deliberately avoids importing screens that pull in Hive, `speech_to_text` and
`geolocator`, which hang in headless CI. The mapping and parsing logic was
extracted into plugin-free libraries so it is covered by real unit tests
instead. Translations for the 8 non-English locales are machine-written and
should be reviewed by a native speaker before release.
