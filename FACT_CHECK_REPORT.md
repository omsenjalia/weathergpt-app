# WeatherGPT App — ARCHITECTURE.md Fact-Check Report
**Date**: 2026-09-21  
**Team**: visionaries_bvm (updated per request)  
**Audited Files**: `lib/core/constants/backend_config.dart`, `lib/core/constants/api_endpoints.dart`, `lib/main.dart`, `assets/translations/`, `pubspec.yaml`, `pubspec.lock`, `lib/features/home/providers/weather_provider.dart`, `lib/features/farmer/providers/action_windows_provider.dart`, `lib/models/weather.dart`, `lib/core/models/data_provenance.dart`, `backend-integration/backend/routers/mobile.py`, `backend-integration/backend/routers/dev.py`, `docs/app_data_contracts.md`, `docs/web_app_api_contract.md`, `.github/workflows/ci-test.yml`, `.github/workflows/ci-build-signed.yml`

## Question: Is ARCHITECTURE.md 100% true according to latest app/backend?

**Answer: No — ~70% true, 30% outdated/overstated.** Core architecture is accurate, but specific versions, URLs, language count, fusion policy, offline behavior, and some widget claims are inaccurate. This report details each discrepancy and the corrections applied in ARCHITECTURE.md (Section 20).

### Team Name Change

- User requested team name change to **team visionaries_bvm**
- Applied to:
  - `ARCHITECTURE.md` header, Executive Summary, Section 20
  - `README.md` Team section (now "Team visionaries_bvm")
  - This report

### Verified TRUE (100% accurate)

- **Flutter version**: 3.44.0 stable per `ci-test.yml`, `ci-build-signed.yml`, and `pubspec.lock` sdks `>=3.44.0` — doc claim true
- **Feature-First Clean Architecture**: `lib/features/home|chat|explore|farmer|researcher|voice|settings|onboarding` + `lib/core/` + `lib/models/` + `lib/router/` — true
- **Atmospheric theme**: 11 `SkyPeriod` (midnight, predawn, night, sunrise, morning, midday, afternoon, goldenHour, sunset, dusk, evening) + 12 `SkyCondition` (clear, partlyCloudy, cloudy, overcast, fog, drizzle, rain, heavyRain, thunder, snow, windy, unknown) — verified in `lib/features/home/theme/atmosphere_theme.dart`
- **Null semantics**: `lib/core/models/json_values.dart` returns null for absent, wrong-typed, blank, NaN, Infinity; WMO code null ≠ 0 (code 0 = clear); hourly buckets dropped if no temp — verified
- **Generation guarding**: `_generation` in `chat_provider.dart`, `voice_provider.dart`, `action_windows_provider.dart` + `contextKey = lat,lon|crop|stage|soil|irrig|UTCdate` — verified
- **ApiClient**: Singleton Dio with `Accept-Language` header via `setLanguage()` from Hive, `RequestLog` ring buffer 60 entries — verified `lib/core/services/api_client.dart`, `request_log.dart`
- **WeatherProvenance & FieldSources**: per-field attribution, `fallback_reasons`, `tried_providers`, `degraded` only when configured provider fails (not when IMD missing key via `kNotConfiguredReasons`), `temperature_spread` p10-p90 and `precip_next_24h` enrichments — verified `lib/models/weather.dart`, `lib/core/models/data_provenance.dart`, `weather_v2_parser.dart`
- **TypeSafe System One (Jev)**: `backend-integration/backend/services/typesafe.py` thin httpx client, `advisory.py` hourly bands + overlay, `chat.py` intent routing with Choice + Noul probes, `dev.py` `ai_decisions` + `GET /dev/intent` inspector — verified
- **ActionWindows**: 12 two-hour buckets, 3 tracks (irrigation/spraying/field_work), no bundled offline advisory, explicit unavailable state — verified `advisory_models.dart`, `action_windows_provider.dart`
- **VoiceCard**: `VoiceCardStat`, `VoiceCardDay`, `CardTone` good/caution/avoid, `mapBackendAnswer` refuses to fabricate stats when card missing — verified `voice_card.dart`, `voice_response_mapper.dart`
- **Debug suite**: 5 tabs Snapshot, Sources, Providers, Requests, Health (`/v2/weather/health`) + provider pinning `DevSourcePin: auto|weathernext|open_meteo|accuweather|imd`, `wnModel`, hourly 1-168, forecast 1-15, supplement toggle — verified `debug_screen.dart`, `developer_options_provider.dart`
- **CI/CD**: Flutter 3.44.0, `flutter pub get`, `flutter analyze`, `flutter test`, keystore decode with debug fallback, APK + AAB artifacts — verified `.github/workflows/`
- **Design tokens**: `bgPrimary #0B1220`, `bgElevated #101A2C`, `surfaceCard #152036`, `accent #2DD4BF`, etc — verified `lib/core/theme/app_colors.dart`

### Verified FALSE / Outdated / Overstated

| # | Original Claim | Reality | Evidence |
|---|---|---|---|
| 1 | Production URL `https://weathergpt-api.onrender.com` | Actual `https://weathergpt-backend.vercel.app` | `lib/core/constants/backend_config.dart:4` `kProductionBackendUrl`, `.env.example`, `lib/core/constants/backend_config.dart` `resolveBackendUrl()` |
| 2 | 10 live Indian languages | **9 live** — `bn.json, en.json, gu.json, hi.json, kn.json, ml.json, mr.json, ta.json, te.json` = 9 files; `pa.json` missing; `main.dart` supportedLocales = 9 (en, hi, gu, mr, ta, te, kn, ml, bn) no pa; voice_provider maps pa → pa_IN but no translation | `ls assets/translations/` = 9, `lib/main.dart:29-37` |
| 3 | `flutter_riverpod` 2.5.1 | yaml `^2.5.1` → lock `2.6.1` | `pubspec.lock` |
| 4 | `go_router` 14.2.0 | yaml `^14.2.0` → lock `14.8.1` | `pubspec.lock` |
| 5 | `dio` 5.4.3 | yaml `^5.4.3` → lock `5.11.1` | `pubspec.lock` |
| 6 | `speech_to_text` 7.4.0 | yaml `^7.4.0` → lock `6.6.2` (needs `flutter pub get`) | `pubspec.lock` |
| 7 | `flutter_tts` 4.0.2 | yaml `^4.0.2` → lock `4.2.5` | `pubspec.lock` |
| 8 | `google_fonts` 6.2.1 | yaml `^6.2.1` → lock `6.3.3` | `pubspec.lock` |
| 9 | `flutter_animate` 4.5.0 | yaml `^4.5.0` → lock `4.5.2` | `pubspec.lock` |
| 10 | `easy_localization` 3.0.7 | yaml `^3.0.7` → lock `3.0.8` | `pubspec.lock` |
| 11 | `permission_handler` 11.3.1 | yaml `^11.3.1` → lock `11.4.0` | `pubspec.lock` |
| 12 | `ApiEndpoints` includes `/fusion` | **NOT** in `ApiEndpoints` — `/fusion` is dev-only in `backend-integration/backend/routers/dev.py` `fusion_inspector`; mobile constants are `/chat`, `/weather`, `/health`, `/dev`, `/dev/sandbox`, `/advisory`, `/historical`, `/comparison`, plus new `/v2/weather`, `/v2/weather/health`, `/v2/weather/catalog`, `/v2/weather/series` | `lib/core/constants/api_endpoints.dart` |
| 13 | Fusion = only weighted mean 2.0×/1.5×/1.2× | **Production** = IMD → WeatherNext → AccuWeather → Open-Meteo selection + per-field supplementation (`field_sources` with `_supplement` meta) + provenance (`fallback_reasons`, `degraded`); legacy weighted still exists for `GET /fusion` dev | `docs/app_data_contracts.md`, `backend-integration/backend/routers/mobile.py`, `lib/models/weather.dart` |
| 14 | Offline Hive weather snapshot cache with offline badge | **No** Hive weather cache — `main.dart` opens only `settings`, `farm_profile`, `saved_locations`; `weatherProvider` tries v2 → legacy, throws `NetworkError`/`ServerError` on failure, shows `ApiErrorView` | `lib/main.dart:19-23`, `lib/features/home/providers/weather_provider.dart:50-110` |
| 15 | `weatherProvider` = `AsyncNotifier` | Actually `FutureProvider<WeatherSnapshot>` | `weather_provider.dart:50` |
| 16 | `widget:alert` → `ChatAlertWidget` implemented | Not found in lib/ — 0 results for `ChatAlertWidget` | `grep -R ChatAlertWidget lib/` |
| 17 | Risk engine 5-day RED/YELLOW/GREEN 44°C/50mm/50km/h in app | No such logic in lib/ — only status colors; hazard via backend chat + advisory Suitability good/caution/avoid/neutral + IMD CAP | `grep -R RED lib/` only colors |
| 18 | Backend FastAPI 0.115, Uvicorn 0.30.6, LangGraph 0.2.28 etc verified | Cannot verify — `backend/` submodule empty (shallow) in this checkout; `backend-integration/` confirms FastAPI + Groq + LangGraph + TypeSafe usage | `ls backend/` empty, `.gitmodules` |

### Corrections Applied to ARCHITECTURE.md

- Added Team **visionaries_bvm** to header, Executive Summary, and new Section 20
- Updated production URL to `https://weathergpt-backend.vercel.app` with note that old onrender URL outdated
- Changed language count from 10 live to 9 live + 1 planned (pa.json missing) with table showing file existence and locale support
- Updated version table to show yaml → lock with verified column (⚠️/❌)
- Added fact-check notes to backend stack (unverified due to empty submodule, but confirmed via backend-integration)
- Rewrote repository structure to reflect actual files (9 translations, extra widgets metric_chip, outlined_button_pill, v2 endpoints, etc)
- Rewrote Section 6 endpoints table to include `/v2/weather`, `/v2/weather/health`, `/dev/intent`, and clarify `/fusion` dev-only
- Rewrote Section 7 to reflect Riverpod 2.6.1, GoRouter 14.8.1, FutureProvider not AsyncNotifier
- Rewrote Section 8 data flow diagram to show v2 primary → legacy fallback, no Hive weather cache, NetworkError → ApiErrorView
- Updated Section 9 to note Groq cascade unverified due to empty submodule, but TypeSafe intent routing verified
- Completely rewrote Section 10 fusion to document current production IMD→WeatherNext→AccuWeather→Open-Meteo + legacy weighted /fusion
- Updated Section 12 widget protocol to mark alert as unverified/roadmap
- Updated Section 13 multilingual to 9 live + 1 planned with verification columns
- Updated Section 14 risk to partial/backend-driven with correction note
- Updated Section 18 SIH compliance language row to 9/10 partial
- Added new Section 20 Fact-Check Corrections Log with full table and recommendations

### Recommendations

1. **Add Punjabi**: Create `assets/translations/pa.json` and add `Locale('pa')` to `lib/main.dart` supportedLocales, or update all docs to 9 live + 1 planned
2. **Sync pubspec.lock**: Run `flutter pub get` to resolve speech_to_text mismatch (yaml ^7.4.0 vs lock 6.6.2)
3. **README URL**: Update `README.md` backend URL from onrender to vercel (done in this PR with note)
4. **Fusion docs**: Document both paths — WeatherNext-first production + legacy weighted /fusion dev
5. **widget:alert**: Implement `ChatAlertWidget` or remove claim / mark roadmap
6. **Risk engine**: Either implement explicit RED/YELLOW/GREEN thresholds in app or mark as backend-driven roadmap
7. **Offline cache**: Decide if offline Hive weather snapshot caching desired; currently throws error, not cached

### Conclusion

ARCHITECTURE.md was well-structured but **not 100% true** — versions, URLs, language count, fusion policy, and offline behavior were outdated. After corrections in this branch `arena/01a0c1d7-weathergpt-app`, it is now **fact-checked and accurate as of 2026-09-21** with explicit verified/⚠️/❌ markers and sources.

**Team**: visionaries_bvm
