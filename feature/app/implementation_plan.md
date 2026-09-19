# WeatherNext and Jev: Flutter app implementation plan

> **Implementing AI — cleanup required:** after implementation and required verification are complete, migrate lasting documentation/non-secret configuration examples, remove this completed temporary plan and its superseded planning templates, and repair all links. Preserve unfinished plans, source code, tests and real credentials. Follow the [owning-folder cleanup instructions](README.md#required-final-step-remove-completed-planning-artifacts).

**Target repository:** `omsenjalia/weathergpt-app` (this checkout). **Status: plan only; no new app feature implemented.** For what to configure/run, start with [App setup](README.md). Backend-only plans and credentials are in [the backend folder](../backend/README.md).

## 1. Ownership and dependency boundary

- Flutter calls the WeatherGPT backend. It does not query Google Cloud, run Jev/LangGraph, calculate scientific ensemble probabilities, or store provider credentials.
- App `.env` contains only the non-secret backend URL. It is bundled as an asset by the current `pubspec.yaml`; **it is not a secret store**.
- The backend owns IMD → WeatherNext → AccuWeather → Open-Meteo selection, authenticated dataset access, data normalization, scientific calculations, Jev evaluation and authorization.
- The app owns mode-specific views, validated inputs, source/uncertainty display and explicit unavailable states. User-selected Researcher mode does not grant server permissions.
- Implement against approved mocked response fixtures first. Do not wire new screens to proposed `/v2/...` endpoints before the backend has implemented and versioned them. Keep legacy `/weather` and `/chat` compatibility during rollout.
- The React web dashboard in `omsenjalia/weathergpt/frontend` is a separate client. Its migration is a follow-on task in that repository, not Flutter work and not a backend-only change.

## 2. Flutter implementation map

| Experience | Recommended change |
|---|---|
| Home | Selected-source badge (IMD/WeatherNext/fallback as appropriate), run/freshness, explicit estimated vs observed conditions; mode-specific scope below |
| Hourly/daily | Everyone retains the compact current experience; Farmer/Researcher can select appropriate available horizons, WeatherNext up to 15 days, with rain interval/spread and partial-day labels |
| Details | Dewpoint/RH, separate sea-level pressure, cloud layers, native and calibrated precipitation comparison |
| Farmer | Member-based rain/wind/heat events for action windows, missing-data caution, source/run context; validated decision thresholds |
| Researcher | Catalog-backed selector for every supported variable, run, pressure level, statistic/member, unit, and time window; profile and ensemble plots |
| Energy/marine | Optional 100m wind, solar energy/irradiance, SST panels; avoid crowding the default farmer/home screen |
| Explore | Keep existing Windy/Weather Lab behaviour for now. The later standalone custom-map/auto-login proposal was withdrawn; any future authorized research map rendering needs a separately approved delivery contract. |
| Chat/voice | Full authorized WeatherNext capability catalog available to LangGraph tools; mode-specific presentation, deterministic scientific calculations, source/run evidence, and structured voice cards |
| Historical | Real archive APIs instead of constant demo charts; forecast verification separate from climate trends |

Suggested implementation locations (new files are proposals):

- Extend `lib/models/weather.dart` with typed overview/provenance fields, and add separate catalog/series/profile models under `lib/models/`.
- Refactor `lib/features/home/providers/weather_provider.dart` to retain UTC times and source metadata, remove fixed truncation, and parse nulls safely.
- Extend `weather_detail_panels.dart`, `weather_metric_strip.dart`, and the hero UI without breaking older backend responses.
- Add catalog-backed asynchronous researcher providers/screens; avoid fetching every field on screen entry.
- Do not implement the withdrawn Weather Lab auto-login/custom-map proposal. Future research layer work remains gated on permission and a confirmed backend contract.
- Backend dependency (not work to run in Flutter): shared provider/decision services, versioned contracts and bounded research endpoints described in the [backend plan](../backend/weathernext_3_integration_plan.md).
- Add translated loading, stale, unavailable, attribution, uncertainty, and fallback text in every locale under `assets/translations/`.

Keep AQI/PM2.5, UV when unavailable, astronomy, authoritative warnings, geocoding, and long-term history on appropriate separate sources. Absence from the documented WeatherNext inventory is not permission to silently manufacture them.

## 3. Mode-specific product contract

All three modes retain location, language, unit preferences, source/freshness indicators, and official alert access. They share one data platform but **must not receive the same dashboard with different colours**.

| Mode | Default screens and data | Agent behaviour | Explicit boundaries |
|---|---|---|---|
| **Everyone** | Keep current temperature/feels-like/condition, high/low, humidity, wind/direction, pressure, rain chance, compact hourly/daily forecast, AQI/PM2.5, UV, sunrise/sunset. Add at most two compact WeatherNext enrichments: forecast temperature p10–p90 range and expected next-24-hour precipitation amount, when available. Source/update text stays unobtrusive. | Plain-language answers and practical everyday guidance; can retrieve authorized advanced evidence when a question needs it, but summarizes instead of dumping arrays. | No default upper-air/member/data-catalog panels, no automatic global queries or extended research dashboard. If the primary source is IMD, show any Google enrichment as a separately attributed WeatherNext forecast; do not imply the sources are one ensemble. No exact rain probability inferred from percentiles. |
| **Farmer** | Rain amounts/probabilities with intervals, dry/wet windows, wind for spraying, heat/cold stress, temperature/dewpoint/RH, and relevant cloud/solar context. Irrigation, spraying, field-work, sowing/harvest guidance uses actual crop, growth stage, soil and irrigation profile; show decision inputs, risk and provenance. | Farmer-specialist route pulls coherent forecast trajectories and validated action-window calculations; explains uncertainty in the user's language. May query the wider authorized WeatherNext catalog when useful. | Soil moisture/temperature, ET0 and agricultural disease/soil models need separately verified inputs/derivations; never call them native WeatherNext fields unless confirmed. Missing inputs cannot produce “safe” work windows or canned advice. |
| **Researcher** | Full capability explorer, every granted surface/product/version, complete variable/statistic/member/level/run/time selectors, native metadata/units, maps, profiles, comparisons, forecast archives and licensed exports/jobs. Cyclones/inference appear when independently granted and supported. | WeatherNext specialist discovers capabilities, pins requested sources/runs, retrieves any authorized field/operation, performs validated analysis and returns reproducible query/evidence references with visualizations or job handles. | No surface-only shortlist or hardcoded variable whitelist that silently drops new approved fields. Bounded/paginated data access rather than loading everything at once. Show precise missing-access/unsupported/terms-blocked states. Raw export remains license-gated. |

The two Everyone enrichments are proposed defaults defining “a tiny bit more”; hide unavailable cards or show a compact unavailable state rather than inventing values. Temperature spread and 24-hour rain must specify their source/run and coverage; do not show a full-period total when the interval is incomplete.

### End-to-end mode propagation

Audit finding: Flutter settings/onboarding already store `everyone`, `farmer`, and `researcher`. Chat and voice currently send only `farmer_mode` and hardcode `Wheat`; backend `ChatRequest` and `run_weather_agent` have no researcher mode, and `AgentState` contains only messages. Existing farmer “sub-agent” wording is a prompt, not a separate LangGraph specialist node.

- Add a validated `mode: everyone | farmer | researcher` to forecast/chat requests and graph context. If absent, map legacy `farmer_mode=true` to farmer and otherwise everyone. If explicit `mode` is present it is authoritative; normalize the legacy boolean from it. Reject unknown mode values rather than silently escalating.
- Update `backend/schemas.py`, `routers/chat.py`, `services/chat.py`, `agent.py`, Flutter weather/chat/voice providers and any web payloads. Persist and propagate mode changes; do not infer mode from the user's text or allow prompt text to alter server entitlements.
- Farmer chat/voice must read `farmProfileProvider` like `/advisory` already does, not assume Wheat. Include farm context only when relevant and consented; do not infer disease status or exact soil state from weather alone.
- Cache native scientific data independently of mode when permissions allow, but scope rendered views, private results, jobs, and conversations by identity/entitlements plus mode/location/profile/units. Invalidate appropriate views when those inputs change. Never share private farm context through a global model or cross-user cache.
- On mode switch, do not reuse a stale farmer/researcher system prompt. Keep any history as history, re-evaluate current request context and do not expose private artifacts to a different identity. Choosing Researcher does not grant Google/IAM or redistribution rights.
- In `action_windows_provider.dart`, replace canned offline favourable windows with clearly unavailable or timestamped last-known verified results. Re-fetch on location/profile changes and prevent old “tomorrow”/cached windows being shown for another place or day.

## 4. Concrete app delivery checklist

1. **Models and API parsing:** add typed provenance, forecast series, catalog, ensemble/profile and date/window-scoped decision models. Preserve UTC timestamps, timezone IDs, null reasons, source pins and schema version. Handle unknown additive fields gracefully; never map missing weather code/rain chance to sunny/zero.
2. **Mode propagation:** update `lib/features/home/providers/weather_provider.dart`, `lib/features/chat/providers/chat_provider.dart` and `lib/features/voice/providers/voice_provider.dart` to send explicit validated mode. Keep the legacy farmer boolean only for compatibility and use the actual `farmProfileProvider` for farm context.
3. **Home:** keep Everyone compact. Add source/freshness and at most the two agreed enrichments; request only appropriate fields and time ranges. Retain complete supported series in models without eagerly displaying/downloading the entire dataset.
4. **Farmer:** wire forecast-backed action windows, nullable evidence and clear fallback state. Read each day's final decision rather than a highest-confidence global verdict. Never present demo/offline favourable windows as live advice.
5. **Voice and chat:** consume structured cards/evidence from the backend; remove hardcoded Wheat, canned rain percentages and fixed weekday forecasts. Keep weather event probability, evidence quality and Jev decision confidence visibly distinct.
6. **Researcher:** replace constant charts with async APIs and a full authorized capability explorer. Provide field/run/level/member/statistic selectors, pagination/jobs where necessary and explicit blockers. Do not relabel forecast archives as decades of observed climate data.
7. **Lifecycle and privacy:** cancel or discard old requests on mode/location/profile changes, clear private cached state on logout/identity change, and prevent an old result from replacing a newer selection. Apply backend expiry and ownership rules to cached results/artifacts.
8. **Localization/accessibility:** translate new loading/unknown/stale/uncertainty/attribution text in every existing locale; test large text, screen readers, colour-independent risk labels and unit formatting. Critical warnings must not be hidden for a cleaner layout.

## 5. Backend contracts needed before live integration

| Client surface | Required backend handoff |
|---|---|
| Home/hourly/daily | Versioned overview/series fixtures, null semantics, source/freshness metadata, actual horizons and timestamps |
| Farmer | Real profile request contract; activity/date/window-scoped final decisions with evidence, warnings and explicit unavailable status |
| Chat/voice | Backward-compatible text plus optional typed cards/evidence; explicit mode and source constraints |
| Researcher | Entitlement-filtered capabilities and all authorized query paths, known blocked states, job/artifact ownership and payload bounds |
| Errors/auth | Stable structured error codes, expiration/session behaviour and no leaked provider errors/credentials |

Endpoint paths in the [backend API proposal](../backend/weathernext_3_integration_plan.md#5-data-contract-proposal) are design targets, not existing services. The [Jev plan](../backend/jev_backend_plan.md) defines decision behaviour; the app renders it rather than recreating model/rule logic.

## 6. App acceptance tests

- Parser fixtures for legacy/new responses, null/malformed/partial data, stale and fallback sources, timestamps/timezones, unit conversions for display and unknown capabilities.
- Widget tests for Everyone/Farmer/Researcher: different content scope, authorized/blocked research states, source attribution and uncertainty labels.
- Interaction tests for switching mode/location/profile while requests are in flight; no stale response or private cross-user cache reuse.
- Farmer/voice regression tests: no synthetic favourable windows, no hardcoded Wheat, no fixed 78%/12 mm cards, no tomorrow verdict shown as today's, and no fabricated safe/clear values.
- UI/backend parity fixtures: same evidence/run/interval yields the same values in Home, farm cards, chat and voice. Jev confidence is not weather probability.
- Localization key-set, readable layout, accessibility and Android/iOS device networking tests.
- Run `flutter test`, `flutter analyze` and platform builds with the appropriate SDK/toolchains, then test against the staged backend before enabling features.

**Done:** implemented and tested app code plus a compatible authorized backend. Moving these documents or filling `BACKEND_URL` does not implement the feature. App runtime tests were not run during this documentation split.
