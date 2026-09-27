# WeatherGPT Mobile — Technical Architecture

> **Context**: Smart India Hackathon (SIH 2026) Technical Reference  
> **Problem Statement**: **SIH26068** — Disaster Management Theme  
> **Team**: **visionaries_bvm**  
> **Target Audience**: Evaluation Panel, Technical Judges, Systems Architects  
> **Last Updated**: 27 September 2026  
> **Status**: React Native app — typecheck, 148 unit tests and Expo bundles verified; native release/device acceptance pending
> **Backend**: `https://weathergpt-backend.vercel.app` — WeatherGPT API **v2.1.0** (submodule `backend/` → `omsenjalia/weathergpt`)
> **Mobile client**: **React Native (Expo SDK 54, React Native 0.81, TypeScript 5.9)** — ported from Flutter 3.44 (mapping table in [`FLUTTER_TO_REACT_NATIVE_MIGRATION.md`](FLUTTER_TO_REACT_NATIVE_MIGRATION.md)), then rebuilt around a voice-first UX, a shared design system (`src/ui`), looping video skies and Bhashini speech.

---

## Navigation Panel

| # | Section | Status | Key Technologies |
| :--- | :--- | :--- | :--- |
| [1. Executive Summary](#1-executive-summary) | System overview and innovations | Live | Expo SDK 54, Zustand 5, Bhashini |
| [2. High-Level Architecture](#2-high-level-architecture) | Mobile-to-cloud topology | Live | Mermaid, FastAPI |
| [3. Technology Stack and Design System](#3-technology-stack-and-design-system) | Frameworks and design tokens | Live | React Native, expo-router, `src/ui` |
| [4. Repository Structure](#4-repository-structure) | Codebase layout (app + backend) | Live | Feature-first modules |
| [5. Environment Variables and Secrets](#5-environment-variables-and-secrets) | Config and credential isolation | Live | EXPO_PUBLIC_BACKEND_URL, backend `.env`, signing |
| [6. Backend Integration and API Architecture](#6-backend-integration-and-api-architecture) | FastAPI routers and endpoints | Live | chat, mobile, weather_v2, speech, decisions, dev |
| [7. Mobile App Architecture](#7-mobile-app-architecture) | Routing, stores, persistence | Live | expo-router 6, Zustand 5, AsyncStorage |
| [8. Data Flow and Request Lifecycle](#8-data-flow-and-request-lifecycle) | Weather fetch and live sky | Live | fetch, generation-guarded stores |
| [9. AI Agent Architecture and Conversational Engine](#9-ai-agent-architecture-and-conversational-engine) | Routing policy, LangGraph, Groq | Live | LangGraph, Groq cascade, TypeSafe |
| [10. Multi-Source Ensemble Fusion Engine](#10-multi-source-ensemble-fusion-engine) | Provider selection, WeatherNext integration, supplementation | Live | IMD, WeatherNext, AccuWeather, Open-Meteo |
| [11. API Contract Reference](#11-api-contract-reference) | Request/response shapes | Live | /chat, /v2/weather, /v2/speech, /advisory |
| [12. Answer Cards and Markdown Rendering](#12-answer-cards-and-markdown-rendering) | RichText live; structured cards client-only | Partial | `card`, InsightCard, RichText |
| [13. Voice and Multilingual Engine](#13-voice-and-multilingual-engine) | 9 Indian languages + Bhashini | Live | Bhashini TTS/ASR, expo-speech-recognition, expo-audio |
| [14. Risk Assessment and Environmental Hazard Engine](#14-risk-assessment-and-environmental-hazard-engine) | Hazard advisory | Live | Backend-driven thresholds |
| [15. Agricultural Farmer Advisory Mode and TypeSafe System One](#15-agricultural-farmer-advisory-mode-and-typesafe-system-one) | Crop decisions | Live | Jev AI, Farm Action Windows |
| [16. Developer Diagnostics and Debug Suite](#16-developer-diagnostics-and-debug-suite) | 5-tab debug screen | Live | Request log, provider pinning |
| [17. Deployment and Release Architecture](#17-deployment-and-release-architecture) | CI/CD, signing, backend hosting | Live | GitHub Actions, Expo prebuild, Vercel |
| [18. Problem Statement and SIH Compliance Matrix](#18-problem-statement-and-sih-compliance-matrix) | SIH26068 compliance | Live | 10-domain matrix |
| [19. Future Roadmap and Planned Enhancements](#19-future-roadmap-and-planned-enhancements) | Roadmap | Planned | IMD APIs, radar, iOS, LoRaWAN |

---

## 1. Executive Summary

**WeatherGPT Mobile** is an AI-powered, voice-first weather intelligence app built for **SIH 2026** Disaster Management (SIH26068) by **Team visionaries_bvm**.

It turns multi-source meteorological data into actionable, hyper-local guidance in **9 Indian languages** (bn, en, gu, hi, kn, ml, mr, ta, te) with two-way voice: **Bhashini** neural TTS and ASR through the backend, with on-device speech as the fallback.

- **Framework**: React Native 0.81 on **Expo SDK 54** + TypeScript 5.9 strict; file-based routes in `app/`, feature modules in `src/`
- **State**: Zustand 5 stores · **Routing**: expo-router 6 · **Persistence**: AsyncStorage
- **Backend**: one FastAPI app (v2.1.0) serving the web client and this app, deployed on Vercel
- **Forecast policy**: **IMD → WeatherNext → AccuWeather → Open-Meteo** selection with per-field Open-Meteo supplementation and full provenance. The legacy weighted fusion (Open-Meteo 2.0×, AccuWeather 1.5×, WeatherAPI 1.2×, Tomorrow.io 1.2×, OWM 1.1×) survives only as the `GET /fusion` diagnostic.

### Core Innovations

- **Voice-first assistant**: a large voice orb on Home (`AskCard`), in the centre of the floating tab bar and in the chat composer opens a full-screen voice mode (`/voice`): listen → live transcript → answer → read aloud. Chat replies can be dictated and are read back.
- **Bhashini speech**: backend proxy (`/v2/speech/tts`, `/v2/speech/asr`) to MeitY's ULCA pipeline; credentials never reach the device. Female/male voice choice in Settings.
- **Persona-driven UI**:
  - **Everyone**: hero conditions over a live video sky, tappable hourly / 7-day / metric tiles that open detail sheets, AQI/UV, full-screen Windy map
  - **Farmer (Krishi)**: Farm tab with TypeSafe System One action windows (irrigation, spraying, field work); farm profile by form **or by voice**
  - **Researcher**: Lab tab with historical archive, anomaly bars and multi-location comparison; full Windy layer/model catalog
- **TypeSafe System One (Jev)**: server-side calibrated decisions with per-day confidence badges (`System One · 88% confident`)
- **Atmospheric sky engine**: 11 solar periods × 12 sky conditions drive a gradient palette, 6 bundled looping sky clips, and native-driver particles (rain, stars, lightning)
- **Zero-guesswork data**: missing values are `null` and render as "—", never `0 °C / 0 mm`. WMO code `0` = clear sky, `null` = unknown
- **Debug suite**: 5 tabs — Snapshot, Sources, Providers, Requests, Health

---

## 2. High-Level Architecture

```mermaid
graph TB
    subgraph "Mobile Client - React Native (Expo SDK 54)"
        UI["Screens + src/ui design system - live SkyBackground (gradient, video, particles)"]
        NAV["expo-router - index, onboarding, (tabs)/home|chat|farm|lab|explore|profile, voice, locations, farm-profile, debug"]
        STATE["Zustand stores - weather, chat, voice, location, farm, actionWindows, settings, developerOptions, map, savedLocations, requestLog"]
        CLIENT["ApiClient (fetch) - 60s timeout, Accept-Language, request ring buffer"]
        CACHE["AsyncStorage - wg.settings, wg.farm_profile, wg.saved_locations, ..."]
        VOICE["Voice - expo-speech-recognition (live transcript + WAV), expo-audio playback, expo-speech fallback"]
        GEO["Open-Meteo geocoding + BigDataCloud reverse geocode (keyless, direct)"]
        WEBVIEW["Windy embed - iframe (web) / WebView (native)"]
    end

    subgraph "FastAPI Backend v2.1.0 (Vercel)"
        API["main.py - CORS *, X-Request-ID, request log, JSON 500 guard"]
        RCHAT["routers/chat - POST /chat"]
        RMOB["routers/mobile - /weather, /advisory, /historical, /comparison"]
        RV2["routers/weather_v2 - /v2/weather (+catalog, series, profile, ensemble, tiles, cyclones, jobs, health)"]
        RSPEECH["routers/speech - /v2/speech/health|tts|asr"]
        RDEC["routers/decisions - /v2/decisions/*, /admin/decisions/*"]
        RDEV["routers/dev - /health, /dev, /fusion, /dev/sandbox, /dev/intent, ..."]
        CHATSVC["services/chat - greeting / fast telemetry / agent routing"]
        FORECAST["services/forecast - provider selection + supplement + cache"]
        DEC["services/decisions - 45-feature registry, engine, policy, audit"]
        JEV["services/typesafe - TypeSafe System One client"]
        AGT["agent.py + tools.py - LangGraph tool loop"]
        LLM["Groq cascade - gpt-oss-120b → qwen3.8 → qwen3.6 → gpt-oss-20b → safeguard-20b"]
        BH["services/bhashini - ULCA pipeline config + compute"]
    end

    subgraph "External Providers"
        IMD["IMD - primary when keys configured"]
        WN["Google DeepMind WeatherNext - BigQuery / GCS / Earth Engine"]
        AW["AccuWeather - fallback"]
        OM["Open-Meteo - baseline + supplement (sunrise, UV, AQI, humidity)"]
        BHX["Bhashini (MeitY ULCA / Dhruva)"]
        TS["TypeSafe AI"]
        GROQ["Groq"]
    end

    UI --> NAV --> STATE
    STATE --> CLIENT
    STATE --> CACHE
    STATE --> GEO
    UI --> VOICE
    UI --> WEBVIEW
    VOICE --> CLIENT

    CLIENT --> RCHAT & RMOB & RV2 & RSPEECH & RDEV

    RCHAT --> CHATSVC
    CHATSVC --> JEV
    CHATSVC --> FORECAST
    CHATSVC --> AGT
    AGT --> LLM --> GROQ
    AGT --> FORECAST
    AGT --> DEC
    RMOB --> FORECAST
    RMOB --> JEV
    RV2 --> FORECAST
    RDEC --> DEC
    DEC --> JEV
    JEV --> TS
    RSPEECH --> BH --> BHX

    FORECAST --> IMD & WN & AW & OM
```

---

## 3. Technology Stack and Design System

### 3.1 Mobile Client (`package.json`)

| Layer | Package | Version | Purpose |
| :--- | :--- | :--- | :--- |
| Framework | expo / react-native / react | ^54.0 / 0.81.5 / 19.1 | Cross-platform runtime (Android / iOS / web) |
| Language | typescript | ~5.9 (strict) | Typed source; `tsc -b --noEmit` gate |
| State | zustand | ^5.0 | Feature stores |
| Routing | expo-router | 6.0.24 | File-tree routes + `(tabs)` shell |
| HTTP | fetch (global) | — | `ApiClient` wrapper: timeout, error mapping, request log |
| Persistence | @react-native-async-storage/async-storage | 2.2.0 | JSON key-value store (`src/lib/persistence.ts`) |
| i18n | custom engine (`src/i18n`) | — | 9 eager-loaded JSON bundles, 312 keys each |
| TTS (primary) | Bhashini via `/v2/speech/tts` + expo-audio | ~1.1.1 | Indic neural voices (female/male); WAV played with expo-audio |
| TTS (fallback) | expo-speech | ~14.0.8 | On-device synthesis when Bhashini is unconfigured or failing |
| STT | expo-speech-recognition | ~3.1.3 | Live interim transcript; persists a 16 kHz WAV (where supported) that Bhashini ASR re-transcribes |
| Files | expo-file-system | ~19.0.24 | Read recorded WAV / write TTS audio to cache |
| Video sky | expo-video | ~3.0.16 | Looping bundled sky clips (`assets/sky/*.mp4`) |
| Haptics | expo-haptics | ~15.0.8 | Selection / light / success feedback on native |
| Clipboard | expo-clipboard | ~8.0.8 | Copy assistant replies |
| Browser | expo-web-browser | ~15.0.11 | Opens Google DeepMind Weather Lab (needs Google sign-in) |
| Typeface | @expo-google-fonts/manrope | ^0.4 | Manrope 300–800, tabular numerals for data |
| Navigation theme | @react-navigation/native | ^7.4 | Transparent dark theme so the sky shows through every route |
| Charts | react-native-svg | 15.12.1 | `LineChart`, `DeviationBars`, sun arc, sky glow |
| GPS | expo-location | ~19.0.8 | Foreground permission + position with 12 s timeout and stale-result guard |
| GIS | react-native-webview / web iframe | 13.15.0 | Windy.com embed |
| Gradients | expo-linear-gradient | ~15.0.8 | Atmosphere palette |
| Icons | @expo/vector-icons (MaterialCommunityIcons) | ^15.1 | Iconography |
| Gestures / screens | react-native-gesture-handler, -screens, -safe-area-context | ~2.28 / ~4.16 / ~5.6 | Native navigation primitives, insets |
| Animation | react-native-reanimated + react-native-worklets | ~4.1 / `0.5.1` (pinned via `overrides`) | No direct app usage (app animations use RN `Animated`); worklets pinned to the SDK 54 version because npm `latest` fails reanimated's version assertion on RN 0.81 |
| Web runtime | react-native-web + @expo/metro-runtime | ^0.21 / ~6.1 | Browser preview (`expo start --web`) |
| Tests | vitest | ^5.0 | 148 tests in 13 files: parsers, stores, generation guards, formatting, markdown, Bhashini speech paths, farm voice parser, i18n completeness, release config |
| Tooling | bun 1.4.2, Node ≥ 22.13 | — | Package manager (`bun.lock`) and runtime |

### 3.2 Backend (`backend/backend/requirements.txt`)

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| Web framework | FastAPI 0.115 + Uvicorn | Async REST API (port 8888 locally) |
| Agent | LangGraph 0.2 + langchain-core | Stateful tool-calling loop |
| LLM | langchain-groq | Groq model cascade |
| Decisions | TypeSafe AI (Jev) via httpx | Calibrated intent, advisory and reply checks |
| Speech | Bhashini ULCA via httpx | TTS / ASR proxy |
| HTTP | httpx | Provider ingestion |
| Validation | Pydantic v2 | Typed contracts (`schemas.py`) |
| WeatherNext | google-cloud-bigquery, google-cloud-storage, google-auth, earthengine-api, xarray/zarr/gcsfs | BigQuery tables, GCS statistics/ensembles, Earth Engine tiles |
| Language | langdetect | Reply-language normalisation |
| Tests | pytest | `backend/backend/tests/` (API, chat guard, fusion, speech, TypeSafe, WeatherNext) |

### 3.3 Design System (`src/ui`)

Semantic tokens live in `src/ui/theme/tokens.ts`; screens import from the `src/ui` barrel, never raw hex.

| Token group | Values | Usage |
| :--- | :--- | :--- |
| Canvas | canvas #0A1120, canvasDeep #060B16 | App background under the sky |
| Surfaces | surface rgba(9,15,30,.42), surfaceStrong .62, surfaceInset white 6% | Translucent cards over the live sky; one hairline, no drop shadows |
| Text | text #F8FAFC, secondary 72%, tertiary 50% | Hierarchy by opacity, not hue |
| Accent | teal #2DD4BF (accentText #5EEAD4) | The single accent: primary actions, selection, voice orb |
| Status | good #4ADE80, caution #FBBF24, danger #F87171, info #60A5FA | Semantic only (advisory bands, errors) |
| Personas | farmer #4ADE80, researcher #60A5FA | Persona chips/icons |
| Type scale | display 96 light, largeTitle 30, title 22, headline 17, body 15, callout 14, footnote 12, caption 11, metric 28, numeric 15 (tabular) | Manrope |
| Spacing / radius | 4-pt grid (2–48); radius 6–26 + pill | Gutter 20, max content width 640 |

- **Primitives** (`src/ui/primitives`): `AppText`, `Icon`, `Touchable` (press scale/dim + haptics), `Card`/`CardHeader`, `Button`/`IconButton` (44 pt targets), `SegmentedControl`, `Chip`/`ChipGroup`, `SwitchRow`, `ListRow`, `Divider`, `TextField`, `Skeleton`, `StateView`, `InlineBanner`, `Screen`/`Section`, `Sheet` (bottom sheet), `VoiceOrb` (idle breathing halo, listening rings, thinking/speaking/error states).
- **Shell** (`src/ui/shell`): `SkyBackground` (+ `SkyVideo`, `SkyParticles`), floating `TabBar` with a centre voice button, `useKeyboardVisible`.
- **Content** (`src/ui/content`): pure `markdown.ts` block parser + `RichText` renderer. **Charts** (`src/ui/charts`): `LineChart`, `DeviationBars`.

---

## 4. Repository Structure

```
weathergpt-app/
├── app/                                   # expo-router routes
│   ├── _layout.tsx                        # Fonts + store hydration, Bhashini probe, transparent nav theme, live sky
│   ├── index.tsx                          # First run → /onboarding, else → /home (+ one-time GPS auto-locate)
│   ├── onboarding/index.tsx               # One route, steps: welcome → language → persona → farm (talk / type / skip)
│   ├── (tabs)/
│   │   ├── _layout.tsx                    # Tabs + FloatingTabBar; Farm tab (farmer) or Lab tab (researcher)
│   │   ├── home.tsx                       # Conditions, AskCard, hourly, 7-day, metric tiles, detail sheets
│   │   ├── chat.tsx                       # Markdown chat, voice-first composer, voice turns read aloud
│   │   ├── farm.tsx                       # Farm profile summary + Today/Tomorrow/7-day action windows
│   │   ├── lab.tsx                        # Historical archive, anomaly bars, multi-location comparison
│   │   ├── explore.tsx                    # Full-screen Windy map, layer/model chips, zoom/locate FABs, Weather Lab link
│   │   └── profile.tsx                    # Settings: persona, language, units, voice, data, developer
│   ├── voice.tsx                          # Full-screen voice assistant (transparent modal)
│   ├── locations.tsx                      # Location picker modal: search, GPS, saved, popular places
│   ├── farm-profile.tsx                   # Farm profile editor (form or voice)
│   ├── debug.tsx                          # 5-tab debug suite
│   └── +not-found.tsx
├── assets/sky/                            # day / night / rain / sunrise / sunset / thunder .mp4 + ATTRIBUTION.txt
├── src/
│   ├── core/
│   │   ├── config/                        # apiEndpoints.ts (all paths incl. /v2/speech/*), backendConfig.ts
│   │   ├── errors/appErrors.ts            # NetworkError / ServerError / ValidationError
│   │   ├── models/                        # appMode, requestContext, dataProvenance, fieldSources, jsonValues
│   │   ├── services/                      # apiClient, geocodingService, requestLog
│   │   ├── theme/appColors.ts, utils/     # markdownUtils (forSpeech, spokenSummary), temperature
│   ├── features/
│   │   ├── app/bootstrap.ts               # useAppReady, useAgentContextSync, useSkyScene
│   │   ├── weather/                       # weatherStore (+ skyScene), format.ts, models/ (weather, parsers),
│   │   │                                  #  theme/atmosphereTheme.ts, components/ (CurrentConditions, AskCard,
│   │   │                                  #  HourlyForecast, DailyForecast, MetricTiles, DetailSheets, HomeSkeleton)
│   │   ├── voice/                         # voiceStore, speechService (Bhashini), models/voiceCard, mappers/
│   │   ├── chat/                          # chatStore; components/ (MessageItem, InsightCard, Composer)
│   │   ├── farm/                          # farmStores (profile + action windows), models/ (advisory, options,
│   │   │                                  #  profile, farmVoiceParser), components/ (FarmProfileForm,
│   │   │                                  #  FarmVoiceFlow, SuitabilityTrack)
│   │   ├── location/                      # locationStore; components/LocationPromptBar
│   │   ├── explore/exploreStores.ts       # savedLocations + Windy map store, embed / Weather Lab URL builders
│   │   ├── research/researchStores.ts     # /historical + /comparison fetchers and statistics
│   │   ├── settings/                      # settingsStore, developerOptionsStore, models/ttsVoiceOption
│   │   └── onboarding/onboardingStore.ts
│   ├── i18n/                              # index.ts (translator, LANGUAGE_META), useTranslation, locales/*.json
│   ├── ui/                                # Design system: theme/, primitives/, shell/, content/, charts/
│   ├── models/location.ts                 # AppLocation, SavedLocation, DEFAULT_LOCATION
│   └── lib/persistence.ts                 # AsyncStorage JSON helpers + StorageKeys
├── test/                                  # vitest suites + stubs/ (RN, AsyncStorage, speech, recognition, audio, file-system, location)
├── .github/workflows/                     # ci-test, android-compile, ci-build-signed, nightly-release
├── backend/                               # Submodule omsenjalia/weathergpt (branch master)
│   ├── backend/                           # FastAPI app (see below)
│   ├── frontend/                          # React/Vite web client (own Architecture.md)
│   └── frontend-backup/
├── backend-integration/                   # Historical patch staging for the backend (TypeSafe); superseded by the submodule
├── docs/                                  # data contracts, API audit, release + audit notes
├── scripts/                               # configure-android-release.cjs, push-all.sh
└── app.json, app.config.js, metro/babel/tsconfig/vitest configs, bun.lock
```

Backend layout (`backend/backend/`):

```
main.py              app factory, CORS, request-ID/log middleware, service index at GET /
api/index.py         Vercel entry (re-exports app); vercel.json maxDuration 60 s
schemas.py, state.py pydantic contracts; uptime + recent-log ring buffer
agent.py, tools.py   LangGraph agent + telemetry tools (bind_tools/ToolNode parity)
routers/             chat, mobile, weather_v2, speech, decisions (+admin), dev
services/            chat (routing), forecast (+_models, _cache, _aggregation, _supplement), providers/
                     (imd, weathernext, accuweather, open_meteo), fusion (legacy), advisory, typesafe,
                     bhashini, config, response (sanitizer), weathernext_* (auth, bigquery, gcs, ee,
                     catalog, normalize, tools), decisions/ (registry, engine, policy, features, questions, audit)
tests/               pytest suites
```

---

## 5. Environment Variables and Secrets

### Mobile — `EXPO_PUBLIC_BACKEND_URL` (template: `.env.example`)

| Variable | Required | Value | Purpose |
| :--- | :--- | :--- | :--- |
| EXPO_PUBLIC_BACKEND_URL | No | `https://weathergpt-backend.vercel.app` (prod) <br> `http://localhost:8888` (local web) <br> `http://10.0.2.2:8888` (Android emulator) | FastAPI base URL. Resolution: `process.env.EXPO_PUBLIC_BACKEND_URL` (inlined by Metro) → `expoConfig.extra.BACKEND_URL` → production URL. `resolveBackendUrl()` trims quotes and trailing slashes. |

> **Credential isolation**: the app holds no provider, LLM, TypeSafe or Bhashini keys — only the backend URL. It calls two keyless services directly: Open-Meteo geocoding (place search) and BigDataCloud's client reverse-geocode (GPS place names). Everything else goes through the backend.

### Backend (`backend/backend/.env.example`)

| Variable | Purpose |
| :--- | :--- |
| GROQ_API_KEY, GROQ_MODEL | LLM access; `GROQ_MODEL` overrides the head of the cascade (default `openai/gpt-oss-120b`) |
| WEATHER_PROVIDER_PRIORITY | Override the IMD → WeatherNext → AccuWeather → Open-Meteo order |
| IMD_API_KEY, IMD_JWT_TOKEN | IMD provider (skipped, not "degraded", when absent) |
| ACCUWEATHER_KEY | AccuWeather fallback provider |
| WEATHERAPI_KEY, TOMORROW_KEY, OPENWEATHER_KEY | Legacy `/fusion` diagnostic providers only |
| WEATHERNEXT_ENABLED (default `0`), WEATHERNEXT_MOCK_DATA | Turn WeatherNext on; mock mode returns clearly labelled synthetic data without Google credentials |
| GOOGLE_CLOUD_PROJECT, GOOGLE_CLOUD_QUOTA_PROJECT | Billing / quota project (required when enabled) |
| GOOGLE_APPLICATION_CREDENTIALS_JSON, GOOGLE_APPLICATION_CREDENTIALS, GOOGLE_OAUTH_CLIENT_ID / _SECRET / _REFRESH_TOKEN / _REDIRECT_URI, WEATHERNEXT_AUTH_MODE (`adc` \| `oauth`) | Credential chain (§10) |
| WEATHERNEXT_SURFACE (`bigquery` \| `gcs_statistics`), WEATHERNEXT_TABLE_3 (alias WEATHERNEXT_BQ_SURFACE_TABLE / WEATHERNEXT_TABLE), WEATHERNEXT_TABLE_3_HR, WEATHERNEXT_TABLE_2, WEATHERNEXT_BQ_LOCATION (`US`) | BigQuery tables (fully qualified `project.dataset.table`) |
| WEATHERNEXT_BQ_MAX_BYTES_BILLED (100 GiB), WEATHERNEXT_BQ_COLUMN_PROFILE (`standard`), WEATHERNEXT_QUERY_TIMEOUT_SECONDS (25), WEATHERNEXT_NEAREST_RADIUS_KM (9) | Cost and lookup bounds |
| WEATHERNEXT_RUN_HOURS (0,6,12,18), WEATHERNEXT_DELIVERY_LATENCY_HOURS (7), WEATHERNEXT_MAX_RUN_ATTEMPTS (3), WEATHERNEXT_FRESHNESS_HOURS (24), WEATHERNEXT_CACHE_TTL_SECONDS (3600), WEATHERNEXT_MAX_HORIZON_HOURS (360) | Run selection, freshness, cache |
| WEATHERNEXT_GCS_ENSEMBLE_ROOT / _STATISTICS_ROOT, WEATHERNEXT_GCS_BUCKET_2/3, WEATHERNEXT_GCS_STATS_2/3, WEATHERNEXT_GCS_USER_PROJECT, WEATHERNEXT_EE_PROJECT | GCS Zarr and Earth Engine surfaces |
| TYPESAFE_WEATHERNEXT_MODE (`off` \| `shadow` \| `enforce`) | Whether Jev decisions act on WeatherNext evidence |
| WEATHER_SUPPLEMENT_ENABLED | Set `0` to disable Open-Meteo gap filling |
| TYPESAFE_API_KEY, TYPESAFE_ENABLED, TYPESAFE_* | System One: chat routing, reply check, abuse gate, advisory min confidence, timeouts, audit |
| BHASHINI_USER_ID, BHASHINI_ULCA_API_KEY, BHASHINI_PIPELINE_ID (optional) | Bhashini speech; default pipeline `64392f96daac500b55c543cd` |
| CHAT_TIMEOUT_SECONDS | Agent hard timeout (default 22 s) before the deterministic fallback |

### Android Release Signing (GitHub secrets)

| Secret | Type |
| :--- | :--- |
| KEYSTORE_BASE64 | Base64 keystore |
| KEYSTORE_PASSWORD | Keystore password |
| KEY_ALIAS | Key alias |
| KEY_PASSWORD | Key password |

The nightly release **fails closed** without these; the per-commit signed build falls back to Expo's debug keystore (see §17).

---

## 6. Backend Integration and API Architecture

### Endpoints

| Path | Method | Used By | Function |
| :--- | :--- | :--- | :--- |
| / | GET | Meta | Service index: version, client endpoint lists, provider priority, WeatherNext + Jev config, chat contract |
| /chat | POST | Mobile chat + voice, web | Conversational AI. Body: message, messages, location, lat, lon, language, mode, farmer_mode, crop, growth_stage, soil, irrigation. Returns `{response: markdown, meta}` (no `card` today — see §12) |
| /v2/weather | GET | Mobile primary | Provider-selected forecast: lat, lon, mode, requested_source, forecast_days, hourly_hours, supplement, model → `{current, hourly, daily, provenance, field_sources, temperature_spread, precip_next_24h, degraded}` or `{status: "unavailable", error}` |
| /v2/weather/health | GET | Debug (Health tab) | Provider health probe |
| /v2/weather/catalog | GET | Future / researcher | Entitlement-filtered WeatherNext capability metadata |
| /v2/weather/series, /profile, /ensemble | GET | Future / researcher | Variable time series, upper-air profile, ensemble member series |
| /v2/weather/tiles/{variable}/{run_id}/{z}/{x}/{y}.png | GET | Future | Run-keyed map tiles |
| /v2/weather/cyclones | GET | Future | Cyclone tracks |
| /v2/weather/jobs (+ `/{id}`, `/{id}/confirm`, DELETE `/{id}`) | POST/GET/DELETE | Future | Bounded scientific export/inference jobs |
| /v2/speech/health | GET | Mobile (startup probe) | `{provider, configured, pipeline_id, languages, tasks}` — no secrets |
| /v2/speech/tts | POST | Mobile voice | `{text ≤ 8000, language, gender}` → base64 WAV |
| /v2/speech/asr | POST | Mobile voice | `{audio_base64, language, audio_format, sampling_rate?}` → `{transcript}` |
| /weather | GET | Mobile legacy fallback | Legacy snapshot: current, hourly, forecast, AQI, UV, sunrise/sunset |
| /advisory | GET | Farm tab | Day-by-day suitability, 2-hour buckets (irrigation / spraying / field_work), System One decisions. `days` 1–7 (backend default 3; the app sends 7) |
| /historical | GET | Lab | Yearly series from the Open-Meteo archive (`source: "open-meteo-archive"`): `{metric, points: [{year, value}]}`; metric rainfall / temperature / humidity, years 2000–2024 by default |
| /comparison | GET | Lab | Same archive, several places: `{metric, locations: [{name, points}]}`; `locations=name,lat,lon;...` from saved locations, 2015–2024 by default |
| /v2/decisions/capabilities | GET | Agent / future clients | Authorised decision features, inputs, blockers per mode |
| /v2/decisions/evaluate | POST | Agent / future clients | Evaluate one feature for a location/time/activity |
| /v2/decisions/{id}, /{id}/feedback | GET/POST | Future | Decision result, user feedback |
| /admin/decisions/health, /replay, /evaluations/{id} | GET/POST | Ops (protected) | Counters, offline replay, shadow evaluation reports |
| /health | GET | Probes | `{status: ok}` |
| /dev | GET | Web dev view | `{ai_decisions, fusion weights, provider_keys_status, recent_logs}` |
| /dev/sandbox | POST | Web dev view | Single-prompt sandbox with latency |
| /dev/intent | GET | Diagnostics | Intent routing inspector (same `decide_intent` as /chat) |
| /dev/weathernext, /dev/forecast, /dev/decisions | GET | Diagnostics | WeatherNext surface status, provider selection trace, decision-platform stats |
| /fusion | GET | Diagnostics | Legacy weighted inspector: provider values, weights, outlier flags |

All responses carry `X-Request-ID`; an unhandled exception becomes JSON `500 {detail, request_id}` so clients never receive HTML.

### Chat Lifecycle

```mermaid
sequenceDiagram
    actor User
    participant UI as Chat / Voice screen
    participant Client as ApiClient (fetch)
    participant Router as routers/chat
    participant Service as services/chat
    participant Jev as TypeSafe System One
    participant Agent as LangGraph Agent
    participant Forecast as services/forecast

    User->>UI: "Will it rain on my wheat crop?"
    UI->>Client: POST /chat + Accept-Language + mode + farm context
    Client->>Router: {message, messages, location, lat, lon, language, mode, crop, ...}
    Router->>Service: run_chat

    alt Greeting / meta
        Service-->>Client: canned intro (no upstream calls)
    else
        Service->>Jev: decide_intent (≤ 3 s, keyword fallback)
        Jev-->>Service: {intent, engine: system-one|keywords, confidence}
        alt Simple weather question
            Service->>Forecast: deterministic telemetry
            Forecast-->>Service: provider-selected data
            Service-->>Client: markdown
        else Complex / multilingual / farm / research
            Service->>Agent: run_weather_agent (hard timeout 22 s)
            Agent->>Forecast: tool calls (weather, AQI, crop, WeatherNext, decisions)
            Agent-->>Service: answer + evidence
            Service->>Jev: optional reply-evidence check
            Service-->>Client: {response, meta}
        end
    end
    Note over Service: agent timeout / error / no key → deterministic telemetry fallback

    Client-->>UI: ChatMessage / VoiceResponse
    UI->>User: RichText and speech
```

---

## 7. Mobile App Architecture

```mermaid
graph TD
    ROUTES["Routes - home, chat, farm, lab, explore, profile, voice, locations, farm-profile, debug, onboarding"]
    COMPONENTS["Feature components - CurrentConditions, AskCard, DetailSheets, MetricTiles, Composer, InsightCard, SuitabilityTrack, FarmVoiceFlow"]
    UIKIT["src/ui - tokens, primitives, SkyBackground, TabBar, RichText, LineChart"]
    STORES["Zustand stores - weather, chat, voice, location, farmProfile, actionWindows, settings, developerOptions, map, savedLocations, requestLog"]
    BOOT["bootstrap.ts - hydration, context sync, sky scene"]
    PARSERS["Parsers - weatherV2Parser, weatherParser, jsonValues, voiceResponseMapper, farmVoiceParser"]
    SERVICES["Services - ApiClient, SpeechService, GeocodingService"]
    STORAGE["AsyncStorage (persistence.ts)"]
    DEVICE["Device - expo-location, expo-speech-recognition, expo-audio, expo-speech, expo-video"]

    ROUTES --> COMPONENTS --> UIKIT
    ROUTES --> STORES
    COMPONENTS --> STORES
    BOOT --> STORES
    STORES --> SERVICES
    STORES --> PARSERS
    STORES --> STORAGE
    STORES --> DEVICE
    SERVICES --> DEVICE
```

### Routing and Shell

- **Root layout** (`app/_layout.tsx`): waits for `useAppReady()` (Manrope fonts + hydration of settings, developer options, location, farm profile and saved locations; a font failure falls back to the system font), fires the non-blocking Bhashini probe, runs `useAgentContextSync`, and wraps a transparent-theme `Stack` in `SkyBackground` so the live sky shows behind every screen. `locations` is a modal that slides up from the bottom; `voice` is a transparent full-screen modal.
- **Entry** (`app/index.tsx`): `wg.onboarding_complete` decides `/onboarding` vs `/home`; returning users trigger a one-time GPS auto-locate.
- **Tabs** (`app/(tabs)/_layout.tsx`): Today · Chat · [Farm | Lab] · Map · Settings. Farmer gets **Farm**, Researcher gets **Lab**, Everyone gets neither. The `FloatingTabBar` has a centre voice orb that opens `/voice`.

### State Management (Zustand 5)

- **weatherStore** (`features/weather`): builds the `/v2/weather` query from mode + developer options, falls back to legacy `/weather` unless the failure is an honest "unavailable" for a pinned source or `disableV2Fallback` is on. Records `lastRequest` + `updatedAt`. Refreshing the same request (`snapshotKey`) keeps the snapshot visible; a new location/mode/pin clears it. Exposes `skyScene(now, snapshot, dev)` → `{period, sky, palette}` using the location's UTC offset.
- **chatStore**: messages, `sending`, error, generation guard. `setContext` (language, persona, location, farm profile) clears the conversation when context changes; `retryLast` replaces the failed user turn. `buildChatPayload` and the voice store share `buildAgentRequestContext` so chat and voice send identical context.
- **voiceStore**: `startListening` (full assistant turn → `/chat` → `mapBackendAnswer`) and `startDictation(onText)` (chat composer, farm voice flow). See §13 for the speech pipeline. Generation guard on cancel and on context change.
- **speechService** (`features/voice/speechService.ts`): `/v2/speech/health` probe, TTS/ASR calls, expo-audio playback (cache file on native, data URI on web), 12-entry audio cache, 5-minute back-off after a Bhashini failure.
- **locationStore**: active location; one-time OS permission prompt (`wg.location_prompted`), never overrides an explicit choice, GPS with 12 s timeout and a generation guard, reverse-geocoded name.
- **farmProfileStore** (`farmStores.ts`): profile + explicit completion flag (legacy saves count as completed). `save()` validates size, geocodes the farm place and makes it the active location.
- **actionWindowsStore** (`farmStores.ts`): `/advisory` for Today / Tomorrow / 7-day, cached per `contextKey = mode|lat,lon|crop|stage|soil|irrig|UTCdate`, generation guard, explicit unavailable state.
- **settingsStore**: language, persona (validated; unknown values rejected on write, de-escalated to `everyone` on read), °C/°F, TTS speed (0.3–1.0), Bhashini gender, device TTS locale, per-language voice picks, notification prefs.
- **developerOptionsStore**: enable flag, source pin, WeatherNext model, hourly (1–168) / daily (1–15) horizons, supplement toggle, disable-v2-fallback, request logging, forced sky period/condition, disable video sky, provenance display.
- **onboardingStore**: chosen language/persona; `completeOnboarding()` persists them, then updates the live settings store so the first Home fetch already uses them.
- **mapStore / savedLocationsStore** (`exploreStores.ts`): Windy layer / product / zoom (3–12), researcher menu + marker toggles, embed and Weather Lab URL builders; saved places.
- **researchStores**: `/historical` + `/comparison` fetchers, `ArchiveStatus` (available / empty / unsupported), long-term average and anomaly statistics.
- **requestLog** (`core/services`): 60-entry ring buffer of every backend call (status, duration, summary such as `source=weathernext · run=… · hourly=48`).

### Persistence (`src/lib/persistence.ts`)

`wg.settings`, `wg.selected_location`, `wg.location_prompted`, `wg.farm_profile`, `wg.farm_profile_completed`, `wg.saved_locations`, `wg.onboarding_complete`, `wg.developer_options`, `wg.location_banner_dismissed`. Read/write failures are swallowed so the app keeps working in memory. Flutter Hive data is **not** imported.

### Correctness Boundaries

- Every async store uses a **generation ID**; stale responses are discarded (weather, chat, voice, action windows, location GPS).
- Explicit "unavailable" responses never silently switch providers; a new location never shows the previous place's data.
- Missing tomorrow windows are unavailable, never copied from today; a missing best-window label never implies good conditions.
- The HTTP timeout (60 s) covers headers **and** body; non-object JSON on a 2xx is an error, not an empty success.
- °F conversion happens only at the presentation layer.
- `src/core/models/jsonValues.ts`: absent, wrong-typed, blank, NaN or Infinity → `null`. Hourly points without temperature are dropped, not drawn at 0. Missing WMO code → `SkyCondition.Unknown`, not clear.

---

## 8. Data Flow and Request Lifecycle

```mermaid
sequenceDiagram
    actor User
    participant App as Home (RN)
    participant Store as weatherStore
    participant Client as ApiClient
    participant APIv2 as /v2/weather
    participant API as /weather (legacy)

    User->>App: Open, pull-to-refresh, or return after >10 min
    App->>Store: fetchWeather(location, mode, dev)
    Store->>Client: GET /v2/weather {lat, lon, mode, requested_source, forecast_days=7, hourly_hours=48}
    Client->>APIv2: HTTP GET

    alt v2 success
        APIv2-->>Store: {current, hourly, daily, provenance, field_sources, ...}
        Store->>Store: parseWeatherSnapshotV2
        Store-->>App: snapshot + lastRequest
    else v2 {status: unavailable}
        Store-->>App: error (no silent provider switch)
    else v2 fails and fallback allowed
        Store->>API: GET /weather {lat, lon, mode, requested_source}
        API-->>Store: legacy payload
        Store->>Store: parseWeatherSnapshot
        Store-->>App: snapshot + usedLegacyFallback=true
    else Offline, no snapshot
        Store-->>App: error → StateView with retry
    end

    App->>App: skyScene → SkyPeriod (11) × SkyCondition (12) → palette + clip + particles
    App->>App: CurrentConditions, AskCard, Hourly, Daily, MetricTiles
```

A failed refresh while a snapshot is on screen keeps the data and shows an `InlineBanner` with retry. Tapping an hour, a day or a metric tile opens `WeatherDetailSheet` (hour / day / metric detail; a day's hours link to hour detail).

### Live Sky (`src/ui/shell`)

`SkyBackground` draws, bottom to top: the palette gradient (always), the looping clip from `clipFor(period, sky)` (thunder → rain → cloudy → time of day; fades in when ready), `SkyParticles` (rain streaks, twinkling stars, lightning; native-driver `Animated`), horizon warmth and a sun/moon glow, and a readability veil. `useSkyScene` re-evaluates every minute. Developer mode can force a period/condition or disable video (gradient only).

---

## 9. AI Agent Architecture and Conversational Engine

- **Routing policy** (`services/chat.py`): greeting/meta → canned reply; simple weather question → deterministic telemetry (no LLM); everything else → LangGraph agent with a hard timeout (`CHAT_TIMEOUT_SECONDS`, default 22 s) that falls back to deterministic telemetry on timeout, error or missing key. Research-grade asks (ensemble, profile, run, cyclone, export, inference, catalog) are forced onto the tool path.
- **Intent**: `decide_intent` asks TypeSafe System One (≤ 3 s, `TYPESAFE_INTENT_TIMEOUT_SECONDS`) and falls back to keyword classification. Labels: `greeting`, `unrelated`, `weather_current_or_forecast`, `rain_probability`, `weather_explanation`, `weather_comparison`, `historical_weather`, `weather_conversation`, `ensemble_query`, `profile_query`, `run_query`, `cyclone_query`, `export_query`, `inference_query`, `catalog_query`, `ambiguous`. `meta` reports `intent`, `intent_engine` (`system-one` | `keywords`) and confidence.
- **Tools** (`agent.py` / `tools.py`, same list for `bind_tools` and `ToolNode`): geocode_city, current / daily / hourly forecast, air quality, UV & sun, surface pressure & wind, agricultural crop telemetry, severe weather alerts; decision tools (list capabilities, evaluate decision, compare eligible windows, request missing context, assess reply evidence, get decision result); WeatherNext tools.
- **Decision platform** (`services/decisions/`): versioned registry of 45 features in six groups (routing 8, farmer 12, everyone 5, researcher 8, evidence/quality 7, ops 5), each with modes, required evidence, confidence gate and a release state (off / shadow / enforce); engine with cache and audit store; policy helpers (eligibility, warning floor, conservative merge, safety monotonicity).
- **Language**: `language` / `Accept-Language` codes are mapped to names (incl. Punjabi, Odia, Urdu, Assamese, Nepali on the backend); Indic city phrases are extracted (`"delhi me kal barish hogi?"` → Delhi).

```mermaid
graph TD
    Q["Agent turn"] --> M1["openai/gpt-oss-120b (GROQ_MODEL)"]
    M1 -->|429/Error| M2["qwen/qwen3.8-27b"]
    M2 -->|Error| M3["qwen/qwen3.6-27b"]
    M3 -->|Error| M4["openai/gpt-oss-20b"]
    M4 -->|Error| M5["openai/gpt-oss-safeguard-20b"]
    M5 -->|All fail / timeout| DET["Deterministic telemetry synthesizer"]
```

A separate text-only cascade (`groq/compound` → `groq/compound-mini` → `allam-2-7b`) handles non-tool generations.

---

## 10. Multi-Source Ensemble Fusion Engine

### Production Policy (`services/forecast.py`)

| Priority | Provider | Key | Role |
| :--- | :--- | :--- | :--- |
| 0 | IMD | IMD_API_KEY / IMD_JWT_TOKEN | Official India; key necessary but not sufficient (endpoints verified) |
| 1 | WeatherNext | Google IAM | Primary NWP (WN3 0.1° default, WN2 optional); no sunrise/UV/AQI |
| 2 | AccuWeather | ACCUWEATHER_KEY | Fallback |
| 3 | Open-Meteo | None | Baseline + supplement (sunrise/sunset, UV, AQI, humidity) |

**Rules**: for `auto`, pick the highest-priority *fresh* eligible source (a stale high-priority run never outranks a fresh lower one); explicit pins bypass substitution and return that provider or an honest `unavailable`; bounded timeouts, retry/back-off, circuit breaker and a shared LRU cache (1000 entries, 30 min TTL).

**App side**:
- `requested_source` is `auto`, or a developer pin (`weathernext`, `open_meteo`, `accuweather`, `imd`). Researcher mode pins `weathernext` unless a developer override says otherwise.
- `provenance: {selected_source, requested_source, fallback_reasons[], tried_providers[], source, product, run_id, issued_at, degraded}` and `field_sources: {temperature_c: "weathernext", humidity: "open_meteo", uv_index: null, _supplement: {provider, enabled, attempted, filled[], errors[], cache_hit}}` are parsed into `WeatherSnapshot` (`src/core/models/dataProvenance.ts`, `fieldSources.ts`).
- **What users see**: Home ends with a single "via &lt;selected source&gt;" caption. Endpoint / legacy-fallback / run details on Home, per-field "via …" rows, WMO codes and UTC timestamps in the detail sheets appear **only in developer mode**; the Debug screen is the canonical attribution surface.
- `degraded` is true only when a configured provider failed or was stale — not when IMD is skipped for a missing key.
- Enrichments (Everyone mode): `temperature_spread {p10_c, p90_c, source, run_id, valid_from, valid_to, members}` (rejected if inverted/one-sided) and `precip_next_24h {total_mm, start, end, complete}` (partial windows labelled).

### WeatherNext Integration (Google DeepMind)

WeatherNext is the priority-1 forecast source. It is an **ensemble** NWP model: every value the backend reads is a precomputed ensemble statistic (mean, p10, p25, p50, p75, p90) per lead time, not a single deterministic run. The code lives in `backend/backend/services/`:

| Module | Responsibility |
| :--- | :--- |
| `providers/weathernext.py` | Provider adapter: eligibility, cache, surface fallback chain, structured `fallback_reason`s |
| `weathernext_auth.py` | Credential chain + status reporting (never logs secrets) |
| `weathernext_bigquery.py` | Bounded, partition-filtered point queries on the WN3/WN2 tables (the live path) |
| `weathernext_gcs.py` | Zarr reader for GCS statistics and full ensembles (lazy `xarray`/`zarr`/`gcsfs`) |
| `weathernext_ee.py` | Earth Engine map tiles (display only; never used for point forecasts) |
| `weathernext_normalize.py` | Pure functions: raw extraction → `NormalizedForecast` (units, derived fields, `provenance.methods`) |
| `weathernext_catalog.py` | Capability catalog + surface access manifest (`/v2/weather/catalog`) |
| `weathernext_tools.py` | Allow-listed LangGraph tools (no arbitrary SQL/URLs) |
| `forecast_aggregation.py` | `temperature_spread`, `precip_next_24h`, member-first daily maths |
| `forecast_supplement.py` | Open-Meteo fill-in for fields WeatherNext does not carry |

#### Products and surfaces

| Surface | WN3 (`weathernext_3_0_0`) | WN2 (`weathernext_2_0_0`) | Backend route | Used by the app |
| :--- | :--- | :--- | :--- | :--- |
| BigQuery point statistics | `weathernext_3_0_0_0p1deg` (0.1°, 19 surface variables × 6 statistics); `…_0p05deg` (0.05°, station-head 2 m temperature / dew point) | WN2 table (`WEATHERNEXT_TABLE_2`) | `/v2/weather` | **Yes** — Home forecast |
| GCS statistics Zarr | `weathernext3_statistics_spatial` bucket | `weathernext2_statistics_spatial` | `/v2/weather` (fallback), `/series` | Indirectly (fallback surface) |
| GCS full ensemble Zarr (64 members) | `weathernext3_spatial` bucket | `weathernext2_spatial` | `/v2/weather/ensemble` | No (researcher API only) |
| Earth Engine map collections | `projects/gcp-public-data-weathernext/assets/weathernext_3_0_0_0p1deg` | WN2 collection | `/v2/weather/tiles/...` | No (map uses Windy; Weather Lab opens in browser) |
| Cyclone tracks | Weather Lab product | — | `/v2/weather/cyclones` (researcher only) | No — catalog blocker: no programmatic delivery contract confirmed |

The catalog lists nine granted surfaces. Each one is reported as `implemented` and only becomes `verified` after an operator's live probe (`WEATHERNEXT_VERIFY_*`). Other catalog states are `unverified`, `not_granted`, `blocked_by_terms`, `unsupported` and `planned`.

#### Request path (`/v2/weather` → WeatherNext)

```mermaid
graph TD
    REQ["ForecastService picks WeatherNext (auto policy or pin)"] --> MOCK{"WEATHERNEXT_MOCK_DATA=1?"}
    MOCK -->|yes| FAKE["Synthetic forecast stamped weathernext_3_0_0_mock"]
    MOCK -->|no| ELIG{"Eligible? enabled, valid lat/lon, credentials, forecast product"}
    ELIG -->|no| FB["fallback_reason → next provider (AccuWeather, Open-Meteo)"]
    ELIG -->|yes| CACHE{"Cache hit for model/table/profile/grid cell/horizon?"}
    CACHE -->|fresh| OUT["NormalizedForecast"]
    CACHE -->|miss / stale| CHAIN["Surface chain for the requested model"]
    CHAIN --> BQ["1. BigQuery point query"]
    BQ -->|fail| GCS["2. GCS statistics Zarr"]
    GCS -->|fail| FB
    BQ -->|ok| NORM["weathernext_normalize"]
    GCS -->|ok| NORM
    NORM --> OUT
    OUT --> SUP["forecast_supplement: Open-Meteo fills only null fields"]
    SUP --> AGG["temperature_spread + precip_next_24h"]
```

- **Model choice**: WN3 by default. WN2 is queried only when explicitly pinned (`model=weathernext_2`, the app's developer "WeatherNext 2" option). The backend never silently swaps WN3 for WN2, because the two use different schemas.
- **Run selection**: WN3 starts a new run every hour, but only the 00/06/12/18 UTC runs forecast 15 days ahead, and a run reaches BigQuery about 7 h after it starts. The adapter tries the newest expected run first, then steps back through up to 3 older runs (a missing partition costs nothing). It never queries partitions past the expiry horizon. Each payload comes from a single run, identified by `init_time` and reported as `run_id`.
- **Freshness**: a run up to 24 h old counts as fresh, up to 48 h as stale, older as expired. Cached results are shared per grid cell for 1 h and returned only while fresh (stale only if `allow_stale` is set). Pinning a specific `run_id` bypasses the cache.
- **Point lookup**: nearest grid cell within 9 km, using the clustered `geography` column (`ST_DWITHIN`).

#### BigQuery cost controls (`weathernext_bigquery.py`)

- Every query filters on an exact `init_time` partition, so the backend never scans the whole table.
- Queries read only explicit leaf columns of the repeated `forecast` record (never `SELECT *`). There are three column profiles:
  - `minimal`: temperature mean/p10/p90, precipitation mean/p90, wind speed mean.
  - `standard` (default): `minimal` plus dew point, precipitation p50, cloud cover and mean sea-level pressure.
  - `extended`: `standard` plus the full temperature and precipitation quantiles, wind p90 and U/V wind.
- Every job sets `maximum_bytes_billed` (default 100 GiB, which blocks a full-table scan but allows one partition). A job over budget fails without being charged.
- Waits are bounded (25 s), and a job that times out is cancelled. The adapter tracks per-process statistics (bytes billed/processed, cache hits, job IDs), which `/dev/weathernext` reports.

#### Scientific normalisation (`weathernext_normalize.py`)

- **Units**: native units stay on the wire and are converted once, here: K → °C, m → mm, m/s → km/h, Pa → hPa, cloud fraction → %.
- **Humidity**: derived from the 2 m temperature and dew-point means with the Magnus formula. It is `null` when dew point was not selected, e.g. in the `minimal` profile.
- **Condition / WMO code**: derived from the ensemble-mean precipitation rate and cloud cover:
  - ≥ 10 mm/h → 65, heavy rain
  - ≥ 2.5 mm/h → 63
  - ≥ 0.5 mm/h → 61
  - ≥ 0.1 mm/h → 51, drizzle
  - otherwise by cloud cover: 0 (clear), 1 (mainly clear), 2 (partly cloudy), 3 (overcast)

  WeatherNext carries no precipitation type or convective flags, so thunder and snow are never derived.
- **Rain probability**: an explicit **lower bound** from the precipitation quantiles at a 0.1 mm/h threshold. The daily value is the maximum of the hourly bounds.
- **Aggregation**: quantiles are never summed; only the mean, which is linear, is. Runs are never mixed. Wind speed is computed from U/V before averaging.
- **Current conditions**: taken from the lead time nearest to now. This is a forecast ensemble mean, not an observation: the app flags it with `currentIsEnsembleMean` and says so in the detail sheets.
- **Labelling**: every derived field is named in `provenance.methods`. Values that can't be derived are `null` with a reason, never made up.

#### What WeatherNext does not provide, and how gaps are filled

WeatherNext has no sunrise/sunset, UV index or air quality. A `minimal` profile also leaves humidity, pressure and cloud cover (and therefore the sky condition) unset. `forecast_supplement.py` makes one bounded Open-Meteo forecast call plus one air-quality call (6 s timeout each). It fills **only the `null` fields** and lists them in `field_sources._supplement.filled`. Temperature, precipitation, wind and run provenance are never overwritten. The app can turn this off with `supplement=false`; the backend with `WEATHER_SUPPLEMENT_ENABLED=0`.

#### Everyone-mode enrichments (`forecast_aggregation.py`)

- **`temperature_spread`**: the p10–p90 envelope over the next window, from the lowest p10 to the highest p90. It carries `source`, `run_id`, `valid_from`/`valid_to` and `members`. The app rejects inverted or one-sided spreads.
- **`precip_next_24h`**: the sum of hourly ensemble-mean amounts. It is marked `complete: false` when the horizon doesn't cover the full 24 h.

#### Credentials (`weathernext_auth.py`)

The first source that works wins:

1. `GOOGLE_APPLICATION_CREDENTIALS_JSON`: service-account JSON in an env var. This is the production (Vercel) path.
2. `GOOGLE_APPLICATION_CREDENTIALS` (a file path) or ambient ADC.
3. `GOOGLE_OAUTH_CLIENT_ID` + `_SECRET` + `_REFRESH_TOKEN`: owner-authorised OAuth. The refresh token is required; client ID and secret alone are not enough.

If every source fails, the provider reports `credentials_missing_credentials` and the chain falls through to the next provider. Health output shows only presence flags, redacted prefixes and error types. Credentials are cached per process.

#### Agent tools and diagnostics

- **LangGraph tools** (`weathernext_tools.py`), permission-checked and allow-listed:
  - `list_weathernext_capabilities`, `list_weathernext_runs`, `query_weathernext_data`
  - `get_weathernext_profile`, `analyze_weathernext_ensemble`, `compare_weathernext_products`
  - `get_weathernext_map_layer`, `get_weathernext_cyclone_tracks`
  - job prepare / submit / get / cancel

  Each tool returns an envelope: status, capability, model, run, effective query, sources, units, freshness, member/coverage counts, evidence ID, a summary and warnings. Chat intents `ensemble_query`, `profile_query`, `run_query`, `cyclone_query`, `export_query`, `inference_query` and `catalog_query` are routed to these tools.
- **`GET /dev/weathernext`**:
  - by default: offline config and credential presence, BigQuery adapter statistics, catalog coverage and provider priority
  - with `?probe=1`: also resolves the credential chain and dry-runs the point query (nothing billed), so the estimated bytes can be compared with the budget.
- **`GET /v2/weather/health`** and **`/dev/forecast`**: provider selection traces.
- **In the app**: the Debug screen's Providers tab shows `tried_providers` and `fallback_reasons` (e.g. `credentials_missing_credentials`, `surface_chain_exhausted`, `missing_dependency_gcs`). The Requests tab shows `source=weathernext · run=…` for each call.
- **Map**: the Explore tab's "Weather Lab" button opens Google DeepMind Weather Lab (WeatherNext 3, hourly precipitation layer) at the map centre in the system browser.

### Legacy Weighted Fusion (diagnostic `GET /fusion`, `services/fusion.py`)

| Provider | Weight | Key |
| :--- | :--- | :--- |
| Open-Meteo ECMWF/IMD | 2.0× | None |
| AccuWeather | 1.5× | ACCUWEATHER_KEY |
| WeatherAPI | 1.2× | WEATHERAPI_KEY |
| Tomorrow.io | 1.2× | TOMORROW_KEY |
| OpenWeatherMap | 1.1× | OPENWEATHER_KEY |

Formula: `M = Σ(M_i · W_i) / Σ W_i` · Outlier guard: `|T_i − T_OpenMeteo| > 7 °C` → excluded · Confidence: High ≤ 1.5 °C spread, Medium 1.5–3.5 °C, Low > 3.5 °C, Single-Source. Not used by the app's Home screen.

---

## 11. API Contract Reference

### POST /chat

Request (built by `buildChatPayload` / the voice store):
```json
{
  "message": "Is it safe to spray pesticide on my cotton crop today?",
  "messages": [{"role": "user", "content": "Is it safe to spray pesticide on my cotton crop today?"}],
  "location": "Rajkot, Gujarat, India",
  "lat": 22.3039,
  "lon": 70.8022,
  "language": "en",
  "mode": "farmer",
  "farmer_mode": true,
  "crop": "Cotton",
  "growth_stage": "Flowering",
  "soil": "Black",
  "irrigation": "Drip"
}
```

`mode` is authoritative; `farmer_mode` is derived from it. Farm fields are sent only in farmer mode with a completed profile. Voice turns send `message` only (no `messages` history). If the body's `language` is empty or English, the router falls back to a non-English `Accept-Language` header.

Before the reply is returned, `services/response.py` `sanitize_response` strips `<think>` blocks and reasoning preambles and validates any widget JSON.

Response:
```json
{
  "response": "## Spraying outlook for Rajkot\n\nWind under 15 km/h and no heavy rain in the next 24 h...",
  "meta": {
    "path": "agent",
    "client": "mobile",
    "language": "en",
    "location": "Rajkot, Gujarat, India",
    "intent": "weather_current_or_forecast",
    "intent_engine": "system-one",
    "intent_confidence": 0.92
  },
}
```

`ChatResponse` (`schemas.py`) also declares optional `weather_evidence`, `forecast_evidence`, `decision_evidence`, `provenance` and `mode` for future structured clients, but `routers/chat.py` currently fills only `response` and `meta`.

### GET /v2/weather (primary)

Query: `lat, lon, mode=everyone|farmer|researcher, requested_source=auto|weathernext|open_meteo|accuweather|imd, forecast_days (default 7), hourly_hours (default 48), supplement (sent only as false), model (sent only for weathernext_2)`

Response: `current, hourly, daily, provenance, field_sources, temperature_spread, precip_next_24h, degraded` — or `{status: "unavailable", error}`.

### GET /weather (legacy fallback)

Query: `lat, lon, mode, requested_source`. Older shape: `temperature_c, feels_like_c, condition, weather_code, high_c, low_c, rain_probability, wind_kmh, humidity, pressure_hpa, precipitation_mm, uv_index, sunrise, sunset, aqi, hourly[], forecast[], source, providers_used, fusion{confidence, temp_spread_c, weights}`

### /v2/speech/*

- `GET /v2/speech/health` → `{provider: "bhashini", configured, pipeline_id, languages: [en, hi, gu, mr, ta, te, kn, ml, bn], tasks: ["tts", "asr"]}`
- `POST /v2/speech/tts` `{text, language, gender}` → `{audio_base64 (WAV), audio_format, sample_rate, language, gender, chunks, truncated, provider, service_id}`. Long text is split into ~380-char chunks (max 2400; `truncated` flags the cut) and the WAVs concatenated by parsing the RIFF chunks directly (Bhashini returns IEEE-float WAVs, which Python's `wave` module rejects).
- `POST /v2/speech/asr` `{audio_base64, language, audio_format: "wav", sampling_rate?}` → `{transcript, language, sampling_rate, provider, service_id}`. Audio capped at ~3 MB (Vercel body limit).
- Errors: `503 {detail: {code: "speech_unavailable"}}` (not configured / language not served), `502 {detail: {code: "speech_upstream_error"}}`, `422` invalid input. Pipeline config is cached per task × language for 1 h.

### Other Endpoints

- `/advisory?lat=&lon=&crop=&days=7&mode=&growth_stage=&soil=&irrigation=` → `{summary, windows: [{date, suitability, summary, best_window, rain_probability, rain_mm, wind_kmh_max, high_c, hourly: {irrigation, spraying, field_work: [{hour, suitability}]}, ai: {spray, irrigation, fieldwork: {score, confidence, band}, overall: {choice, confidence}}}], advisory_engine, ai: {enabled, applied, model, evaluated_days, mean_confidence, overall_verdict}}`
- `/historical?lat=&lon=&metric=&start_year=&end_year=` → `{metric, points: [{year, value}]}`
- `/comparison?locations=name,lat,lon;...&metric=` → `{metric, locations: [{name, points}]}`
- `/dev/sandbox` POST `{prompt, location, language}` → `{status, duration_ms, response, model_used}`
- `/dev/intent?text=` → routing decision

Full per-field contracts: [`docs/app_data_contracts.md`](docs/app_data_contracts.md) and [`docs/web_app_api_contract.md`](docs/web_app_api_contract.md).

---

## 12. Answer Cards and Markdown Rendering

### Markdown (`src/ui/content`)

Every AI surface (chat bubbles, voice results) renders through one `RichText` component backed by the pure `markdown.ts` parser: headings, bold/italic, inline code, bullet and numbered lists, blockquotes, links, code blocks and pipe tables. Native-card payloads — ```` ```widget:* ```` fences, or JSON fences carrying a `"widget_type"` key — are **dropped**, so card instructions never leak into the conversation. The app does not render widget fences as cards.

For speech, `MarkdownUtils.forSpeech()` (`src/core/utils/markdownUtils.ts`) strips code/widget blocks, markdown, emojis, URLs and LaTeX delimiters and flattens tables to prose; `spokenSummary()` prefers the body after the heading block and trims to ~320 characters at a sentence boundary.

### Structured Cards (`card`) — client ready, backend not yet sending

> **Gap**: the app accepts an optional `card` object on `/chat` responses, but the backend's `ChatResponse` has no `card` field, so in practice every answer renders as prose only. The shape below is the contract the client parses (`src/features/voice/models/voiceCard.ts`, `InsightCard.tsx`); wiring it on the backend (e.g. from `decision_evidence`) is open work.

Expected shape:

```json
{
  "response": "Favorable conditions for wheat irrigation this morning.",
  "card": {
    "label": "Irrigation Outlook",
    "verdict": "Favorable for Irrigation",
    "explanation": "Soil moisture 38% and wind calm <10 km/h.",
    "cta_label": "Schedule Drip Irrigation",
    "source": "Open-Meteo (ECMWF)",
    "confidence": 0.88,
    "stats": [
      {"label": "Soil Moisture", "value": "38%", "tone": "good"},
      {"label": "Wind Speed", "value": "8 km/h", "tone": "good"}
    ],
    "forecast": [
      {"day": "Today", "temperature": "32°C", "rainfall": "0 mm", "condition": "sunny"}
    ]
  }
}
```

- **Chat**: `MessageItem` shows `InsightCard` (via `insightFromCard`) above the prose, plus copy and read-aloud actions.
- **Voice**: `mapBackendAnswer` (`src/features/voice/mappers/voiceResponseMapper.ts`) builds a `VoiceResponse` (label, verdict, accent, stats, forecast, explanation); the voice screen shows the same `InsightCard`.
- Numbers come **only** from a backend card. Prose-only answers render prose only — no fabricated stats; greetings never get weather cards. `CardTone`: `good | caution | avoid` (aliases: safe, favourable, watch, risk, poor).

---

## 13. Voice and Multilingual Engine

### Languages

| Language | ISO | Script | Device TTS locale | Device STT locale | File |
| :--- | :--- | :--- | :--- | :--- | :--- |
| English | en | English | en-US / en-IN | en-US | en.json |
| Hindi | hi | हिंदी | hi-IN | hi-IN | hi.json |
| Gujarati | gu | ગુજરાતી | gu-IN | gu-IN | gu.json |
| Marathi | mr | मराठी | mr-IN | mr-IN | mr.json |
| Tamil | ta | தமிழ் | ta-IN | ta-IN | ta.json |
| Telugu | te | తెలుగు | te-IN | te-IN | te.json |
| Bengali | bn | বাংলা | bn-IN | bn-IN | bn.json |
| Kannada | kn | ಕನ್ನಡ | kn-IN | kn-IN | kn.json |
| Malayalam | ml | മലയാളം | ml-IN | ml-IN | ml.json |

Bhashini serves TTS and ASR for all nine (ISO-639-1 codes). Punjabi is mapped in the STT table and on the backend but is not a shipped UI language.

- **Bundles**: `src/i18n/locales/<iso>.json` (the same content the Flutter app shipped), eager-loaded by `src/i18n/index.ts`. `useTranslation` re-renders on language change; onboarding uses `createTranslator(selected)` so it renders in the language being chosen before it is saved. Developer-only copy (Debug, Developer section) stays English.
- **Keyset guarantee**: vitest asserts every locale has all 312 English keys and translates each one.
- **Header**: `ApiClient` sends `Accept-Language: <iso>` from settings; `/chat` also carries `language`.

### Speech Pipeline

```mermaid
sequenceDiagram
    actor User
    participant VS as voiceStore
    participant Rec as expo-speech-recognition
    participant SS as SpeechService
    participant BE as Backend /v2/speech + /chat

    Note over SS,BE: App start: GET /v2/speech/health → configured?
    User->>VS: tap voice orb
    VS->>Rec: start(lang, interimResults, persist 16 kHz PCM WAV if Bhashini + recording supported)
    Rec-->>VS: interim transcript (shown live)
    Rec-->>VS: audioend(uri), end
    alt Bhashini available and WAV recorded
        VS->>SS: transcribe(uri, language)
        SS->>BE: POST /v2/speech/asr
        BE-->>SS: transcript (replaces device transcript when non-empty)
    end
    alt Dictation (chat composer / farm voice flow)
        VS-->>User: text handed to caller
    else Assistant turn
        VS->>BE: POST /chat (same context as chat)
        BE-->>VS: {response, meta}
        VS->>SS: speak(spokenSummary)
        SS->>BE: POST /v2/speech/tts (language, gender)
        BE-->>SS: WAV → expo-audio playback (rate mapped 0.75–1.25×)
    end
    Note over VS,SS: Any Bhashini failure → expo-speech / device transcript, Bhashini paused 5 min
```

- Voice entry points: Home `AskCard`, centre tab-bar orb, chat composer (empty composer shows a large mic; dictated turns are read back), `/voice` (with tappable persona suggestions as the typed path), and the farm profile voice flow.
- Settings → Voice: Bhashini female/male voice with preview, speed (slow / normal / fast); the footer says whether Bhashini or the device engine is active.
- Where recognition is unavailable (e.g. some web browsers, denied permission) the UI says so and offers suggestions / typing.

---

## 14. Risk Assessment and Environmental Hazard Engine

Hazard handling is **backend-driven**, not an in-app RED/YELLOW/GREEN threshold engine.

- **Sources**: severe-weather alert tool in the agent, advisory suitability `good | caution | avoid | neutral`, System One decisions (warning floor, conservative merge, safety monotonicity policies), chat markdown warnings
- **Rendering**: status tokens `danger #F87171`, `caution #FBBF24`, `good #4ADE80` in `SuitabilityTrack`, `InlineBanner`, `InsightCard` tones and metric-tile interpretations
- **No hardcoded 44 °C / 50 mm / 50 km/h thresholds in `src/`** — thresholds are evaluated server-side
- **Future**: direct IMD APIs for structured district warnings and cyclone tracks

---

## 15. Agricultural Farmer Advisory Mode and TypeSafe System One

### TypeSafe System One (Jev)

- **Server**: `backend/backend/services/typesafe.py` (httpx client), `advisory.py` hourly bands, `chat.py` intent routing + reply check, `decisions/` platform, `routers/dev.py` `ai_decisions`
- **Per-day decision**: each day reads its own `windows[i].ai.overall = {choice, confidence}`; only the 7-day overview uses the aggregate verdict and mean confidence
- **Badge**: `System One · NN% confident` only when that day carries a decision; otherwise rule-based thresholds (`AdvisorySource.Thresholds`)
- **No bundled offline advisory**: backend unreachable → explicit unavailable state, never demo bars. Cache keyed on `mode|lat,lon|crop|stage|soil|irrig|UTCdate`, discarded on move, profile edit or midnight (`unavailableActionWindows`, `contextKeyOf` in `src/features/farm/farmStores.ts`)

### Farm Profile (Onboarding and Settings)

- Picking **Farmer** in onboarding adds a **farm** step: *Talk* (`FarmVoiceFlow`), *Type* (`FarmProfileForm`) or *Skip for now* (keeps the default profile, not marked completed). The same two components power `/farm-profile`, reachable from the Farm tab and Settings.
- `FarmVoiceFlow` asks six questions (location, crop, growth stage, farm size, irrigation, soil) in the chosen language using voice dictation; each answer is parsed by `farmVoiceParser.ts` (en/hi/gu aliases, romanised forms, fuzzy longest-phrase match, Indic-digit sizes) or tapped from chips, then confirmed on a review list.
- Saving validates the size, geocodes the farm place and makes it the active location; the profile then feeds `GET /advisory` and `/chat` farm context (farmer mode + completed profile only).
- Option catalogs (`src/features/farm/models/farmOptions.ts`) are English wire values; `withCurrentOption` keeps a stored value present in its picker.
  - Crops: Wheat, Rice, Cotton, Maize, Sugarcane, Soybean, Groundnut, Mustard, Potato, Onion, Tomato, Pulses
  - Growth stages: Sowing, Germination, Vegetative, Flowering, Fruiting, Maturity, Harvest
  - Irrigation: Borewell, Canal, Drip, Sprinkler, Rainfed · Soil: Loamy, Clay, Sandy, Silty, Black, Red, Alluvial

### Farm Action Windows (Farm tab)

Today / Tomorrow / 7-day segments; three tracks (irrigation, spraying, field work) drawn by `SuitabilityTrack` from the backend's 2-hour buckets (7-day view: one cell per day), with the day's verdict, explanation, best window, "as of" time and System One badge.

```
[04:00-08:00] Good    (low wind <8 km/h)  <- optimal spray
[08:00-12:00] Caution (rising thermals)
[12:00-16:00] Avoid   (peak solar / evaporation)
[16:00-20:00] Good    (calm evening)
```

---

## 16. Developer Diagnostics and Debug Suite

Enable via **Settings → Developer → Developer mode**. The section then shows:

- **Show provenance on Home** — endpoint, legacy-fallback flag and run ID under the Home attribution line
- **Disable video sky** — gradient-only background
- **Source** pin chips — `DevSourcePin` auto / weathernext / open_meteo / accuweather / imd (surfaces honest failures instead of substituting)
- **Debug & state** → `/debug`

Detail sheets also gain per-field "via …" sources, WMO codes and UTC times in developer mode.

`/debug` — 5 tabs:

| Tab | Capability | Details |
| :--- | :--- | :--- |
| 1. Snapshot | Parsed snapshot | Fields, highs/lows, rain probability, solar times, last request |
| 2. Sources | Per-field attribution | `field_sources`, supplemented values |
| 3. Providers | Chain & degradation | Tried/skipped providers, fallback_reasons, degraded flag |
| 4. Requests | Ring-buffer log | Last 60 backend calls: status, duration, query, summary; clear |
| 5. Health | Backend probe | `GET /v2/weather/health` on demand |

`developerOptionsStore` also persists the WeatherNext model (`weathernext_3` / `weathernext_2`), hourly (1–168) and daily (1–15) horizons, the supplement toggle, disable-v2-fallback, request logging and forced sky period/condition. These are honoured by the weather request and sky scene but have **no Settings controls in the current build** (they only take effect if set in stored developer options).

---

## 17. Deployment and Release Architecture

```mermaid
graph LR
    subgraph "ci-test.yml (PRs, pushes)"
        T1["Node 22 + Bun 1.4.2"] --> T2["frozen install"]
        T2 --> T3["tsc strict + Vitest"]
        T3 --> T4["expo export --platform all"]
    end
    subgraph "android-compile.yml"
        A1["frozen install"] --> A2["expo prebuild -p android"]
        A2 --> A3["Java 17 · gradlew assembleDebug → debug APK artifact"]
    end
    subgraph "ci-build-signed.yml (PRs, push main/develop)"
        S1["expo prebuild"] --> S2["decode KEYSTORE_BASE64 or fall back to Expo debug keystore"]
        S2 --> S3["assembleRelease → release.apk artifact"]
    end
    subgraph "nightly-release.yml — daily 00:00 IST"
        N1["require signing secrets"] --> N2["typecheck + Vitest + prebuild"]
        N2 --> N3["assembleRelease + apksigner verify + SHA-256"]
        N3 --> N4["GitHub Release: release.apk + checksum"]
    end
```

- CI Test and Android Compile Check gate PRs. Debug APKs need Metro and are **not** standalone downloads; judges should use the nightly Release or the per-commit signed artifact.
- Nightly runs at **18:30 UTC / 00:00 IST** every day (plus manual dispatch). Missing signing secrets fail closed. The keystore lives in runner temp and is cleaned up even on failure; passwords are read from the environment.
- Backend URL for builds: `EXPO_PUBLIC_BACKEND_URL` repository variable → legacy `BACKEND_URL` secret → production URL.
- `app.config.js` validates `ANDROID_VERSION_CODE` (1–2,100,000,000) and takes `APP_VERSION`. Nightly: version code = Unix epoch minute, version name `1.0.0-nightly.YYYYMMDD` (IST); tags include run ID and attempt and point at the built SHA.
- Android identity stays **`com.weathergpt.weathergpt_mobile`** (Flutter's application ID) for same-certificate upgrades; permissions: coarse/fine location, `RECORD_AUDIO`. iOS bundle ID `com.visionariesbvm.weathergpt`. Hive data is not migrated.
- **Backend**: deployed to Vercel from the submodule (`api/index.py`, 60 s max duration); locally `uvicorn main:app --port 8888`.
- Native compilation, signing and device installation remain release gates not covered by a Metro export. See [release setup](docs/ANDROID_RELEASES.md) and [audit findings](docs/REACT_NATIVE_AUDIT.md).

---

## 18. Problem Statement and SIH Compliance Matrix

### SIH26068 Key Requirements

| Requirement | Implementation | Status | Source |
| :--- | :--- | :--- | :--- |
| Real-time telemetry | Temp, humidity, pressure, wind, UV, AQI via provider selection + supplementation | Live | `weatherV2Parser.ts`, `services/forecast.py` |
| Natural language querying | Routed chat: deterministic fast path + LangGraph/Groq agent | Live | `chatStore.ts`, `services/chat.py`, `agent.py` |
| NWP integration | WeatherNext (WN3/WN2), ECMWF/GFS/ICON via Open-Meteo and Windy | Live | `providers/weathernext.py`, `explore.tsx` |
| Extreme weather warnings | Severe-alert tool, advisory suitability, System One safety policies | Live | `tools.py`, `decisions/policy.py` |
| Agricultural advisories | Farm profile (form or voice) + System One action windows | Live | `features/farm/`, `services/advisory.py` |
| Multilingual support | 9 languages, Accept-Language, Bhashini TTS/ASR | Live | `src/i18n`, `speechService.ts`, `services/bhashini.py` |
| Historical trends | Multi-year archive, anomaly bars, multi-location comparison | Live | `app/(tabs)/lab.tsx`, `researchStores.ts` |
| Voice accessibility | Voice-first UI, hands-free ask, read-aloud, voice farm onboarding | Live | `voiceStore.ts`, `app/voice.tsx`, `FarmVoiceFlow.tsx` |

### 10-Domain Use Cases

| Domain | Stakeholders | Telemetry | Capability |
| :--- | :--- | :--- | :--- |
| Agriculture | Farmers, KVK | Soil moisture, rain prob, wind, temp | Crop advisories with Jev confidence |
| Disaster Management | NDRF/SDRF, Collectors | Extreme rain, wind gusts, WMO codes | Alert banners, emergency actions |
| Urban Health | Municipalities, Citizens | AQI, PM2.5, PM10, UV, heat index | Pollutant tracking, exposure warnings |
| Aviation & Drones | Pilots, Operators | Cloud cover, pressure, wind vectors | Windy GIS: cloud, pressure, CAPE, wind maps |
| Coastal Fisheries | Fishermen, Ports | Squally winds, waves, pressure drop | High-wind advisories, voice bulletins |
| Renewable Energy | Solar/Wind Operators | Irradiance, UV, 10 m wind | Solar and wind outlook |
| Logistics & Transport | Fleet, Highway Police | Fog codes, precipitation, visibility | Rainfall and fog advisories |
| Construction & Mining | Engineers, Safety | Lightning, gusts, wet bulb | Crane wind alerts, pour rain checks |
| Mountain Tourism | Pilgrims, Hikers | Sub-zero, snowfall, pressure trends | Pass weather guides |
| Climate Research | Climatologists, Labs | Multi-decade rainfall, temp anomalies | SVG LineChart anomalies, multi-city comparison |

---

## 19. Future Roadmap and Planned Enhancements

```mermaid
graph LR
    subgraph "Phase 2 Q4 2026"
        R1["Direct IMD API Suite - api.imd.gov.in"]
        R2["WeatherNext research surfaces in-app - series, ensemble, tiles, cyclones"]
        R3["iOS Build - TestFlight"]
    end
    subgraph "Phase 3 2027"
        R4["FCM Push - IMD severe alerts"]
        R5["Streaming voice - wake word 'Hey WeatherGPT'"]
        R6["LoRaWAN Mesh - KVK field stations"]
    end
    R1 --> R4
    R2 --> R5
    R3 --> R6
```

- **IMD direct APIs**: city forecast, district warnings, cyclone track, agromet, marine bulletins, radar
- **WeatherNext in the app**: the backend already exposes `/v2/weather/series|profile|ensemble|tiles|cyclones|jobs`; the Lab tab can adopt them (endpoints are already listed in `apiEndpoints.ts` for catalog/series)
- **Doppler radar**: DWR composite tiles, sub-30-min nowcasting
- **iOS**: Expo iOS build, background location, APNS via TestFlight
- **Voice**: on-device wake word, streaming Bhashini ASR, offline fallback voices for low-bandwidth areas; Punjabi UI
- **Push**: FCM-based IMD severe alerts (notification preferences are already stored in settings)
- **Structured answer cards**: return `card` (or typed `*_evidence`) from `/chat` so `InsightCard` renders real stats
- **Developer UI**: Settings controls for the horizon, model and supplement options already in `developerOptionsStore`
- **LoRaWAN**: low-cost KVK field stations for micro-climate ground truth

---

**Team**: visionaries_bvm  
**Backend**: https://weathergpt-backend.vercel.app (FastAPI 2.1.0, submodule `omsenjalia/weathergpt`)  
**Mobile**: Expo SDK 54 / React Native 0.81 / TypeScript 5.9 / Zustand 5 / expo-router 6 / AsyncStorage / Bhashini speech  
**History**: ported from Flutter 3.44 (see `FLUTTER_TO_REACT_NATIVE_MIGRATION.md`)  
**Docs**: `docs/app_data_contracts.md` (authoritative mobile contract), `docs/web_app_api_contract.md` (endpoint audit)
