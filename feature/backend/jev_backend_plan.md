# Jev backend expansion plan

> **Implementing AI — cleanup required:** after implementation and required verification are complete, migrate lasting documentation/non-secret configuration examples, remove this completed temporary plan and its superseded planning templates, and repair all links. Preserve unfinished plans, source code, tests and real credentials. Follow the [owning-folder cleanup instructions](README.md#required-final-step-remove-completed-planning-artifacts).

Status: **planning only; not implemented or evaluated**. Target: `omsenjalia/weathergpt/backend`, audited previously at commit `1004061d7e6c25fce5e52566bff66519f13e9212`. This document is the detailed Jev section of the [WeatherNext backend blueprint](weathernext_3_integration_plan.md#7c-jev--typesafe-improvements-using-weathernext-evidence). Remote backend files have not been changed. For setup see [Backend README](README.md); client changes belong to [the app plan](../app/implementation_plan.md).

## 1. Scope and definition of success

The user requested maximum useful Jev functionality across the backend. Treat this as an extensible decision platform, not an artificial limit to the current three farm Scores. There is no fixed ceiling on future registered features, but every feature must have valid evidence, a typed contract, deterministic safeguards, evaluated usefulness, authorization and controlled cost.

Do not interpret broad feature scope as unlimited API calls, access to unlicensed data, autonomous physical actions, an ability to retrain Jev, or permission to bypass official warnings. The previously withdrawn custom-map and notification proposals remain withdrawn; this roadmap improves existing weather, farmer, researcher and conversational workflows.

### Division of responsibility

| Component | Owns | Does not own |
|---|---|---|
| Provider selector | **IMD → WeatherNext → AccuWeather → Open-Meteo**, with capability/freshness checks and explicit source pins | Model-selected provider priority or opaque blending |
| WeatherNext / other data providers | Forecast evidence, ensemble members/statistics and metadata as actually available | Farm suitability judgments or official IMD warning status |
| Deterministic feature/rule layer | Time/units, quality validation, member-first statistics, thresholds, eligibility, costs, permissions and provenance | Inferring missing measurements from plausible defaults |
| Jev | Constrained Choice, Score and Noul judgments over verified context | Numeric meteorology, authorization, ground truth, uncontrolled tool execution |
| LangGraph | Task planning, registered tool execution, explanations and follow-up | Inventing evidence or relaxing server constraints |
| Client | Mode-appropriate cards, uncertainty, dates and evidence, accepting user preferences/confirmation | Supplying trusted model results or secrets |

No new TypeSafe API is assumed. Use the inspected `services/typesafe.py` client and its existing `Choice`, `Score`, and `Noul` builders. Vendor wording about calibration, batching or model intelligence does not establish application-specific accuracy, zero cost or constant latency.

### Stages and gates

1. **Baseline correctness** → regression fixes and trustworthy missing-data behaviour, even with Jev disabled.
2. **Decision platform** → typed registry, evidence models, bounded execution and audit trail.
3. **Shadow evaluation** → compare existing Jev, expanded Jev and deterministic-only outputs without changing user advice.
4. **Core integrations** → routing, evidence-aware replies and current farm activities enabled per feature after evaluation.
5. **Extended capability rollout** → additional registered farmer/everyone/researcher decisions, each with its own evidence and review gate.
6. **Operational verification** → access isolation, cost/latency, model/template changes, replay and rollback.

Self-review gate at every stage: source/target mapping exists, evidence is adequate, no hard rule was relaxed, missing/error paths are tested, and evaluation limitations are recorded. Require independent reviewer approval for safety-sensitive releases; this planning audit itself is not independent-agent review.

## 2. Existing integration and mandatory fixes

Existing code uses Jev for intent classification, abuse probing, daily activity suitability/overall verdict, and an opt-in reply-quality check. Preserve supported old contracts during migration. No key or Jev failure must remain a supported operating state.

Four direct offline pure-function checks in the parent plan confirmed these findings; they are not fixes or end-to-end test results:

| Finding | Required implementation |
|---|---|
| Missing weather arrays can produce a good spraying band | Nullable inputs and a required-evidence gate. Never coerce unknown rain/wind to zero for safety advice. |
| Different days have identical question text saying “this day” | Embed exact date, timezone, activity/window ID and evidence ID in every independently evaluated question. |
| Global overall verdict chooses the highest-confidence day | Store and display date/window-scoped decisions; define any period aggregation separately. |
| Nonfinite advisory Scores are accepted and can become good metadata | Shared strict answer validation; invalid output is no opinion, not good. |

Additional inspected hazards to fix: short arrays can be indexed past their end; router heat handling can downgrade `poor` to `caution`; missing thunder codes imply no thunder; generic fixed “6–10 AM” copy need not match computed windows; Flutter voice and offline farm cards contain canned values. Fix these deterministic/client behaviours independently of Jev enablement.

Do not loosen the current conservative activity/day veto while moving to window-level assessment. A new preference rank is not authority to clear an existing exclusion. Any eventual change in veto granularity requires separate validated rules and migration tests.

## 3. Feature catalog

All rows below are **proposed**, including expanded versions of the simpler functionality identified in section 2. `C` = Choice, `S` = Score, `N` = Noul. The feature ID is stable and must have a registry entry, UI/agent caller, evidence schema, fallback and test. Primitive selection is a design proposal to validate against the current API.

Common fallback: ignore invalid/low-confidence model output; use deterministic, evidence-backed behaviour or abstain/ask for missing inputs. An unsupported feature returns an explicit capability result. No feature changes provider order or bypasses licensing.

### A. Conversation, routing and LangGraph orchestration

| ID | Feature and Jev role | Required evidence / hard boundary |
|---|---|---|
| `route.intent` | C: classify current, daily, hourly, farm, profile, ensemble, historical, comparison and explanation tasks | User request, mode and permitted capability manifest; weather-specific research must not be rejected by a broad “Python” keyword. |
| `route.followup` | C: choose the most useful clarification (location, date, crop stage, activity duration, variable/level) | Deterministic ambiguity detection and allowed questions; do not invent dates or ask for irrelevant private details. |
| `route.location` | C: select among geocoder candidates, or ask the user | Candidate IDs, region/context and match evidence; never fabricate coordinates or silently use Ahmedabad for another city. |
| `route.specialist` | C: choose Everyone, Farmer or Researcher task handler | Explicit selected mode remains authoritative for presentation; task delegation does not change entitlements. |
| `route.tool_plan` | S/C: rank candidate registered tool plans by fitness to the request | Code generates eligible plans from the registry and fixed source constraints; no arbitrary URL/SQL/code tools. |
| `route.complexity` | C: simple deterministic answer, multi-tool analysis, clarification or bounded async job | Actual task dimensions/requirements and code-estimated cost; permission and spending confirmation remain deterministic. |
| `route.repair` | C: choose a permitted recovery step after a failed/partial tool result | Typed error, requested source/run, available capabilities; no silent source substitution on pinned requests. |
| `route.injection_review` | N: supplementary prompt-injection/role-manipulation signal | Treat user/dataset text as untrusted; never rely on Jev as the sole enforcement layer or expose hidden prompts. |

### B. Farmer decisions and work planning

These are weather-informed decision support, not prescriptions or guarantees. Use supplied farm context, measured inputs when required, validated agronomic rules and applicable product-label restrictions. Exact irrigation amounts, pesticide dosing and automated equipment control are not delegated to Jev.

| ID | Feature and Jev role | Required evidence / hard boundary |
|---|---|---|
| `farm.spray_windows` | S/C: rank eligible spraying windows or defer | Member-derived joint rain/wind/temperature context, post-application dry period and applicable limits. Missing gust/lightning/label constraints cannot be inferred from mean wind. |
| `farm.irrigation_timing` | S/C: compare permissible timing candidates or request moisture evidence | Forecast rain, supplied crop stage, irrigation system, verified soil moisture/water balance when needed; soil type is not current moisture. |
| `farm.field_work` | S: judge weather suitability of bounded manual/mechanical work windows | Heat/cold, rain/wind and authoritative warnings; field access/trafficability requires soil/drainage evidence, not rain alone. |
| `farm.sowing_transplanting` | S/C: rank dates/windows under approved crop-specific rules | Soil temperature/moisture, crop calendar and frost/rain outlook where available; missing agronomic inputs must produce a blocker. |
| `farm.harvest_windows` | S/C: rank weather-compatible harvest candidates | Crop readiness supplied/verified, wetness/rain/wind constraints, operation duration; forecast weather does not establish maturity or grain moisture. |
| `farm.fertilizer_windows` | S/C: assess supplied application plan against rain/wind risks | Approved agronomy/product constraints and operation type; no generated fertilizer rates or runoff claims without supporting data. |
| `farm.drying_windows` | S/C: compare produce/grain drying windows | Relevant humidity, temperature, wind and rain evidence plus process constraints; do not predict final moisture from weather alone. |
| `farm.heat_cold_response` | C: choose from expert-approved crop/worker precautions | Correctly defined stress/frost metrics, source limitations and warnings; no unsupported medical or absolute frost-free claims. |
| `farm.disease_watch` | S/C: prioritize scouting under validated crop-specific weather-risk rules | Actual disease-risk model inputs/region validation; weather suitability for disease is not diagnosis of infection or treatment selection. |
| `farm.operation_sequence` | C/S: rank feasible multi-operation schedules | A deterministic constraint solver supplies candidates, dependencies/resources/time windows and weather risks; Jev is not the optimizer or an actuator. |
| `farm.multiplot_priority` | C/S: rank eligible tasks across user-owned plots | Plot contexts, task urgency and comparable evidence; honor ownership and native forecast resolution, not false plot-level precision. |
| `farm.counterfactual` | C/S: explain preferences across bounded what-if plans | Backend recomputes features for changed task time/duration or supplied constraints; changing a plan does not change forecast reality. |

### C. Everyone-mode guidance

Keep the normal dashboard and at most the two previously proposed compact WeatherNext enrichments. These features primarily enrich answers or existing detail views, not a new wall of metrics or push notifications.

| ID | Feature and Jev role | Required evidence / hard boundary |
|---|---|---|
| `everyday.outdoor_window` | C/S: compare eligible times for a walk, commute or outdoor event | Time/location-specific weather and warnings, activity duration; general planning advice, not assurance of safety. |
| `everyday.preparation` | C: select concise rain/heat/cold preparation advice | Approved guidance catalog and actual conditions; no medical diagnosis or fabricated UV/AQI. |
| `everyday.summary_focus` | C: prioritize the most relevant verified facts | User's question/preferences plus evidence; official warnings cannot be suppressed for brevity. |
| `everyday.uncertainty_copy` | C: choose an appropriate uncertainty explanation | Actual spread/coverage/calibration status; decision confidence cannot be presented as weather probability. |
| `everyday.comparison` | C/S: compare candidate times/places for a stated weather preference | Backend-aligned quantities and source/time provenance; surface tradeoffs, not a universal “best city” claim. |

### D. Researcher assistance across all authorized WeatherNext data

Jev assists query planning and interpretation; deterministic scientific code performs calculations. No feature limits the complete authorized WeatherNext catalog to only these examples.

| ID | Feature and Jev role | Required evidence / hard boundary |
|---|---|---|
| `research.variable_selection` | C: match a scientific question to catalog variables/products | Real catalog IDs and descriptions; mean-sea-level and surface pressure, rain variants, grids and model versions remain distinct. |
| `research.statistic_selection` | C: select member data, quantile, mean or event metric suitable for the question | Method metadata and availability; no exact joint probability reconstructed from marginal percentiles. |
| `research.run_selection` | C: select among code-filtered eligible runs when the user leaves the choice open | Completeness, init/valid/publication times and task horizon; explicit source/run pins always win. |
| `research.comparison_plan` | C/S: choose a valid comparison design | Aligned products/times/units and sampling methods; provenance and resolution limitations cannot be ignored. |
| `research.profile_focus` | C: choose variables/levels to inspect for a stated atmospheric question | Granted pressure-level fields with masks; calculations and below-ground exclusions remain deterministic. |
| `research.anomaly_review` | C/N: prioritize statistically detected anomalies for review | Backend-computed outlier tests and appropriate baselines; model opinion does not establish a physical extreme or data error. |
| `research.verification_plan` | C: select appropriate metrics from a vetted method registry | Forecast type and independently sourced observations; code computes bias, errors, Brier/reliability/CRPS where applicable, not Jev. |
| `research.job_plan` | C/S: rank allowed extraction/inference job plans or suggest a smaller query | Actual granted capabilities, costs and quotas; separate user confirmation for spend, no assumed WN3 custom-inference entitlement. |

### E. Evidence, answer quality and responsible uncertainty

| ID | Feature and Jev role | Required evidence / hard boundary |
|---|---|---|
| `quality.semantic_support` | N: flag draft statements not supported by tool evidence | Claim-to-evidence links and draft; numerical/unit/time/source checks run in code first. Model approval cannot repair a failed check. |
| `quality.uncertainty_alignment` | N/C: detect overconfident wording or select safer copy | Forecast distribution, missingness and validation status; no multiplication of unrelated confidence numbers. |
| `quality.cross_surface` | N: flag semantic contradiction across cards, chat and voice | Same evidence IDs/date/window and deterministic field comparisons; facts are fixed, not voted on by models. |
| `quality.translation` | N/C: assess whether localized explanation preserves meaning and urgency | Source statement, approved terminology and immutable numbers/units; use human-reviewed language fixtures, not model self-approval alone. |
| `quality.task_completion` | N: detect omitted requested dates/variables or an irrelevant answer | Validated original request, structured tool outputs and draft; incomplete coverage must be disclosed, not concealed by an affirmative score. |
| `quality.evidence_followup` | C: choose a useful next evidence request from allowed options | Deterministic evidence gaps; critical missing-data gates have already blocked unsafe actions, regardless of Jev's view. |
| `quality.disagreement_explanation` | C: choose supported explanation categories for provider/run disagreement | Code-detected differences, resolution/timing/product metadata; never claim a provider is wrong without validation or change configured priority. |

### F. Reliability, diagnostics and developer workflows

| ID | Feature and Jev role | Required evidence / hard boundary |
|---|---|---|
| `ops.issue_triage` | C/S: prioritize redacted incidents for operator review | Validated error codes, impact and deterministic severity floors; cannot mute security/official-warning failures. |
| `ops.fallback_explanation` | C: choose truthful user-facing fallback wording | Selector's recorded reason and actual source; cannot hide an outage or relabel fallback data as Google data. |
| `ops.review_sampling` | S: help prioritize ambiguous decisions for expert review | Deterministic random/rare-case sampling remains to prevent selection bias; no training on user data without permission. |
| `ops.regression_triage` | C: group mismatches in offline model/template evaluation | Gold fixtures and diffs; model guesses do not turn a failing test green. |
| `ops.operator_assist` | C: suggest an approved investigation checklist | Redacted metrics/run/version evidence; no autonomous secret rotation, IAM edits, deployments, policy changes or billing actions. |

There are **45 initial feature IDs**. The registry is extensible: future authorized WeatherNext capabilities can add feature entries without duplicating provider adapters or changing the safety boundary. A feature being in this catalog does not mean it is enabled or that all its required inputs currently exist.

## 4. Registry, evidence and decision contracts

### `DecisionFeatureSpec`

Every feature must declare:

- Stable feature/version ID, owner, description, mode-specific callers and primitive type.
- Required/optional evidence fields with units, intervals, source constraints, coverage/freshness requirements and sensitivity/processor-sharing tags.
- Candidate construction, hard exclusions, allowed choices or ordered Score criteria; Noul's precise proposition and limitations.
- Template version, exact question-to-date/window/evidence bindings, selected model and supported model identifier/version metadata.
- Per-feature confidence gate, validated fallback/abstention semantics, expected latency/cost class and execution tier.
- Audit/replay policy, linked regression/evaluation suite, release state (`off`, `shadow`, `enforce`) and operator-visible blocker.

Registry access is controlled configuration, not arbitrary user-supplied prompts. New or changed entries require review and tests. The same registry generates discovery metadata, Jev requests, parser validation and LangGraph wrapper availability.

### `DecisionContextV2`

Normalize context before calling Jev:

- Request ID, explicit mode, user/session authorization scope and requested source/product/run pins.
- Server-resolved location/timezone, exact UTC and local intervals, activity/plot IDs and supplied farm context with origin/time.
- Evidence IDs, model/run/version, init/valid/publication/ingestion times, sampled grid/resolution, field source, units and scientific derivation version.
- Valid/expected members and time samples, masks, incompleteness and reasons, official-warning status with validity and last successful retrieval.
- Backend-calculated distributions, counts, thresholds, complete-trajectory event probabilities and coherent derived fields.
- Permitted candidate IDs with constraint outcomes, deterministic baseline, required clarifications and allowed recovery paths.

Unknown values stay null with a reason. All calculations are native scientific-code operations, not natural-language inference. Use a compact deterministic serialization budget: the current transport slices state at 8,000 characters. Reject/split oversized contexts at safe boundaries rather than losing warnings, date bindings or data-quality flags. Do not rely on questions seeing each other's answers within a batch.

### `DecisionResultV2`

Return a stable envelope rather than letting each route invent metadata:

```text
schema_version, decision_id, feature_id/version, request_id
mode, activity/plot_id, interval, evidence_ids, requested/selected_source
execution_mode, status, deterministic_verdict, model_verdict, final_verdict
selected_candidate_id, score/criteria, decision_confidence
weather_event_probability (with event definition), evidence_quality
constraint_flags, reason_codes, missing_inputs, suggested_followup
model_requested/resolved, template/rule/feature_versions
latency_ms, attempts, usage_if_reported, cache_state, created_at, expires_at
```

Statuses include `evaluated`, `abstained`, `insufficient_data`, `not_authorized`, `unsupported`, `budget_exceeded`, `provider_unavailable`, `invalid_answer` and `pending_job`. Preserve evidence flags even if an infrastructure error dominates the status. Internal diagnostics must be separated from safe client-visible fields.

Jev confidence, weather probability and evidence quality are separate. No universal confidence threshold is assumed; calibrate/task-test thresholds and display labels. Reasons must reference actual evidence or approved reason categories, not generated rationalizations. An audit trail records structured outcomes, not hidden chain-of-thought.

## 5. Execution architecture and integration targets

```text
request → auth/mode/source constraints → feature selection
        → resolve required evidence through shared weather services
        → deterministic quality/official-warning/constraint gates
        → generate eligible candidates and typed questions
        → feature-scoped cache + bounded Jev calls
        → strict answer validation → conservative merge/abstention
        → structured result + evidence → LangGraph explanation/client
        → redacted audit + evaluation metrics
```

Authorization must run before data access and before outbound processing. Check both the app user's entitlement and permission to send this data to TypeSafe. An external processor is not entitled to all WeatherNext data merely because our backend can read it. If forwarding is prohibited, skip Jev and retain deterministic processing; summaries are not automatically exempt from licensing.

### Planned modules and exact changes

| Target | Work |
|---|---|
| `backend/services/typesafe.py` | Retain HTTP transport; add shared strict finite/range validation, total-deadline-aware retries, usage/error taxonomy and safe telemetry. Do not hardcode feature logic here. |
| `backend/services/decisions/models.py` | New typed feature, context, evidence and result models; nullable/unknown semantics and compatibility serializers. |
| `backend/services/decisions/registry.py` | New versioned registry and feature/mode capability discovery. |
| `backend/services/decisions/features.py` | New deterministic weather/farm/research feature extraction with scientific tests. Split by domain as it grows. |
| `backend/services/decisions/policy.py` | New candidate constraints, eligibility, warning floors, confidence gates, abstention and immutable provider/source rules. |
| `backend/services/decisions/engine.py` | New bounded execution, batching, cache, retry budget, per-feature rollout and audit orchestration. |
| `backend/services/decisions/questions.py` | New versioned Choice/Score/Noul templates with date/window/evidence IDs, reviewed independently of transport. |
| `backend/services/advisory.py` | Fix confirmed bugs; adapt existing thresholds and conservative overlay to the decision contracts, preserving old response fields during migration. |
| `backend/routers/mobile.py` | Route advisory requests through shared forecasts and decisions; fix monotonic hazards and per-day output mapping. |
| `backend/services/chat.py` | Extend routing/research choices; provide evidence to reply checks, preserve fast-path/fallback policy and explicit source constraints. |
| `backend/agent.py` and `backend/tools.py` | Register decision wrappers in both `.bind_tools` and `ToolNode`; request-scoped mode/permissions, not global mutable user state. |
| `backend/schemas.py` | Add optional structured decision/evidence fields to existing chat contracts without breaking legacy `response`/`meta`. |
| `backend/routers/decisions.py` | New typed discovery/evaluation/result endpoints under explicit user/admin authorization. |
| `backend/routers/dev.py` | Protected decision inspector, shadow comparison and redacted failure counters; do not extend today's dev surface with public private-data access. |
| `backend/tests/` + versioned evaluation fixtures | Contract, pure-function, mocked transport, end-to-end tool and regression suites; no live paid calls in normal CI. |
| Flutter farmer/chat/voice models/providers | Parse date/window-scoped results and abstention states; remove canned values and misleading global confidence; every displayed decision ties to evidence. |

### Proposed application endpoints (not TypeSafe API endpoints)

| Route | Purpose / authorization |
|---|---|
| `GET /v2/decisions/capabilities` | User-authorized features, inputs, modes and blockers; no secrets or private registry internals. |
| `POST /v2/decisions/evaluate` | Validated feature ID, location/time/activity preferences; server fetches/verifies evidence. Do not trust client-asserted forecast facts. |
| `GET /v2/decisions/{decision_id}` | Owned, authorized result with safe evidence references and expiration. |
| `POST /v2/decisions/{decision_id}/feedback` | Optional user feedback with consent and input validation; not a mechanism to change active policy or create ground-truth labels automatically. |
| `GET /admin/decisions/health` | Protected counters: enabled features, dependency state, latency, abstention and quota budget; redacted identities/errors. |
| `POST /admin/decisions/replay` | Authorized offline replay of retained permitted evidence against specified versions; redaction, retention and replay-cost gates. |
| `GET /admin/decisions/evaluations/{id}` | Protected evaluation/shadow report; no automatic promotion based on model self-approval. |

Use bounded batches/async jobs for large evaluations. Researcher mode is not an administrator role. The frontend cannot set `enforce`, replace a safety policy, pass secrets or access another user's decision by guessing its ID.

### LangGraph tool families

Add `list_decision_capabilities`, `evaluate_weather_decision`, `compare_eligible_windows`, `request_missing_context`, `assess_reply_evidence` and `get_decision_result` wrappers as appropriate. All wrappers delegate to the same registry/engine, never to raw model-controlled TypeSafe HTTP calls.

The intent gate can use the request/capability manifest without fetching all weather. Evidence-dependent decisions run only after tool results exist. Reuse one result within a turn; avoid routing → decision → reply-check loops with no stopping condition. Graph recursion, tool calls, total elapsed time and paid work remain bounded; exceeding the budget returns a clear partial/unavailable result.

## 6. Configuration and operations

A separate [Jev environment template](jev.env.example) distinguishes existing settings from proposed controls. Merge it deliberately into the backend `.env`; do not overwrite working credentials or expose it through Flutter.

- Existing `TYPESAFE_API_KEY`, `TYPESAFE_ENABLED`, `TYPESAFE_MODEL`, base URL, routing/advisory/reply-check controls remain supported.
- `TYPESAFE_WEATHERNEXT_MODE=off|shadow|enforce` controls expanded WeatherNext-informed behaviour. **Off preserves the existing Jev paths**; deterministic correctness fixes apply regardless. `TYPESAFE_ENABLED=0` disables all Jev calls, including shadow/replay routes.
- A proposed feature allowlist plus reviewed per-feature policy controls deployment. A global `enforce` setting cannot enable an unreviewed, unentitled or terms-blocked feature. Features without a reviewed policy stay off.
- Shadow means no user-visible changes, not “no data leaves the server” or “no cost.” Permissions, consent, budgets and retention gates apply equally.
- Authentication/Google credential setup remains in the parent plan. A WeatherNext credential is not a TypeSafe key and vice versa.

### Reliability and performance

- Enforce a request-wide deadline across all Jev calls, retries and backoff, including optional reply checks. Per-attempt timeout is not a total deadline; abandon retries that cannot fit remaining time.
- Bounded retry with jitter for retryable failures only, circuit breaker, concurrency limits and request coalescing for identical permitted contexts. No uncontrolled fan-out across every feature or every hour/member.
- Cache immutable decisions by evidence/run/interval/region, activity/farm-profile, rules/template/model and authorized ownership scope. Official-warning changes, evidence refresh, profile edits or version changes invalidate affected decisions.
- Coalesce duplicate in-flight work, but do not promise exactly-once billing for uncertain upstream failures unless the provider supports and documents idempotency. Replaying a stored result is distinct from making another Jev call.
- Show separate provider-unavailable, insufficient-evidence and Jev-unavailable statuses. Never let a working model conceal missing weather evidence.
- Record p50/p95 latency, failure/timeout/rate-limit rates, calls and reported usage, invalid-answer rates, abstention/coverage, vetoes and cache hits. Do not assume batching is free because an existing comment says so.

### Security, privacy and lifecycle

- Least-privilege service access; authorization before evidence retrieval, decision read, feedback, replay and external processing.
- Minimize private farm/location data. Store structured decisions/provenance by default, not raw prompts, secrets, full arrays or raw model payloads. Evidence hashes are not anonymization guarantees.
- Define retention/deletion and access controls for records, derived features and feedback. Expiring a result must not leave an accessible raw-data artifact indefinitely. Do not archive experimental data beyond granted rights.
- Treat crop names, uploaded context, downloaded metadata and chat text as data, not instructions. Validate text lengths/enums, escape for serialization, and separate trusted templates from untrusted values.
- No autonomous IAM changes, provider priority changes, physical equipment control or paid job confirmation by Jev. Human approval/explicit user actions remain outside model authority.

## 7. Evaluation and acceptance matrix

Compare three baselines on the same valid evidence: deterministic-only, current Jev, expanded Jev. Only claim an improvement after evaluation. Evaluate weather probabilities with independently sourced observations and decision quality with reviewed agronomic/task labels and available outcomes; these are different targets.

| Area | Required tests / release evidence |
|---|---|
| Confirmed bugs | Missing/short/null/nonfinite arrays; date-bound questions; no highest-confidence-day substitution; invalid Scores; worst-band hazard merging; no canned favourable windows. |
| Registry coverage | Every one of the 45 initial IDs maps to schema, caller, fallback, owner and test; future IDs require the same. Planned/blocked does not count as enabled or verified. |
| Scientific features | Member-first daily/interval aggregation, actual valid-member counts, joint trajectories, Celsius/Kelvin and wind/rain units, timezone/DST, pressure masks, mixed-run rejection and partial-day handling. |
| Model contracts | Valid/malformed Choice/Score/Noul responses, finite ranges, absent fields, unknown options and contradictory distributions; every batch question binds to the right evidence. |
| Safety monotonicity | Jev cannot clear a hard exclusion, downgrade an official warning, turn unknown into safe, or alter the IMD-first order; low confidence produces no opinion. |
| Modes and sources | Everyone remains concise, Farmer uses actual profile, Researcher reaches full authorized capabilities; pinned WeatherNext queries never become another provider's answer. |
| Evidence-aware replies | Wrong unit/date/source/number, unsupported certainty, incomplete answer and multilingual meaning changes are caught by deterministic checks plus reviewed semantic evaluation. |
| Failure and cost paths | No key, disabled/off/shadow/enforce, timeout, 429/5xx, consent/data-sharing refusal, full budgets, cache expiry and outdated model/template; safe fallback without retries escaping the total deadline. |
| Privacy/authorization | Cross-user cache/job/result/replay access denied; researcher cannot invoke admin operations; no keys/refresh tokens/raw private context in logs. |
| Independent evaluation | Time/region/crop/season-held-out cases, rare hazards and missingness; confusion matrix, unsafe-clearance and unnecessary-veto rates, abstention/coverage, calibration/reliability, language quality and p95 cost/latency. Report sample size and uncertainty, not only aggregate accuracy. |
| Expert review | Agricultural operations and thresholds reviewed by qualified domain experts; feedback is not automatically truth. Preserve blind/random review samples to avoid only reviewing cases Jev finds interesting. |
| Version changes | Regression replay for supported model/template/rule updates; pin a supported model/version if available and record resolved metadata. Do not promise reproducing stochastic calls exactly. |
| Rollback | Demonstrate feature-level disable and global Jev kill switch; existing APIs keep operating with evidence-valid deterministic responses or explicit unavailability. |

Set numerical acceptance thresholds and permitted risk/latency/cost budgets before testing each feature. Critical safety invariants have zero allowed violations in release fixtures, but that is not a claim of zero real-world risk. Use explicit sign-off, cohort rollout and monitoring rather than auto-promoting a model because it scored its own answers well.

### Rollout order

1. Correctness fixes and typed nullable data; existing behaviour preserved where correct.
2. Registry/engine, shadow infrastructure, routing and semantic evidence checks.
3. Spraying, irrigation timing and field-work windows with validated context.
4. Everyone guidance and researcher query/method assistance, without additional unsolicited dashboard complexity.
5. Extended agronomic activities only when their inputs/rules are validated; diagnostics and expert-reviewed model/template evolution throughout.

## 8. Remaining limitations and decisions

- The deployed backend revision, live TypeSafe contract/quotas/billing, supported model versions and processor terms still need verification.
- Google access and permission to forward data to TypeSafe are separate gates. No amount of prompt engineering creates missing rights or missing soil/lightning/observation data.
- The full feature catalog is deliberately broad; domain-specific inputs for several farmer features are not currently in WeatherNext or the app.
- Adding evidence does not retrain Jev. No fine-tuning, guaranteed accuracy, constant fan-out cost or universal confidence calibration is promised.
- This document and the environment template are planning artifacts. No new backend feature, endpoint, model invocation, runtime test suite or deployment was performed in this update.

**Definition of done:** every approved feature has an implemented registry entry, typed input/output, deterministic evidence/safety gates, UI/agent integration, regression and independent evaluation results, cost/access controls, observability and tested rollback. Unavailable or blocked features are reported explicitly instead of being described as complete.
