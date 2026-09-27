# Flutter → React Native Migration

**Date**: September 2026 · **Scope**: full codebase port of WeatherGPT Mobile

The Flutter/Dart app (`lib/`, 103 Dart files, ~20,200 lines) has been ported to
**React Native (Expo SDK 54)** with TypeScript. The port runs on web (this
repo's Freebuff preview) and compiles to native iOS/Android via
`npx expo prebuild` / EAS Build.

## Mapping table

| Flutter (before) | React Native (after) |
| :--- | :--- |
| Flutter SDK 3.44 + Dart | Expo SDK 54 + TypeScript 5.9 (strict) |
| Riverpod 2.6 providers/notifiers | Zustand 5 stores (`src/**/[ STORE ].ts`) |
| Hive boxes | AsyncStorage (`src/lib/persistence.ts`) |
| GoRouter ShellRoute | expo-router v6 (`app/` file tree, `(tabs)` group) |
| Dio 5 + interceptors | fetch-based `ApiClient` (`src/core/services/apiClient.ts`) |
| easy_localization + 9 JSON assets | typed i18n engine (`src/i18n/`), same JSON files reused |
| fl_chart | react-native-svg `LineChart` (`src/ui/components/`) |
| gpt_markdown (GptMarkdown) | `RichText` renderer (`src/ui/components/RichText.tsx`) |
| flutter_tts | expo-speech (voice store) |
| speech_to_text (native channel) | expo-speech-recognition ~3.1.3; capability/permission checked, typed fallback |
| geolocator / permission_handler | expo-location ~19.0.8 foreground permissions and GPS |
| webview_flutter (Windy embed) | `iframe` on web, react-native-webview 13.15.0 on Android/iOS |
| flutter_dotenv + --dart-define | `EXPO_PUBLIC_BACKEND_URL` (see `.env.example`) |
| Material 3 + google_fonts | react-native-web + system font stack, same tokens |

## What was preserved exactly

- **Null semantics** (`src/core/models/jsonValues.ts`): absent / wrong-typed /
  blank / NaN / infinite values → `null`. A missing `weather_code` is never
  read as `0` ("clear sky"); hourly buckets without a temperature are dropped.
- **WeatherNext-first fetch policy** (`src/features/weather/weatherStore.ts`):
  `/v2/weather` primary with honest legacy `/weather` fallback, `status:
  "unavailable"` surfaced instead of silently re-asking a pinned source,
  exact request info recorded for the Debug screen.
- **Provenance model** (`src/core/models/dataProvenance.ts`): unconfigured
  providers are not degradation; backend `degraded` verdict wins; unknown age
  is never labelled stale (6-hour threshold).
- **Generation guarding** in chat, voice and advisory stores — a late answer
  from a superseded context is discarded, never rendered.
- **Mode propagation** (`src/core/models/appMode.ts`, `requestContext.ts`):
  explicit unknown mode is rejected (strict) or de-escalated (storage), farm
  context attached only in farmer mode, `farmer_mode` derived from `mode`.
- **Advisory honesty** (`src/features/farm/farmStores.ts`): no bundled
  favourable windows — unreachable backend shows the explicit unavailable
  state; each day reads its own `windows[i].ai.overall` decision, never the
  global verdict; cache keyed on `lat,lon|crop|stage|soil|irrig|UTCdate`.
- **Voice cards**: numbers come only from a backend-sent structured card;
  prose-only answers stay prose-only (no fabricated rain %).
- **Atmosphere engine** (`src/features/weather/theme/atmosphereTheme.ts`):
  11 solar periods × 12 conditions with the same palettes, weather blending,
  luminance-based readability normalization and minute clock ticker.
- **9 live languages**: en, hi, gu, mr, ta, te, kn, ml, bn (287-key set,
  keyset test enforces parity; Punjabi remains planned).
- **Developer suite**: 5-tab debug screen (snapshot / sources / providers /
  requests ring buffer of 60 / health probe), source pinning, horizons,
  supplement toggle, v2-fallback kill switch — provider names stay
  developer-only on the home surface.

## Layout

```
app/                      expo-router routes (onboarding, (tabs)/, debug, farm-profile)
src/core/                 config, errors, models (jsonValues, appMode, provenance,
                          fieldSources, requestContext), services (api client,
                          request log, geocoding), theme, utils (markdown speech)
src/features/             weather, farm, chat, voice, settings, location, explore,
                          research, onboarding — each with models/stores/theme
src/i18n/                 9 locale JSONs (reused from assets/translations) + engine
src/ui/                   design tokens, spacing, shared components (GlassCard,
                          buttons, chips, AtmosphereBackground, NavigationShell,
                          LineChart, TimeWindowBar, RichText, ApiErrorView)
src/models/               location models + presets (was lib/models/location.dart)
test/                     vitest ports of the Dart fixture tests + stubs/
```

## Commands

```bash
bun install            # install
bun run typecheck      # tsc -b --noEmit (strict)
bun run test               # vitest — 124 tests over the ported pure logic
bunx expo start --web  # dev server
bunx expo export --platform web   # static web build (dist/)
bunx expo prebuild     # generate native ios/android projects
```

Backend contract, endpoints and fusion policy are unchanged and documented in
[`ARCHITECTURE.md`](ARCHITECTURE.md). The Flutter sources (`lib/`, `test/*.dart`,
`pubspec.yaml`, `android/`, `ios/`, Flutter CI workflows and bundled media assets)
were removed in the same change once the port passed typecheck, tests and the web
export; the translation JSONs live on under `src/i18n/locales/`, and the sky-video
attribution notes were retired with the assets (the gradient sky renders on every
platform, video skies remain a documented native enhancement).

## Post-migration audit (2026-09-26)

See [`docs/REACT_NATIVE_AUDIT.md`](docs/REACT_NATIVE_AUDIT.md) for verified fixes,
validation evidence and outstanding device/parity checks, and
[`docs/ANDROID_RELEASES.md`](docs/ANDROID_RELEASES.md) for nightly signing setup.
Android identity is restored to `com.weathergpt.weathergpt_mobile`. An upgrade
requires the same signing certificate as the installed Flutter APK. Hive data is
not automatically imported into AsyncStorage; users must repeat onboarding.
