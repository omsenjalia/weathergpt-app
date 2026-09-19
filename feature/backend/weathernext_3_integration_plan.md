# WeatherNext 3 backend integration blueprint

> **Implementing AI — cleanup required:** after implementation and required verification are complete, migrate lasting documentation/non-secret configuration examples, remove this completed temporary plan and its superseded planning templates, and repair all links. Preserve unfinished plans, source code, tests and real credentials. Follow the [owning-folder cleanup instructions](README.md#required-final-step-remove-completed-planning-artifacts).

**Execution target:** `omsenjalia/weathergpt/backend`. Start with [Backend setup](README.md). Flutter work is in [feature/app](../app/README.md).

Audited: 2026-09-19. Status: **design and repository audit, not a live integration**.

Backend source confirmed by the user: `omsenjalia/weathergpt/backend`. Read-only GitHub audit pinned to commit [`1004061d7e6c25fce5e52566bff66519f13e9212`](https://github.com/omsenjalia/weathergpt/tree/1004061d7e6c25fce5e52566bff66519f13e9212/backend) on its default branch, `master`. This confirms repository source, not which revision is deployed. No branch was changed and no remote files were modified.

## Recommendation and release gate

Use the user-requested default provider order **IMD (when configured and eligible) → Google DeepMind WeatherNext → AccuWeather → Open-Meteo (fallback)** behind the backend. WeatherNext is the primary Google forecast source and the default forecast source when eligible IMD data is unavailable, not a direct Flutter dependency or a replacement for every weather-related source. Preserve the complete discoverable data catalog internally; expose bounded, purpose-specific views only where your agreement permits. Do not ship whole global forecasts to phones.

**Resolve distribution rights first.** The linked real-time terms permit internal uses and certain value-added services, but do not generally permit public redistribution of unmodified real-time data. They explicitly exclude mere colouring, formatting, unit-like fixed adjustments, spatial subsets, and combinations of parameters/timesteps/model runs from qualifying as value-added services. Retrievable value-added services have controlled-distribution restrictions. The disclaimers say the experimental data is not intended for consumer use. A public JSON endpoint, raster map, login wall, or attribution alone does not establish permission. Ask Google to confirm in writing that the actual WeatherGPT screens, numerical forecasts, farm recommendations, territories, and API distribution are permitted under your agreement. This is an engineering release gate, not a legal opinion. [Terms](https://storage.googleapis.com/weathernext-public/terms-of-use.pdf)

Historical data is licensed under CC BY 4.0 when the **time the data relates to** is at least an hour in the past. An old forecast run whose valid times are still in the future is not automatically historical merely because you downloaded it yesterday. Official warnings must remain authoritative; WeatherNext is not an official warning service. [Disclaimers](https://developers.google.com/weathernext/guides/disclaimers)

### Confirmed product requirements (user update)

- **Farmer mode:** farmer-specific weather data and crop/location-aware action guidance.
- **Researcher mode:** every authorized WeatherNext-related data capability Google provides, accessible through both the researcher UI and the WeatherNext specialist in LangGraph. Not limited to the initial surface-variable list.
- **Everyone mode:** retain the current normal weather experience, adding only a small amount of useful WeatherNext detail (see section 7a).
- **Default backend order:** IMD → WeatherNext → AccuWeather → Open-Meteo. This supersedes the earlier WeatherNext-first recommendation and the existing Open-Meteo-first fusion weights.
- **Agent parity:** LangGraph must be able to discover and query the complete authorized catalog; dashboard integration alone does not meet the requirement.
- **Completion rule:** all discovered capabilities must be accounted for, and every authorized, technically supported capability must have a tested UI path and agent tool path. Explicit blockers are tracked, not quietly counted as completed integration.

These are planned requirements, not shipped functionality. Mode controls presentation and task routing; server-side entitlements, licensing, budgets, and safety checks still apply.

## 1. Stage map, evidence, and verification

| Stage | Expected output | Check/result |
|---|---|---|
| 1. Audit application | Actual data paths and limitations | Read Flutter models/providers/UI, then the actual backend source at pinned commit `1004061`. Hosting and deployed revision remain unverified. |
| 2. Verify product | Official access mechanisms, variable families, terms | Checked official model, access, GCS, BigQuery, and licensing documents. Live account access not tested. |
| 3. Design integration | Coverage matrix, serving architecture, app changes | Updated with three personas, IMD-first provider selection, full capability inventory, and LangGraph parity. Public serving is conditional on rights. |
| 4. Skeptical review | Explicit tests, rollout gates, remaining unknowns | No runnable integration claimed; schema, IAM, budget, permission, and deployment checks remain prerequisites. |

The supplied Fable skill guided staged work and parallel research/inspection. Subagent and Todo tools were unavailable; this is self-review, not independent-agent verification. No application code, providers, or deployed infrastructure were changed.

## 2. What this repository actually does

| Area | Evidence in this checkout | Integration consequence |
|---|---|---|
| HTTP boundary | `lib/core/services/api_client.dart` calls the configured backend and explicitly requires server-side keys | Keep all Google credentials and dataset access server-side. |
| Home forecast | `lib/features/home/providers/weather_provider.dart` requests `/weather`, takes only 12 hourly entries, retains time as a display label plus temperature, ignores source/fetched-at metadata | Replace parsing with a richer versioned forecast model; preserve UTC timestamps and provenance. |
| Data model | `lib/models/weather.dart`: `HourlyPoint` only has `label` and `tempC`; `WeatherSnapshot` has no ensemble, run, resolution, or freshness fields | Add dedicated forecast/provenance models rather than squeezing arbitrary upper-air arrays into this snapshot. |
| Home UI | `weather_detail_panels.dart` displays at most 24 hours and 7 days | Provider truncation currently wins; add selectable horizons and uncertainty views. |
| Bundled `/weather` | `backend-integration/backend/routers/mobile.py` gets Open-Meteo, overlays current-condition fusion, returns 3 daily entries and first 24 hourly entries | Change forecast assembly in the real backend. Existing hourly code starts at the array's beginning despite its “from now” comment. |
| Farm advice | Same route file calls Open-Meteo independently for `/advisory`; `services/advisory.py` expects hourly arrays and applies threshold/TypeSafe logic | Route through the same normalized forecast service as home, not a second WeatherNext implementation. |
| Chat | Bundled `services/chat.py` calls functions imported from `agent` for telemetry and agent responses | Update shared weather tools in the deployed backend; changing mobile `/weather` alone will not update chat or voice. |
| Explore | `map_provider.dart` and `explore_screen.dart` embed Windy/Weather Lab | These are external viewers, not ingestion of WeatherNext into WeatherGPT. Own layers require an authorized tile service/map client. |
| Research | `historical_data_provider.dart`, `anomaly_trends_provider.dart`, `comparison_provider.dart` contain constant chart series consumed by screens | Wire real APIs and clearly label/remove demo data. Forecast archives are not a decades-long observed climate record. |
| Backend completeness | `backend-integration/README.md` targets `omsenjalia/weathergpt`; imported `services/fusion.py`, `services/open_meteo.py`, and `agent` are absent here | The full backend was subsequently inspected read-only on GitHub (section 2a). Its mobile router and chat service match this bundle byte-for-byte at the audited revision; deployment still needs confirmation. |

Additional migration hazards: missing weather codes default to `0` in the mobile parser (can imply clear sky), missing rain probability becomes zero in the bundled route, and `pressure_hpa` currently represents surface pressure. Unknown data must remain unknown; WeatherNext mean-sea-level pressure must not silently replace station/surface pressure under an unchanged label.

## 2a. Confirmed backend integration points

Continuation audit: repository identity and revision were obtained with `gh`; selected source files were downloaded to an external scratch cache, not another Git checkout. Source reads and static checks only; no runtime or account access is implied. Paths below are relative to `omsenjalia/weathergpt` unless explicitly labelled Flutter.

### Actual call graph

```text
Flutter Home → GET /weather → routers/mobile.py::_build_weather_snapshot
                               ├─ services/open_meteo.py::get_json (forecast + AQI)
                               └─ services/fusion.py::fuse_current_weather (current)

Flutter Farm → GET /advisory → routers/mobile.py::get_advisory
                               ├─ independent Open-Meteo forecast request
                               └─ services/advisory.py + services/typesafe.py

Flutter Chat / Voice → POST /chat → services/chat.py::run_chat
                                    ├─ agent.py::run_weather_agent → tools.py
                                    └─ agent.py::run_deterministic_telemetry_fallback
                                         ├─ tools.py (current + daily forecast)
                                         └─ direct Open-Meteo HTTP fallback

React dashboard → frontend/src/api.js::getWeatherByCoords
                   → getEnsembleWeather (client-side forecast assembly)
```

`backend/main.py::create_app` registers chat, mobile, and dev routers. `backend/mobile_api.py` is a compatibility shim, not the route implementation. No `/voice` backend route is registered in the inspected source; Flutter `lib/features/voice/providers/voice_provider.dart` explicitly posts recognized text to `/chat`. The older `docs/web_app_api_contract.md` entry for `/voice` should not be treated as evidence of a deployed route.

### Concrete implementation diff, not yet applied

| Existing file / symbol | Required change |
|---|---|
| `backend/routers/mobile.py::_build_weather_snapshot` | Replace forecast retrieval/aggregation with the shared forecast service; compose separate current/AQI/UV/astronomy products with provenance; preserve legacy response compatibility. Do not make WeatherNext success depend on a successful initial Open-Meteo forecast fetch. |
| `backend/routers/mobile.py::get_advisory` | Consume the same normalized service and coherent run/member-derived daily/hourly products; preserve crop context and conservative TypeSafe policy. |
| `backend/tools.py::get_weather_forecast` | Replace direct HTTP with the shared forecast service; update the current “up to 16 days” tool contract to actual provider capabilities (WeatherNext synoptic maximum 15 days); return source/run/coverage. |
| `backend/tools.py::get_hourly_forecast` | Same service; select future timestamps rather than the first 24 entries of the upstream day; retain wind/humidity as promised by the tool rather than silently dropping them. |
| `backend/agent.py::run_deterministic_telemetry_fallback` | Remove provider-bypassing HTTP and invented fallback measurements; handle nullable structured data and unresolved locations honestly; render provenance in deterministic replies. |
| `backend/services/chat.py::run_chat` | Preserve routing and TypeSafe gates; ensure fast path, agent path, timeout fallback, and reply-check fallback share data/provenance semantics. Keep heavy data processing outside chat deadlines. |
| `backend/schemas.py::ChatResponse` and `backend/routers/chat.py` | Add optional typed weather/forecast evidence or structured cards, retaining `response` and `meta` for older clients. Prefer a server-assembled result over extracting measurements from prose. |
| `backend/services/fusion.py` and `tools.py::get_current_weather` | Replace the default app/agent weighted-current path with capability-aware priority selection (section 4). Retain legacy fusion only as an explicitly labelled diagnostic/comparison, not the primary answer. Apply product eligibility: WeatherNext forecasts cannot stand in for actual observations. |
| `backend/tools.py::get_agricultural_crop_telemetry` | Retain separately sourced soil/ET0 fields; consume shared forecast rain for decisions; remove made-up moisture/temperature defaults and add unknown-data handling. |
| `backend/tools.py::get_severe_weather_alerts` | Separate model-derived hazard guidance from official alerts. Add an actual authoritative warning source when available; never present missing data as an all-clear. |
| `backend/tools.py::get_air_quality`, `get_uv_index_and_sun`, `get_surface_pressure_and_wind` | Preserve supplementary capabilities with explicit provenance, units, AQI standard, and missing states; remove arbitrary values and gust estimates masquerading as measurements. |
| `backend/main.py` | Register approved new routers and capability metadata; update advertised provider order and distinguish legacy fusion diagnostics from selected-provider results. Add authorization/rate/cost controls before exposing paid scientific queries. |
| `backend/routers/dev.py` | Add source health, latest complete runs, freshness/coverage, fallback reasons, and cache/query-cost diagnostics without credentials. |
| `frontend/src/api.js::getWeatherByCoords` | If web/mobile parity is in scope, replace client-side assembly with the shared backend forecast contract and adapt the web response shape. A backend-only change does not automatically migrate this dashboard. |
| Flutter `lib/features/voice/providers/voice_provider.dart` | Replace `_responseFor` canned statistics/forecasts used by `_responseFromBackend` with optional structured response data; absent values must render unavailable, not the demo numbers. |

Suggested **new** modules in the backend (names are design proposals, not existing code):

```text
backend/services/forecast.py                 # IMD → WeatherNext → AccuWeather → Open-Meteo selection
backend/services/forecast_models.py          # normalized units, times, provenance, coverage
backend/services/providers/imd.py            # granted IMD products; key presence is not capability
backend/services/providers/weathernext.py    # bounded reads from cached WeatherNext products
backend/services/providers/accuweather.py    # forecast adapter in addition to existing current adapter
backend/services/providers/open_meteo.py     # legacy forecast adapter, not wholesale deletion
backend/services/forecast_aggregation.py     # member-first daily/risk calculations
backend/services/forecast_cache.py           # run-keyed shared cache and freshness
backend/services/weathernext_catalog.py       # all authorized capabilities, schemas, tool/UI mappings
backend/services/weathernext_tools.py         # typed, permission-checked LangGraph tools
backend/routers/weather_v2.py                # bounded series/catalog/profile views
backend/workers/weathernext_ingest.py         # separately deployed scheduled ingestion
backend/tests/test_weathernext_*.py           # provider, science, run selection, error paths
backend/tests/test_forecast_contract.py       # old/new client and tool compatibility
```

The new Open-Meteo adapter should reuse the existing `backend/services/open_meteo.py` HTTP helpers where appropriate; migrate callers explicitly rather than leaving two conflicting provider policies. Keep expensive raw-Zarr dependencies in the worker image/dependency group; the API adapter should normally read prepared products, not load global arrays.

### Release-critical findings from the actual source

1. **Synthetic fallback data:** `agent.py::run_deterministic_telemetry_fallback` substitutes values such as 27°C, 65% humidity, and wind defaults on failed retrieval/conversion, and a synthetic forecast card when daily data is empty. It can also substitute Ahmedabad coordinates when geocoding fails while retaining a requested city label. Replace these behaviors with explicit unresolved-location/unavailable states.
2. **Voice cards are not live measurements:** Flutter `_responseFromBackend` takes live reply text but retains `_responseFor` statistics and forecast cards for non-meta queries (examples: 78% rain, 12 mm, fixed Tue/Wed/Thu entries). Fix this client-side path even after backend tools are migrated.
3. **Official-alert labelling:** `frontend/src/api.js::getIMDAlertBulletin` generates “IMD” titles from local thresholds, not a fetched IMD bulletin. `tools.py::get_severe_weather_alerts` also constructs threshold alerts from model data. Relabel these as WeatherGPT model-derived guidance and use separately verified official alerts; a quiet model forecast is not proof that no official warning is active.
4. **Supplementary consistency:** mobile `/weather` requests European AQI while `tools.py::get_air_quality` requests US AQI. Preserve an explicit AQI standard in the contract; these numbers are not interchangeable. Several tools substitute default AQI, UV/sunrise/sunset, soil, pressure, or gust values when fields are missing; centralize nullable handling.
5. **Deployment constraints:** `backend/vercel.json` configures `api/index.py` with `maxDuration: 60`; `api/index.py` imports the FastAPI app. This establishes a serverless configuration, not proof of current hosting. Use a separate scheduled worker and shared persistent cache rather than background ingestion inside request handlers. No shared forecast cache was found in the inspected weather paths. The current requirements do not include WeatherNext/GCP/Zarr libraries.
6. **Test coverage is mixed:** `backend/tests/test_fusion.py` has offline unit tests; advisory tests mock weather and TypeSafe transports. Some `backend/tests/test_api.py` cases use live upstream calls and accept 502/504. Those passing would not verify forecast correctness. Add deterministic mocked contracts and a separately gated live-access smoke test instead of relying on the previous integration bundle's test-count claim.

### Verification of this continuation

- Confirmed repository/default branch and pinned source revision through GitHub API.
- Compared downloaded `backend/routers/mobile.py` and `backend/services/chat.py` to their local bundle copies: byte-for-byte matches.
- Traced direct forecast reads, deterministic fallback, voice `/chat` usage, web client assembly, and Vercel configuration in source.
- Static checks validate referenced backend symbols/files and Python syntax; no application test pass or successful deployment is claimed.
- Remaining weakness: these are source findings, not evidence that the same revision is deployed or that Google credentials/permissions work. Keep the private proof and release gates in section 8.

## 3. Verified WeatherNext scope

Official documentation describes 64 ensemble members, hourly forecast steps, 360-hour horizons for 00/06/12/18 UTC initializations, and 48-hour horizons for interim hourly initializations. Station-head temperature/dewpoint use 0.05° grids, gridded surface fields 0.1°, and atmospheric levels 0.25°. Do not advertise every variable as 5 km or every run as 15 days. Upper-air fields and the six-hour accumulation fields below are limited to synoptic initializations in the full GCS ensemble. [2](https://developers.google.com/weathernext/guides/models)

### Access paths

| Path | Contents | Recommended role |
|---|---|---|
| BigQuery linked tables | Surface statistics; 0.1° and 0.05° tables | First point-forecast implementation if your Analytics Hub subscription is ready |
| GCS statistics Zarr | Surface mean, p10, p25, p50, p75, p90 | Alternative hot-path ingestion; regional batches and offline caches |
| GCS full-ensemble Zarr | Raw ensemble, upper air, multi-resolution fields | Required for complete coverage, member-level risks, and scientific views |
| Earth Engine | Surface statistics and geospatial analysis | Optional for everyday serving, but included in full researcher/agent coverage when granted; not a substitute for full-ensemble access |

BigQuery/Earth Engine alone cannot meet “all data.” The official access guide says the allowlist covers all three surfaces, but you must separately verify access from the actual deployed service identity; personal Console access is not evidence that a workload service account can read the data. [9](https://developers.google.com/weathernext/guides/access-forecast)

Official GCS roots:

- Full ensemble: `gs://weathernext3_spatial/weathernext_3_0_0/zarr/`
- Statistics: `gs://weathernext3_statistics_spatial/weathernext_3_0_0_statistics/zarr/`

The full-ensemble bucket is Requester Pays and located in `us-east1`; the statistics bucket has Requester Pays off. Use nearby processing, measure actual reads, and avoid global loads. “Requester Pays off” does not mean your compute/storage pipeline is free. [GCS guide](https://developers.google.com/weathernext/guides/gcs)

### Complete documented variable inventory

These are **documented logical variables**, not a guarantee that every raw Zarr array has precisely this flattened name. Inspect live metadata; scalar wind speed is documented as derived. All rows need native units, availability, coordinates, null semantics, resolution, and source identifiers in the internal catalog. [2](https://developers.google.com/weathernext/guides/models)

| Family | Exact documented variable(s) | Native units | App use |
|---|---|---|---|
| Surface temperature | `temperature_2m`, `dewpoint_temperature_2m` | K | Temperature/dewpoint charts; humidity derivation |
| Station-head temperature | `station_head_temperature_2m`, `station_head_dewpoint_temperature_2m` | K | Higher-resolution point forecast, where valid; still predictions, not observations |
| 10m wind | `wind_speed_10m`, `u_component_of_wind_10m`, `v_component_of_wind_10m` | m/s | Wind speed/direction, spraying conditions |
| 100m wind | `wind_speed_100m`, `u_component_of_wind_100m`, `v_component_of_wind_100m` | m/s | Energy/research tab |
| Downward solar | `surface_solar_radiation_downwards_1hr`, `surface_solar_radiation_downwards_6hr` | J/m² | Solar energy; derived interval-average irradiance |
| Direct solar | `total_sky_direct_solar_radiation_at_surface_1hr`, `total_sky_direct_solar_radiation_at_surface_6hr` | J/m² | Energy/research; do not relabel as direct-normal irradiance without confirming definition |
| Native precipitation | `total_precipitation_1hr`, `total_precipitation_6hr` | m | Accumulation and ensemble risk |
| IMERG-trained precipitation | `imerg_tp_1hr` | m | Separate forecast product, not a live satellite observation |
| Experimental precipitation | `experimental_tp_1hr` | m | Separate experimental product/comparison |
| Clouds | `total_cloud_cover`, `high_cloud_cover`, `medium_cloud_cover`, `low_cloud_cover` | 0–1 | Total/layer cloud views |
| Pressure | `mean_sea_level_pressure` | Pa | Explicit sea-level pressure display/maps |
| Ocean | `sea_surface_temperature` | K | Marine/research, masked on land |
| Upper-air geopotential | `geopotential_{level}` | m²/s² | Heights and pressure-level charts |
| Upper-air humidity | `specific_humidity_{level}` | kg/kg | Profiles; not relative humidity |
| Upper-air temperature | `temperature_{level}` | K | Atmospheric profiles |
| Upper-air horizontal wind | `u_component_of_wind_{level}`, `v_component_of_wind_{level}` | m/s | Wind profiles and shear analysis |
| Upper-air vertical motion | `vertical_velocity_{level}` | Pa/s | Pressure vertical velocity; not m/s |

Pressure levels: **50, 100, 150, 200, 250, 300, 400, 500, 600, 700, 850, 925, 1000 hPa**. Raw stores can use a `level` dimension rather than suffixes. Six families × 13 levels produce 78 logical upper-air fields. The model table lists 22 gridded surface logical variables (including three six-hour accumulations) and two station-head variables. BigQuery documents 19 gridded variables × six statistics = 114 metrics, plus two station-head variables × six statistics = 12 metrics. Do not multiply these statistics by 64 members: they are summaries of members, not additional members. [2](https://developers.google.com/weathernext/guides/models) [BigQuery guide](https://developers.google.com/weathernext/guides/bigquery)

“All” additionally means retaining run/version, initialization and valid times, lead times, member identities, accumulation intervals, coordinate systems, sampling/interpolation methods, masks, native units, available horizons, and ingestion timestamps. Build a discovery diff that flags new/removed variables; unrecognized fields may be retained internally but not silently published without unit/meaning review.

Do not assume research-paper outputs, cyclone tracks, satellite inputs, radar images, model weights, or every field in a related Google product are included in these datasets. Add them only when access-specific inventory confirms them.

## 3a. “Every endpoint”: capability inventory and coverage contract

**Scope is every WeatherNext-related data/service capability actually granted by Google**, across supported model versions and access surfaces—not every unrelated Google Cloud API method. A data variable, a BigQuery table, a GCS object, and an HTTP operation are different inventory items. The app provides a unified explorer rather than pretending each variable has a Google REST endpoint.

The official [forecast access guide](https://developers.google.com/weathernext/guides/access-forecast) lists GCS, BigQuery, and Earth Engine. Extend the inventory with any additional services in the user's approval documentation. Do not invent URLs or scrape undocumented Weather Lab internals.

| Capability group | Scope to inventory and integrate | Researcher UI / LangGraph path | Verification status |
|---|---|---|---|
| GCS full ensemble | All granted versions/runs, native variables, grids, levels, members, coordinates, metadata, real-time and available archives | Native-field browser, profiles, trajectories, bounded regional jobs / series, profile, ensemble and job tools | Public WN3 documentation verified; account access/schema untested |
| GCS statistics | All granted statistics arrays and metadata, not only mean temperature | Distribution charts and transport/source inspection / statistics queries | Documentation verified; account access untested |
| BigQuery | Both linked surface tables, every forecast field/statistic, schema metadata and available partitions | Table/field explorer, point/region comparisons / bounded parameterized queries | Documentation verified; linked IDs/IAM untested |
| Earth Engine | Both surface collections, every band/property and run/time, permitted reductions, visualization/export operations | Map/layer and region explorer / region, layer and bounded job tools | Forecast surface documented; allowed operations/quotas need live inspection |
| WeatherNext Cyclones via Weather Lab | Documented CSV/ATCF downloads, storm identities, predicted/member tracks, intensity/time, separately attributed paired observations | Cyclone explorer / track inspection and verification tools | Downloads documented; supported automated delivery and access-specific schemas not verified |
| Custom inference | Model-version-specific configuration, job submission/status/result/cancellation where supported and authorized | Advanced, cost-confirmed jobs / scoped job tools | Current guide documents **WeatherNext 2**, separately allowlisted; do not present as WN3 inference |
| Other granted WeatherNext capabilities | Any additional product/version/endpoint named in the user's grant; include a Maps Weather API capability only if explicitly in scope and separately verified | Capability-specific view/tool or a documented blocker | Unknown until grant and API documentation are reviewed; not assumed included |

Weather Lab documents cyclone downloads and distinguishes WeatherNext Cyclones, WeatherNext 3, WeatherNext 2, and MetNet; those products must not be relabelled as one WN3 model. Its webpage is not evidence of a supported programmatic cyclone API. The [custom-inference guide](https://developers.google.com/weathernext/guides/access-vmg) describes WN2, separate project allowlisting, billing and accelerator quotas. These are inventory candidates, not promises that the user's WN3 data approval includes them. [Weather Lab guide](https://developers.google.com/weathernext/guides/weatherlab)

**Registry record required for every discovered capability:** stable `capability_id`, product/model/version, surface, documented operation and resource identifier, documentation revision, actual schema/units/dimensions, temporal/spatial coverage, access status, license/distribution rules, cost/quota bounds, provider adapter, backend route, UI entry point, LangGraph tool mapping, last verified date, test ID, and blocker/owner if any. Distinguish `unverified`, `not_granted`, `blocked_by_terms`, `unsupported`, `planned`, `implemented`, and `verified` states.

- Run discovery using the production identity across every granted surface; store a sanitized manifest and schema fingerprints. Discovery does not download all global values.
- For redundant surface statistics, allow selection/inspection of each granted surface, but choose one efficient transport for routine requests. Querying identical values three times is not greater coverage; do not merge products or runs on name alone.
- New schema fields enter review with an explicit pending status; unsupported units or operations must not be silently published.
- **Coverage accounting:** report discovered count, permitted count, implemented count, verified count, and blocked count separately. Full integration is complete only when every permitted/supported capability has both tested UI and tool mappings; inaccessible items remain visible as blockers, not fake data or false 100% coverage.
- Downloads/exports require their own distribution checks. “Researcher” is a product mode, not automatic permission to redistribute raw experimental forecasts or execute paid cloud operations.

## 4. Recommended architecture

All proposed public endpoints and views below are conditional on permission. First run this architecture privately. This diagram shows the core WeatherNext ingestion path; the complete surface/capability inventory is in section 3a. The shared service applies IMD → WeatherNext → AccuWeather → Open-Meteo for automatic-source requests and preserves explicit WeatherNext pins for research.

```text
WeatherNext statistics (BigQuery OR GCS)    GCS full ensemble
                  \                         /
              scheduled ingestion / bounded research jobs
                     | discover + validate + normalize
                     v
         run catalog + variable catalog + cached point products
              |                               |
       normalized forecast service      research/tile worker
              |                               |
       existing FastAPI backend + authorization + release policy
              |
        Flutter: home / farm / research / chat / voice / maps

Separate sources: current-condition estimates/observations, AQI/UV,
astronomy, long-term archive, authoritative alerts, provider fallback
```

### Ingestion and identity

1. Confirm intended use and terms with Google. Record attribution and territory restrictions, and implement a provider kill switch.
2. Choose a billing project and a keyless production workload identity/attached service account. Confirm allowlist handling for that principal with Google; do not assume the human user's grant transfers. Use least privilege, runtime secrets only when necessary, and never put service-account JSON in Flutter assets, Git, or chat.
3. For BigQuery, subscribe to the official Analytics Hub listing; inspect the linked dataset schema and location. Configure fully qualified table IDs rather than assuming a public table name. Use bounded `init_time` predicates, explicit columns, parameterized coordinates/times, dry runs, and maximum bytes billed. Restrict configured table identifiers to an allowlist.
4. For GCS, inspect one accessible statistics run and one synoptic full-ensemble run. Use compatible pinned `xarray`, `zarr`, `obstore`, and (when using `chunks={}`) Dask dependencies. Select variables/region/time before compute. Profile chunk amplification: a point read can still touch large chunks.
5. Discover available initialization directories/partitions; never construct “now's” path and assume it exists. Catalog publication/ingestion lag and validate completeness per field group before making a run selectable.
6. Schedule refresh checks with bounded retries/backoff; reuse overlapping chunks and collapse duplicate requests. Keep an immutable run cache plus an atomically updated latest-complete pointer. Apply explicit size, retention, and spend limits.

### Run selection

- Select the newest **available complete** run covering each requested product/time range, not simply the latest initialization timestamp.
- Near-term surface views can use an interim run. Long-range and atmospheric views require an eligible synoptic run.
- For a joined near/long-range display, record the source run on each segment. Never imply one coherent 15-day ensemble when the first 48 hours came from another run.
- Daily probabilistic aggregates and farm windows spanning multiple hours should use a coherent single-run member trajectory. Member index 7 in separate runs is not necessarily the same weather scenario.
- Missing/partial/stale data is explicit. Define freshness budgets from observed publication lag and product needs; do not invent an upstream SLA.

### Shared forecast provider

Introduce a backend `ForecastProvider` boundary with normalized results and capability metadata. Home, farmer advice, chat/voice tools, and web clients must use the same selector rather than separate priority implementations.

**Required default order:**

```text
1. IMD              when its server-side credentials and requested product are usable
2. WeatherNext      when granted, complete, fresh, and suitable for the requested product
3. AccuWeather      when credentials, licensed forecast horizon, and fields are usable
4. Open-Meteo       final supported-provider fallback
5. Unavailable      if none qualifies; never substitute fabricated values
```

This is **ordered source selection, not a weighted average**. The current `PROVIDER_WEIGHTS` and Open-Meteo-based outlier anchor must not decide the new default answer. WeatherAPI.com, Tomorrow.io, and OpenWeatherMap are excluded from this automatic chain; retain only explicit, separately labelled comparison/legacy features if needed. Update `/`, `/dev`, provider labels, agent descriptions, tests and web clients that currently advertise the old order.

Selection rules:

1. A configured IMD key is necessary for key-gated IMD products, not proof of valid access or coverage. Verify the actual IMD endpoints, authentication (including tokens if required), region, product, units, and terms before writing an adapter. On missing/invalid credentials, unavailable fields, unsuitable spatial/temporal coverage, timeout, rate limit, or failed quality checks, record the reason and move down the chain.
2. For `source=auto`, select the highest-priority **fresh eligible** source for the requested product/field group. Use coherent same-source/run data for derived humidity/wind, daily aggregation, and multi-hour probabilities; do not combine unrelated marginals, models, or ensemble member identities. Supplementary fields may use another source, explicitly labelled per field.
3. Search for prior complete runs within each provider's freshness/coverage budget. A genuinely stale high-priority result must not outrank a fresh eligible lower-priority one. Only after all fresh sources fail may an explicitly permitted, age-bounded last-known product be shown as stale; otherwise return unavailable. Never use stale data to declare an activity safe or infer an official all-clear.
4. Apply the same priority policy to supported current-condition **estimates**, but observations remain a distinct product. Skip WeatherNext for a request requiring actual observations. Preserve separate definitions for mean-sea-level vs surface pressure, rain vs total precipitation, AQI standards, UV, astronomy, soil/ET0, and long-term history. Priority is not a reason to manufacture an unsupported field.
5. Official IMD warnings are an independent authoritative channel where available and relevant. A lower-provider forecast must not cancel or downgrade them. Failure to retrieve warnings means unknown warning status, not no active alerts.
6. **Explicit researcher/source queries bypass automatic substitution:** `source=weathernext` plus model/run/transport pins must return that data or a precise unavailable/permission/coverage result. Other providers may be offered as separately labelled comparisons, never passed off as WeatherNext. A research ensemble query must not fall back to an unrelated deterministic series.
7. Share bounded timeout, retry/backoff and circuit-breaker policies; cache usable credentials/capability health without exposing secrets. Run discovery/ingestion out of the request path. Do not issue every expensive provider request merely to discard it.
8. Return `requested_source`, `selected_source`, `selection_policy_version`, product, field/segment provenance, and structured `fallback_reasons`; never use a generic “Google-powered” label when IMD or a fallback supplied the displayed value.

The existing AccuWeather integration inspected in `services/fusion.py` fetches **current conditions**, not daily/hourly forecasts. Add and validate a forecast adapter against the user's actual AccuWeather subscription before claiming step 3 works for forecasts. The IMD adapter is likewise new work, not enabled by changing an environment variable alone.

## 4a. Backend authentication and environment configuration

**User requirement:** configure WeatherNext through backend `.env` or the hosting provider's environment/secrets dashboard, without editing source code for project IDs or credentials. **Status: planned configuration contract; no authentication adapter is implemented yet.** This section targets `omsenjalia/weathergpt/backend`, not Flutter's `.env`. The remote backend repository was not modified in this planning session.

A copyable, non-secret template is included at [`weathernext.env.example`](weathernext.env.example). After the implementation lands, merge its settings into the actual backend `.env` without replacing existing provider/LLM settings. Production environment variables take precedence over local dotenv values. Example values are placeholders, not valid credentials or proof of access.

### Project ID is not an OAuth application ID

- **Cloud project ID:** chooses the project for API jobs/resources. The quota/billing project may be the same project or a separately authorized one.
- **OAuth client ID/application ID and client secret:** identify an OAuth application. They do not grant dataset access or authenticate an unattended request on their own.
- **Refresh token:** an additional secret issued through an approved user's consent flow, used with the matching client to obtain short-lived access tokens. It can expire or be revoked; it is not a permanent API key.
- **Service account/workload identity:** a different production principal. Verify allowlist eligibility and resource permissions for that exact principal; the owner's personal approval does not automatically transfer.
- **`GOOGLE_APPLICATION_CREDENTIALS`:** a standard ADC variable containing a trusted credential/configuration **file path**, not an API key, raw JSON string, or OAuth client ID.

There is no planned `WEATHERNEXT_API_KEY` shortcut. Use one explicit authentication mode, backed by the real Google client libraries. [ADC documentation](https://docs.cloud.google.com/docs/authentication/application-default-credentials) [OAuth web-server flow](https://developers.google.com/identity/protocols/oauth2/web-server)

### Mode A — ADC (default and recommended)

```dotenv
WEATHERNEXT_ENABLED=0
WEATHERNEXT_AUTH_MODE=adc
WEATHERNEXT_SURFACE=bigquery
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_QUOTA_PROJECT=your-billing-project-id
```

**Local setup once, on the developer's own computer:**

```bash
gcloud init
gcloud auth application-default login
gcloud auth application-default set-quota-project YOUR_BILLING_PROJECT_ID
```

Choose the Google account approved for WeatherNext. Leave `GOOGLE_APPLICATION_CREDENTIALS` unset when using the generated local ADC file. Quota-project permission and API/resource access are still required; these commands do not grant either. Local ADC contains sensitive credentials: do not commit it, paste it into chat, or copy it into Flutter.

**Production:** prefer an approved attached service account on Google Cloud or Workload Identity Federation on a compatible external host. For federation, configure the provider/audience/trust relationship and use a trusted mounted credential configuration. An environment variable alone does not set up that trust. If a downloaded service-account key is unavoidable, mount it from the backend secret store, restrict access, rotate it, and set its absolute path using `GOOGLE_APPLICATION_CREDENTIALS`; never store it in the repository. Google recommends avoiding service-account keys. [ADC documentation](https://docs.cloud.google.com/docs/authentication/application-default-credentials)

### Mode B — owner-authorized OAuth credentials in environment variables

For an explicitly approved deployment using the allowlisted user's identity, plan an alternative:

```dotenv
WEATHERNEXT_AUTH_MODE=oauth
GOOGLE_OAUTH_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=replace-in-backend-secret-store
GOOGLE_OAUTH_REFRESH_TOKEN=replace-after-approved-user-consent
```

These `GOOGLE_OAUTH_*` names are **our proposed backend configuration**, not variables that Google SDKs automatically consume. A credentials factory must read them and construct refreshable Google user credentials explicitly. No Google Cloud `client_credentials` grant is assumed. **Client ID + secret alone is incomplete configuration.**

One-time bootstrap to implement:

1. Create the appropriate Google OAuth client and configure its consent screen, narrowly appropriate API scopes, and exact authorized redirect URI. A web-server callback uses a web client; do not mix credentials from another client type. Account allowlisting, project/API/IAM setup and linked datasets remain separate prerequisites.
2. Provide a local setup helper or an authenticated, administrator-only bootstrap route. Request offline access from the approved account in the system browser; validate state and use PKCE where supported. The callback must exchange the authorization code server-side and verify the resulting credential identity/scopes. No tokens in browser URLs, response bodies, public logs, or frontend code.
3. Store the issued refresh token securely with its matching client credentials; for the requested environment-based flow, load it from the backend secret store/environment on startup. Do not obtain tokens using an unrelated third-party OAuth client and assume they work with our client secret. If no refresh token is returned, report a reconnect/setup requirement rather than pretending setup succeeded.
4. Use library-managed short-lived access-token refresh. On revoked/expired consent (`invalid_grant`) or missing access, mark WeatherNext unavailable and request administrator reconnection; do not repeatedly prompt app users or silently switch to another Google identity. Account policy and OAuth app testing/verification status may affect token lifetime and usability.

The bootstrap callback/helper is **proposed**, not a working URL. Define `GOOGLE_OAUTH_REDIRECT_URI` only for this setup flow and match the registered URI exactly. Prefer workload identity for unattended production when Google grants it access. [OAuth web-server flow](https://developers.google.com/identity/protocols/oauth2/web-server)

### Dataset, billing and provider settings

The template also specifies:

| Setting group | Required implementation behaviour |
|---|---|
| `WEATHERNEXT_ENABLED` | Default off. Enabling opts into configured provider access, not a permission grant or a license override. |
| `WEATHERNEXT_AUTH_MODE` | Exactly `adc` or `oauth`; reject unknown values. ADC is the default, not an automatic fallback after OAuth errors. |
| `WEATHERNEXT_SURFACE` | Default everyday serving transport: `bigquery` or `gcs_statistics`. Does not disable granted full-ensemble/EE/research capabilities. |
| `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_QUOTA_PROJECT` | Explicit job/resource and quota projects; validate identifiers/permissions. No secrets in these fields. |
| `WEATHERNEXT_BQ_*` | Actual linked surface/station table IDs, correct dataset location, positive per-query maximum bytes billed; explicit columns, init-time bounds and dry runs. WeatherNext 2 and WeatherNext 3 are separate Analytics Hub listings and are therefore linked into **separate datasets** (WN2 and WN3 can never share one); `WEATHERNEXT_BQ_DATASET_2` / `WEATHERNEXT_BQ_DATASET_3` name those datasets and `WEATHERNEXT_BQ_ALLOW_SHARED_DATASET` is the documented escape hatch only if a project really links both. WN2 Mean is its own listing/table again. |
| `WEATHERNEXT_GCS_*` | Allowlisted dataset roots and explicit Requester Pays project; propagate billing headers/options in the storage adapter, not merely the SDK's default project. |
| `WEATHERNEXT_EE_PROJECT` | Optional granted EE capability; validate project registration, API, account permissions and usage category separately. |
| `WEATHER_PROVIDER_PRIORITY` | Required order `imd,weathernext,accuweather,open_meteo`; validate without duplicates/unknown providers. Keys are separately configured using existing `IMD_API_KEY`, `IMD_JWT_TOKEN`, `ACCUWEATHER_KEY` where applicable. |

Subscribe to the WeatherNext Analytics Hub listing and set the **actual linked table names** before using BigQuery. Authentication does not create that subscription. Resource permissions and billing/API activation must be verified against the production identity; access to the Google-managed bucket cannot be granted by merely assigning roles on our own project. [BigQuery guide](https://developers.google.com/weathernext/guides/bigquery)

**Cost expectations:** Google currently states that experimental data access itself is not charged; cloud queries, Requester Pays data access/transfer, processing, caching and hosting may still cost money. Surface statistics and narrowly bounded queries are the first proof, not full-global reads. A `WEATHERNEXT_BQ_MAX_BYTES_BILLED` cap applies to each query, not the whole application or GCS usage. Add aggregate quotas, job/concurrency limits, monitoring and alerts; budget alerts are not a hard spending cap. Free access does not establish permission to distribute forecasts. [Real-time terms](https://storage.googleapis.com/weathernext-public/terms-of-use.pdf) [GCS guide](https://developers.google.com/weathernext/guides/gcs)

### Backend implementation and verification gates

- Add a typed configuration loader and central credentials factory, shared by API adapters and workers. Use supported Google auth/client libraries; ensure the chosen GCS/Zarr transport actually accepts and refreshes the credential provider. Do not assume all third-party storage libraries automatically consume our OAuth environment variables. Validate EE initialization separately.
- Disabled mode performs no Google authentication or reads. Enabled mode validates required settings and rejects blank/placeholders/conflicting credential modes; do not select credentials opportunistically from mixed sources. Standard ADC discovery is allowed only within explicit ADC mode. Report configuration errors clearly without taking unrelated providers offline.
- Add an administrator-only bounded connectivity check: configured → authenticated → resource authorized → tiny dataset read → ready, with separate billing/quota/permission error states. Token minting alone is not a successful WeatherNext integration. Health/diagnostic endpoints must not dump environment variables, credential file contents, refresh tokens, client secrets, authorization headers or raw sensitive exceptions.
- Test dotenv/environment precedence, both credential modes, missing client/secret/refresh token, placeholder IDs, incorrect credential path, invalid auth mode, wrong linked tables/region, 401/403, Requester Pays rejection, quota/billing failure, token refresh/revocation and redacted logs. Mock transports in normal CI; only explicitly authorized smoke tests contact Google and incur bounded usage.
- Configuration failure follows the existing provider policy for `source=auto`; a pinned WeatherNext query returns an explicit failure, not an unrelated fallback. Enabling a provider never changes end-user entitlements or authorizes raw-data distribution.
- Update the actual backend `.env.example`, README, ignore rules and deployment instructions when implementing. Keep secrets in the ignored backend `.env` or secret manager, credential files outside the checkout, and only placeholders in templates. In this app repository, the template is a planning artifact; adding values today will not enable a provider that has not been implemented.

## 5. Data contract proposal

Keep legacy `/weather` functional while migrating clients. Proposed new routes are **not implemented**:

| Route | Purpose and bounds |
|---|---|
| `GET /v2/weather` | Compact current/forecast overview and bounded hourly/daily views |
| `GET /v2/weather/catalog` | Complete entitlement-filtered capability/variable metadata across granted surfaces, units, levels, runs, tool support, and explicit blocked/unavailable states |
| `GET /v2/weather/series` | Selected variables, point, run, valid-time window, statistic; strict variable/time limits |
| `GET /v2/weather/profile` | One location/valid time, selected upper-air fields/levels |
| `GET /v2/weather/ensemble` | Selected member series for bounded scientific requests; restricted authorization |
| `GET /v2/weather/tiles/...` | Run-keyed authorized map tiles, only if permitted; do not expose upstream bucket tokens |
| `GET /v2/weather/cyclones` | Granted cyclone tracks/intensity/member/verification data via a verified adapter, if available |
| `POST /v2/weather/jobs` and scoped job status/cancel/result operations | Bounded extraction/export or separately entitled inference jobs; estimate cost and require confirmation before billable work |

Use asynchronous jobs for expensive regional/member exports, if authorized. Enforce quotas, rate limits, payload ceilings, cancellation, and job expiration; do not accept arbitrary bucket paths or SQL from clients.

Every result should carry:

- `schema_version`, `model`, `model_version`, `product`, `run_id`.
- `init_time_utc`, `ingested_at_utc`, `served_at_utc`, validity range, timezone identifier.
- Requested coordinates and actual sampled grid coordinates/resolution; spatial method and distance.
- Per-field `variable_id`, unit, source, statistic or member ID, level, accumulation bounds, derivation version, quality flag.
- Series points with real UTC timestamps, nullable values, and missing reasons.
- `sources`/segment provenance, `is_stale`, fallback reason, expected/valid member counts, coverage completeness.
- `mode`, capability/product ID, `requested_source`, `selected_source`, `selection_policy_version`, structured fallback reasons, and evidence/job IDs for chat/voice parity.
- Distribution/attribution metadata; never return upstream credentials or internal exception details.

Maintain a native-unit scientific schema internally and an explicitly converted display schema. Do not store timezone-formatted labels as the only timestamp. Cache scientific values independent of locale; cache localized descriptions separately.

## 6. Scientific correctness rules

1. **Units:** K − 273.15 → °C; m × 1000 → mm; m/s × 3.6 → km/h; Pa ÷ 100 → hPa; cloud fraction × 100 → percent. Divide interval solar J/m² by 3600 seconds for one-hour average W/m², or 21600 for six hours. Geopotential ÷ 9.80665 gives geopotential height in meters.
2. **Time coordinates:** Full GCS data uses `lead_time` plus `lead_subtime` for hourly steps; statistics stores are already flattened. Compute valid time from actual coordinate values, not guessed offset signs. Check sorting, duplicates, and expected coverage independently for each variable, including six-hour accumulations. [GCS guide](https://developers.google.com/weathernext/guides/gcs)
3. **Spatial handling:** Inspect coordinate names, order, longitude convention, and masks. Normalize −180…180 input for 0…360 arrays where required; handle wraparound, descending latitudes, coastlines, and missing/below-ground levels. Do not silently use sea-surface temperature on land.
4. **Precipitation products:** Native, IMERG-trained, and experimental precipitation are different estimates of precipitation, not components to add. Keep separate IDs. Choose any default only after local evaluation. Do not add overlapping one-hour and six-hour totals or divide six-hour rain into invented hourly values.
5. **Rain probability:** A chosen threshold/interval event can be estimated from valid member exceedance counts, e.g. fraction with precipitation ≥ 0.1 mm during one hour. Declare threshold, units, interval, valid/expected member counts, and minimum coverage policy. This is an empirical ensemble probability, not automatically calibrated truth. A mean or p90 cannot reconstruct exact rain probability.
6. **Daily uncertainty:** Sum rain (or take temperature min/max) within each member and local day first; then compute quantiles. Summing hourly p90 rainfall is not daily p90 rainfall. Quantiles of daily maxima are not maxima of hourly quantiles. Incomplete local days need coverage labels, not extrapolated totals. Respect 23/25-hour DST days.
7. **Other derived fields:** Compute wind speed from member-level U/V before averaging; speed of mean U/V is not mean speed. Wind-from direction is `(270 - degrees(atan2(v,u))) mod 360`; calm direction is undefined. Derive RH from paired temperature/dewpoint with a documented formulation/range, preferably per member; do not pair unrelated marginal quantiles to claim an RH percentile.
8. **Confidence:** p10–p90 describes ensemble spread, not “80% guaranteed accuracy.” Keep forecast spread, TypeSafe decision confidence, and language-model confidence separate. Preserve the existing conservative advisory overlay policy and test missing-input behavior.
9. **Current/derived semantics:** Forecast values near now are estimates, not observations. Station-head predictions are not live station readings. Condition codes/feels-like require documented derivation or a supplementary source. Do not infer UV from broadband solar energy or fabricate radar, lightning, gusts, snow, waves, soil moisture, or CAPE when not available/validated.
10. **History:** Archived forecasts support hindcast verification; they are not observations or a multi-decade climate baseline. Keep an appropriate historical/reanalysis source for existing researcher climate screens.

## 7. Flutter handoff

The Flutter implementation details have moved to [the app plan](../app/implementation_plan.md). Follow [the app README](../app/README.md) in `omsenjalia/weathergpt-app`; do not copy backend credentials or Python modules into Flutter.

This backend document retains the client audit and shared API requirements as integration context, not instructions to implement Flutter files in the backend repository.

## 7a. Shared mode contract

The [mode-specific product contract](../app/implementation_plan.md#3-mode-specific-product-contract) is shared with the app. Backend requests must accept validated `everyone`, `farmer` and `researcher` modes, preserve legacy `farmer_mode` compatibility, use real supplied farm context and enforce entitlements independently of mode. The backend must provide the correct structured data; the app controls its presentation.

## 7b. LangGraph: complete WeatherNext data access

**Required invariant:** for every authorized and supported researcher capability, at least one schema-validated LangGraph tool reaches the same backend service and data product used by the UI. This applies to structured results, not just a link or a sentence that claims the agent can access it. The orchestrator and mode specialists can use the shared catalog; mode determines routing/presentation, while server authorization determines access.

Proposed graph (new architecture, not present today):

```text
validated request context (mode, identity, location, farm context, source constraints)
      → intent/task router
          → Everyone specialist | Farmer specialist | WeatherNext Research specialist
          → shared authorized ToolNode wrappers → provider selector / pinned WeatherNext adapters
          → deterministic analysis + evidence checks
          → mode-appropriate text, typed cards/charts, evidence or job references
```

A specialist may be a routed node using the same LLM; no separate paid model is required. Use one reusable tool registry instead of duplicating adapters per persona. Farmer/Everyone specialists may delegate complex data retrieval to the WeatherNext specialist without displaying the full researcher UI.

### Proposed tool families (app tools, not claimed Google endpoint names)

| Tool | Capability coverage and typed arguments |
|---|---|
| `list_weathernext_capabilities` | Product/version/surface filters, permitted operations, variables, units/dimensions, availability, costs and blockers |
| `list_weathernext_runs` | Product/model, surface, bounded init/valid-time window, completeness and horizon |
| `query_weathernext_data` | Validated capability/variable IDs, selected point or bounded region, exact run/time range, member/statistic, level, grid and transport; generic route covers approved fields not in convenience tools |
| `get_weathernext_profile` | Selected upper-air variables and levels for location/run/valid time |
| `analyze_weathernext_ensemble` | Member trajectories and approved threshold/interval/aggregation functions; deterministic code, not LLM arithmetic |
| `compare_weathernext_products` | Explicit product/run/precipitation-variant/surface comparisons with units and time alignment; preserve separate provenance |
| `get_weathernext_map_layer` | Approved variable/run/time/level/statistic layer or bounded raster result through the same mapping adapter |
| `get_weathernext_cyclone_tracks` | Granted storm/model/run/member/time/intensity/observation fields, only after the delivery contract is verified |
| `prepare_weathernext_job`, `submit_weathernext_job`, `get_weathernext_job`, `cancel_weathernext_job` | Cost-bounded extraction/export or separately entitled inference; opaque job ownership checks and server-validated user confirmation before expensive execution |
| Existing general weather/farm tools | Use the IMD-first selector for automatic-source requests; preserve the same optional source constraints, farm context and result evidence |

Tool return envelope: `status`, capability/model/run, effective query, source(s), units, validity/freshness, member/coverage counts, evidence ID, compact data/summary, warnings, and optional paginated artifact/job reference. Use precise states such as `not_granted`, `unavailable`, `unsupported`, `pending_job`, `budget_exceeded`, or `partial`—never replace a failed research query with a sunny forecast.

### Required backend wiring and controls

- Register tools in `backend/agent.py` for both `.bind_tools(...)` **and** `ToolNode(...)`; generate both from the same registry and test that the sets match. All configured fallback tool-calling LLMs must bind the same capabilities. Current `_llm` and `_app` are global: do not mutate global tool permissions/prompts per user; enforce authorization in request-scoped tool wrappers/context.
- Extend `AgentState` with validated mode/source constraints and evidence/job references using mechanisms compatible with the pinned LangGraph version. Review whether a library upgrade is needed; do not assume newer APIs exist in the current `langgraph==0.2.28` environment.
- Update `services/chat.py` intent classification/TypeSafe routes: ensemble, pressure-level, run-specific, catalog, cyclone, export and inference requests must reach the capable tool path, not the existing short current-weather/rain fast path. Weather-related scientific analysis is in scope; broad keyword matches such as “Python” must not automatically discard an otherwise valid weather-data request. Do not add arbitrary code execution.
- Update the deterministic/LLM-timeout path to honor mode, source pins and requested product. If it cannot execute a scientific task, return capability-aware unavailability or a pending job; do not substitute unrelated general weather. Text-only localization models format supplied evidence and must not invent additional data.
- Agents access **all authorized data on demand**, not all raw grids in the prompt. Bounded subsets and computed summaries enter context; large arrays stay server-side behind authorized artifact references. External LLM processing of experimental data requires its own terms/contract review; do not assume cloud data access permits sharing with Groq/TypeSafe or another processor.
- All parameters are validated/allowlisted. No model-supplied credentials, arbitrary SQL, unrestricted URLs, filesystem/GCS paths, code execution, or cloud resource provisioning. Treat dataset metadata and downloaded text as untrusted data, never instructions.
- Compute unit conversion, daily quantiles, exceedance counts and agronomic thresholds in tested code. Every numerical claim/card has an evidence reference; UI and agent results for the same query must match within stated tolerances. A model request for `source=auto` cannot silently remove an explicit user source pin.
- Paid inference/export job confirmation is a server-validated user action with estimated bounds, not an LLM saying “confirmed.” Apply per-user quotas, maximum bytes/member/time/region dimensions, cancellation and retry/idempotency controls.

## 7c. Jev / TypeSafe improvements using WeatherNext evidence

**Expanded backend roadmap:** [Jev backend expansion plan](jev_backend_plan.md). It specifies **45 initial feature IDs** across routing/orchestration (8), farmer decisions (12), Everyone guidance (5), researcher assistance (8), evidence/answer quality (7), and operations (5). The registry remains extensible rather than imposing a feature-count ceiling. Each feature requires evidence, a typed Jev role, deterministic constraints, fallback, an owner and tests.

The detailed plan adds module-by-module backend work, user/admin endpoint contracts, shared LangGraph decision tools, versioned input/output schemas, feature-level off/shadow/enforce controls, evaluation, privacy/cost safeguards, diagnostics and rollback. A separate [Jev environment template](jev.env.example) contains existing settings plus clearly labelled proposed controls. These additions do not reinstate the withdrawn custom-map or notification proposals.

Status: **proposed improvements to the existing decision integration**, not model retraining or a claim of measured accuracy gains. The previously withdrawn map/extra-feature proposals remain withdrawn. No new Jev API or fine-tuning capability is assumed: keep the existing `Choice`, `Score`, and `Noul` request types in `services/typesafe.py`.

### What Jev currently receives and does

In the inspected backend/bundle, `services/advisory.py::daily_stats` reduces hourly data to maximum rain probability, total rain, peak wind, temperature extrema and thunder-code counts. `build_state` includes crop/location and optional growth stage, soil and irrigation. `build_questions` asks for three activity Scores and one daily Choice. `apply_typesafe_overlay` may make advice more conservative; it is not the forecast source. Separately, `services/chat.py` uses Jev for intent/abuse routing and an optional reply check. The latter currently sees the question and reply, **not the weather tool evidence**, so it cannot establish meteorological correctness merely by approving the text.

### First: fix correctness before richer AI inputs

Four targeted offline pure-function checks were run against the existing local `services/advisory.py`, which matches the earlier pinned backend source:

| Verified finding | Required change / regression proof |
|---|---|
| A time-only hourly record produces `spraying=good` because missing rain/wind become zero and missing temperature is ignored | Explicit nullable inputs and a data-sufficiency gate before scoring. Unknown critical data returns `insufficient_data` or conservative unavailability, not “safe.” Tests cover null, missing, short arrays, nonfinite values, and missing thunder/alert coverage. |
| Different-day questions have identical instructions that say “this day” without the actual date | Embed the exact date, timezone, activity/window ID and evidence ID in each independently evaluated question. Ensure question IDs map to immutable evidence records rather than relying on model inference from `d0`/`d1`. |
| The top-level `overall_verdict` chooses the highest-confidence day, so it can be tomorrow=`good` while today remains `poor` | Return date/window-scoped decisions. UI Today/Tomorrow must consume their respective evidence. If a period summary is desired, define its semantics explicitly and never use a highest-confidence day as the period's safety verdict. |
| The advisory `_num_field` accepts NaN; `band_from_score(NaN)` becomes `good` metadata | Reject nonfinite and out-of-range Scores/confidences, unexpected types/options and inconsistent probability distributions. Treat invalid answers as no opinion. This finding does not mean the conservative merge currently clears an unsafe day. |

Additional source-review fixes: the router's `high >= 40` branch unconditionally assigns `caution` even after rain assigned `poor`; merge hazards using the worst applicable band. Validate short arrays in `daily_stats` rather than indexing them unchecked. Preserve independent official-warning gates. These fixes belong to the deterministic baseline, so they also protect requests where Jev is off or unavailable.

### Proposed pipeline: compute facts first, let Jev judge constrained choices

```text
IMD-first provider selection + separately labelled WeatherNext ensemble evidence
    → deterministic validation, freshness/coverage and official-warning gates
    → deterministic member-wise feature extraction and candidate time windows
    → compact versioned decision context + farm profile
    → optional Jev Choice / Score / Noul evaluation
    → deterministic conservative merge + evidence-linked result
    → LangGraph explanation / Flutter cards / voice
```

WeatherNext is the forecast model; Jev is the optional decision layer; LangGraph orchestrates tools and explanations. More data improves available evidence, not automatically the underlying Jev weights. Do not dump all raw arrays into Jev or ask it to calculate event probabilities, derive meteorological variables, determine Google permissions, or reorder providers.

### New decision context

Build a `DecisionContextV2` in backend code with:

- Source/model/run, selected-provider policy, UTC interval and local timezone, issuance/ingestion age, grid resolution, completeness, missing reasons, and official alert status. Keep IMD primary data and supplementary WeatherNext evidence separately attributed; do not merge them into invented ensemble members.
- Selected activity, exact candidate start/end, crop/growth-stage and supplied soil/irrigation context. Label whether soil information is a profile category or a measured state. Soil type alone does not establish moisture or irrigation need.
- Backend-computed rain accumulation/temperature/wind distributions, relevant quantiles, and explicit **event threshold + interval + valid/expected member count**. Distinguish derived empirical probabilities from validated/calibrated probabilities.
- For joint work conditions, count members whose complete trajectories satisfy all approved rain/wind/temperature constraints over the candidate interval. Do not multiply hourly probabilities, combine unrelated marginal quantiles, or splice members from different runs. Use full-ensemble data; surface summary percentiles alone cannot supply exact joint risks.
- For rain-sensitive work, calculate the required post-activity dry period using validated agronomic/product-label constraints, not a universal invented threshold. Missing gust/lightning observations or relevant warnings remain unknown even if forecast mean wind/rain look benign.
- A bounded list of deterministic risk flags, constraint outcomes and candidate IDs. Use a structured budgeted serializer; current `typesafe.evaluate` truncates `state` to 8,000 characters. Never let blind truncation drop the date, official warnings, provenance or missing-data indicators while keeping a favourable conclusion. Batch only complete contexts with explicit question-to-evidence bindings.

If only deterministic forecasts or summary statistics are available, pass that limitation explicitly. Jev must not invent ensemble spread or exact event probabilities to fill the gap.

### Highest-value uses of Jev

| Use | Typed question / responsibility | Controls |
|---|---|---|
| **Window-specific farm advice** | Score each already-defined candidate for spraying/irrigation/field work in the supplied crop context; Choice among permitted candidate IDs, `defer`, `need_more_data` | Code establishes eligibility first. Jev can prefer or downgrade eligible candidates, never clear a hard exclusion or prescribe irrigation solely from forecast rain. Start with current activities; add sowing/harvest only with validated rules. |
| **Ambiguous farm context** | Choice of a narrowly scoped follow-up, e.g. missing crop stage vs moisture observation vs task duration, when that changes the advice | Required-input checks remain deterministic. Ask only for relevant information; an optional Noul opinion is not proof that missing evidence is sufficient. |
| **Research intent routing** | Extend existing route Choices for ensemble/profile/run comparison/cyclone queries and authorized jobs, using mode + capability availability | Route to LangGraph tools; do not retrieve raw datasets merely to classify intent. Preserve explicit source/run pins and prevent the general-weather fast path from swallowing research requests. |
| **Evidence-aware reply assessment** | Noul checking whether a draft is supported by the bounded, provenance-linked tool results and respects uncertainty/official-warning constraints | Numeric/source/time checks run in code first. Jev assesses semantic support, not objective truth without observations. A high score cannot authorize a fabricated claim or override a failed deterministic check. |

This is improving an existing advisory feature, not restoring the withdrawn notification/custom-map proposal.

### Decision policy, outputs and confidence

- Keep Jev optional. Missing key, timeout, malformed/low-confidence answer or model outage returns the validated deterministic baseline. If the baseline lacks critical evidence, that baseline is unavailable/cautious—not permissive.
- Preserve the current conservative overlay until a new window-level policy is independently evaluated. An activity/day exclusion stays in force; new window ranking must not silently undo it. Scope any future window veto to its evidence interval, while official warnings/validated all-day hazards retain their full coverage.
- Validate supported Score ranges against the current five criteria, confidence/probability bounds, finite values and exact Choice options. Fix the advisory-specific parser rather than assuming the generic TypeSafe accessors already protect every path.
- Return `decision_id`, activity/window/date, rule verdict, Jev verdict, applied final verdict, `decision_confidence`, weather `event_probability`, evidence-quality flags, reason/evidence IDs, model ID and rule/feature versions **as separate fields**. Do not multiply these numbers into a new “overall confidence.”
- Do not present “Jev 90% confident” as “90% chance the weather will occur” or “90% safe.” Whether decision confidence is calibrated for Gujarat crops/seasons and these new inputs must be measured; the SDK/vendor description is not validation of our application.
- Reasons must refer to verified input flags or constrained reason categories. LangGraph may explain them in the user's language but cannot invent justifications from a confidence score alone.
- Keep raw measurements and TypeSafe keys server-side. Minimize crop/location detail sent to the processor, review Google data-sharing/contractor rights before sending experimental forecasts to TypeSafe, and obtain appropriate permission for private farm context. If forwarding is not allowed, retain deterministic processing; summarization is not automatically a licensing exemption.

### Implementation, evaluation and rollout

1. **Correctness first:** fix missing-data behaviour, question date binding, per-day metadata selection, numeric validation and non-monotonic hazard merging; add regression tests for all four confirmed findings and reviewed hazards.
2. **Shadow mode:** introduce the versioned feature builder/context serializer and compare three paths on the same fixtures: deterministic-only, current Jev, WeatherNext-enriched Jev. Do not change user-visible advice yet.
3. **Evaluation:** use time/region-held-out forecast/observation data for weather-event reliability and agronomist-reviewed scenarios/outcomes for decision quality. Never treat Jev agreement or provider agreement as ground truth. Measure unsafe clearances, unnecessary vetoes, abstention/coverage, activity/date binding, confidence reliability, latency and actual API usage. Include rare hazards, missing data and provider fallback cases.
4. **Controlled enablement:** choose confidence gates from the evaluated task, not an untested assumption that the existing `0.55` remains appropriate. Version templates/criteria/rules and record the resolved model where the service exposes it; prefer a supported pinned model over blindly relying on `jev-latest` for reproducible experiments. Keep rollback and a kill switch.
5. **Budgets:** cache decisions by evidence/run/location/activity/farm-profile and model/rule/template versions under appropriate user isolation; batch relevant questions only. Measure billed usage and p95 latency; existing comments that fan-out is “free” are not a guarantee of zero cost or constant latency. Bound the total deadline across retries, not just each HTTP attempt.

Changes target `services/advisory.py`, `routers/mobile.py`, `services/typesafe.py`, `services/chat.py`, a new deterministic decision-feature module, and the farmer/voice models that consume results. Keep all work on these features distinct from weather-provider credentials. Existing `TYPESAFE_API_KEY`/`TYPESAFE_MODEL` still configure Jev; WeatherNext credentials do not grant Jev access. Add a proposed `TYPESAFE_WEATHERNEXT_MODE=off|shadow|enforce` rollout control (default off), with explicit configuration validation and permissions checks before outbound calls. `off` leaves the existing Jev integration unchanged; deterministic correctness fixes apply independently.

Verification performed for this planning addition: four direct calls to existing pure functions, no network or live Jev credentials, confirmed the findings above. No fixes, new feature extraction, API calls, comparative evaluation or full application test suite were performed. Any accuracy improvement remains a hypothesis until shadow evaluation passes.

## 8. Rollout and acceptance tests

### Phase A — permission and one-point private proof

- Confirm intended distribution, production identity, all granted Google surfaces/products, budget, deployed backend source, initial regions, and IMD/AccuWeather product entitlements. Enumerate the capability registry from the actual grant, not just the initial WN3 variable table.
- Inspect live schema and retrieve one bounded surface series plus one upper-air/member slice using the production identity.
- Produce a sanitized metadata manifest and small allowed fixture, not credentials or a bulk global download.
- Measure publication lag, latency, bytes read/billed, and missing values. No public endpoints enabled.

**Pass:** access and contract verified, terms decision recorded, predictable bounded cost.

### Phase B — primary forecast adapter in shadow mode

- Implement the IMD → WeatherNext → AccuWeather → Open-Meteo selector and compatibility layer in shadow mode without changing user output. Separately validate the new IMD/AccuWeather forecast adapters and WeatherNext-pinned research requests.
- Tests: Kelvin/meter/Pa conversions; solar interval conversion; calm wind; member-first wind aggregation; precipitation threshold counts; missing members; native vs IMERG separation; daily quantiles; interval overlaps.
- Tests: interim-to-synoptic selection, incomplete/new run rejection, stale fallback, no mixed-run member trajectories, coordinate wraparound, land/ocean masks, missing pressure levels, UTC/local boundaries and DST.
- Simulate 403, 429, timeout, schema drift, nonfinite data, partial writes, permission revocation, and cost-cap failures.

**Pass:** deterministic tests and existing backend suite pass; observational verification is separated from provider-to-provider comparison. Agree measurable latency, freshness, cost, and forecast-skill targets before enabling traffic.

### Phase C — app and shared feature rollout

- Contract-test legacy/new responses; widget-test null, stale, fallback, missing-code, large-font, translated, and uncertainty states.
- Verify all shared surfaces agree on run/units/source: home, farmer, chat, voice. Apply the mode, capability, and LangGraph acceptance matrix below.
- Test that missing forecasts never produce “safe to spray,” 0% rain, or clear sky by default.
- Build provider kill switch and rollback; enable approved cohorts/features gradually.

**Pass:** client tests/analyzer/build and full backend integration tests pass, permission/attribution implemented, telemetry and rollback tested.

### Phase D — complete scientific coverage

- Add profiles, members, maps, and bounded exports only as permitted.
- Inventory reconciliation: every discovered capability, operation and variable across every granted WeatherNext-related surface/version has a UI path, LangGraph tool mapping and verification result, or an explicit blocker. Report coverage counts separately; no silent omission or claim that blocked functionality is implemented.
- Cross-check selected values/statistics against the same upstream run/grid; validate raw-derived vs precomputed statistics within documented tolerances.
- Load/cost testing includes map pan/zoom, repeated queries, many distinct locations, and concurrent expensive research jobs.

**Pass:** documented catalog coverage, validated outputs, bounded payloads/costs, no raw public-data bypass.

### Required acceptance matrix for the user update

| Requirement | Minimum proof before release |
|---|---|
| Three distinct modes | Widget/contract tests for Everyone's existing cards + at most two compact enhancements; Farmer's profile-specific views; Researcher's full explorer. Verify mode change propagation, legacy `farmer_mode` mapping, conflicting fields, invalid values, and chat/voice parity. |
| IMD first | Mock a valid, fresh, supported IMD result and ensure selection over all others; no IMD key/invalid auth/out-of-area/unsupported product advances to WeatherNext with a reason. An active official warning remains visible regardless of forecast source. |
| Ordered fallbacks | WeatherNext unavailable → eligible AccuWeather; then Open-Meteo; then unavailable. Test 403/429/timeout/nulls, partial fields, time horizons, stale high-priority vs fresh lower-priority data, and circuit breakers. WeatherAPI/Tomorrow/OpenWeather must never enter the default chain. |
| Pinned research source | With IMD available, a WeatherNext-specific request still returns the requested Google product/run. If absent, return explicit failure, not IMD/AccuWeather masquerading as WeatherNext. |
| Coherent science | Enforce source/run/member coherence for every derived risk/daily product; never sum percentiles or splice member trajectories. Distinguish forecast/observation and pressure/AQI/precipitation definitions. |
| Complete capability coverage | Compare live manifest to registry: zero unaccounted-for capabilities; every permitted/supported capability has a verified view, tool mapping, and test. All blocked/unverified items remain counted and labelled; schema additions fail coverage review until accounted for. |
| Real agent access | Execute mocked end-to-end ToolNode calls for all tool families, not just check prompts. Verify `.bind_tools`/ToolNode parity across model fallbacks, evidence correctness, raw-vs-summary selection and UI equivalence. Separately gate credentialed smoke tests. |
| Advanced routing | Ask for a 500 hPa profile, all members' rainfall for a bounded point/time, a precipitation-variant comparison, a specific archived run, and any granted cyclone/inference operation. Ensure each reaches its correct adapter or an explicit blocker, not the ordinary weather fast path. |
| Jev expansion | Reconcile all 45 proposed feature IDs against the detailed registry/caller/fallback/test matrix; planned/blocked features do not count as implemented. Regress missing-data fail-open, per-day question binding, top-level verdict confusion and nonfinite scores; test evidence-aware reply checks, conservative merge, bounded context serialization and retries, TypeSafe outage and shadow/off/enforce modes. Evaluate against independent observations/expert labels, not model agreement. |
| Backend environment/authentication | Verify ADC and explicit OAuth configuration, one-time consent bootstrap, refresh/revocation, correct authorized principal, bounded real-data smoke read, Requester Pays/BigQuery caps and secret redaction. Client ID + secret alone must fail validation. |
| Security and spend | Forged researcher mode does not grant entitlement; unauthorized jobs/artifacts and arbitrary SQL/URLs fail. Dataset prompt injection cannot alter tool policy. Test cross-user cache/context isolation and server-side confirmation for costly jobs. |
| Farmer and voice correctness | Use the actual farm profile; no hardcoded Wheat, 78%/12 mm voice cards, synthetic favourable offline windows, or safe verdicts from missing/stale critical inputs. |

These are **planned acceptance tests**, not passing application-test results. Verification covers source-to-plan mapping, documentation consistency and whitespace, plus the four targeted existing-function Jev checks described in section 7c. No runtime provider switch is performed.

## 9. Remaining questions and limitations

1. Was approval for experimental internal access, a controlled research demo, or public consumer distribution? Is there a custom agreement overriding default terms?
2. Which WeatherNext surfaces/products are in your grant and currently work: GCS, linked BigQuery tables, Earth Engine, cyclone data, or separately approved inference/other APIs? Sanitized approval scope and resource/schema identifiers are sufficient; never share private keys/tokens.
3. Is backend commit `1004061` the deployed revision, and where does it run? Source access is confirmed; the repository includes a Vercel entrypoint but does not establish the active hosting environment.
4. What regions, expected traffic, monthly cloud budget, and rollout sequence should we use for the three confirmed modes? Final researcher scope is all authorized capabilities, not just the first release slice.
5. Which IMD and AccuWeather products/endpoints are enabled by your subscriptions, with what horizons, fields, quotas and terms? Key presence alone does not answer this.

Self-critique: the public catalog is not a live inspection of your account's schema. Publication lag, chunk layout, IAM eligibility, and product permission have not been verified. The GitHub backend source was inspected at commit `1004061`; its deployed revision remains unverified. The mobile router and chat service match the local bundle at that commit. Flutter/Dart executables and backend Python dependencies were not available during this documentation audit; no app/backend test suites, builds, or live cloud queries were run. Static checks are not a substitute for those tests. These are reasons to start with the private one-point proof, not a broad provider replacement.

## Official references

- [2](https://developers.google.com/weathernext/guides/models) — model, cycles, grids, variables.
- [9](https://developers.google.com/weathernext/guides/access-forecast) — access surfaces and scope.
- [GCS guide](https://developers.google.com/weathernext/guides/gcs) — paths, dimensions, raw ensemble, billing, slicing.
- [BigQuery guide](https://developers.google.com/weathernext/guides/bigquery) — linked datasets, nested forecast schema, statistics and partitioning.
- [Disclaimers](https://developers.google.com/weathernext/guides/disclaimers) — experimental status, official warnings, applicable licenses.
- [Real-time terms](https://storage.googleapis.com/weathernext-public/terms-of-use.pdf) — use, redistribution, attribution, territory restrictions; linked revision dated 2026-09-03.
- [Weather Lab guide](https://developers.google.com/weathernext/guides/weatherlab) — documented cyclone downloads and distinct model products.
- [Custom inference access](https://developers.google.com/weathernext/guides/access-vmg) — currently documents WN2 and separate project allowlisting/compute requirements.
