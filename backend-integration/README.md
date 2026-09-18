# TypeSafe System One (Jev) integration — apply to `omsenjalia/weathergpt`

This directory contains a **ready-to-apply integration of [TypeSafe AI](https://docs.typesafe.ai)'s
System One model ("Jev")** into the WeatherGPT backend (`omsenjalia/weathergpt`), plus the
matching client support already merged into this Flutter app.

TypeSafe is not a text model: you send a `state` plus **typed questions** (Choice / Score /
Noul) and receive structured answers with **probabilities and confidence** that code can
branch on directly. That makes it a drop-in upgrade for the two most brittle heuristics in
the backend — and it is why the integration is **server-side**: the API key never ships in
the mobile app (matching this repo's own rule in `api_client.dart`).

## What was integrated

| # | Backend surface | Before | After |
|---|---|---|---|
| 1 | `services/chat.py` intent routing | substring keyword lists (`SIMPLE_MARKERS`, `OFF_TOPIC_MARKERS`, …) | one batched System One call per turn: a **Choice** over the same intent labels + three **Noul** probes (`answerable from live data`, `is smalltalk`, `is abuse/prompt-injection`). Confidence-gated; keywords remain the fallback. `/chat` `meta` gains `intent_engine` + `intent_confidence`; high-abuse turns short-circuit to a canned reply (`meta.path: "guarded"`) without waking the Groq agent |
| 2 | `routers/mobile.py` `GET /advisory` | per-day thresholds only (`rain >= 70% → poor`) | **hourly** per-activity bands (irrigation / spraying / field work) for the app's action-window bars, plus **one fan-out System One call** scoring each day on each activity (days × 3 **Scores** + a daily **Choice** verdict). Optional `growth_stage` / `soil` / `irrigation` query params enrich the state (the same judgment differs by growth stage) |
| 3 | `routers/dev.py` | LLM diagnostics only | `ai_decisions` block: `typesafe_enabled`, `typesafe_model`, `chat_routing`, `advisory_scoring` — plus **`GET /dev/intent?text=…`**, an inspector that runs the shared `decide_intent()` and shows keyword vs System One answers, the full route probability distribution, which engine wins, and whether the message would take the fast path |
| 4 | `services/chat.py` agent replies (opt-in) | agent output trusted as-is | with `TYPESAFE_REPLY_CHECK=1`, one **Noul** checks the reply answers the question safely; only an extreme "no" (< 0.15) downgrades to the deterministic telemetry reply. Gate failures never lose a good answer |

### The merge policy (code stays in control)

Following TypeSafe's *confidence-gated routing* and *composite scoring* patterns
(docs.typesafe.ai/patterns):

- Every System One failure (no key, timeout, 4xx/5xx, malformed body) returns `None` and the
  previous deterministic behavior runs unchanged. **TypeSafe is never a hard dependency.**
- Answers below `TYPESAFE_*_MIN_CONFIDENCE` (default 0.55) are recorded but change nothing.
- A high-confidence daily verdict can only make a day **more conservative** — the model can
  veto a risky day; it can never clear a bad one.
- A high-confidence `Unsafe` activity score floors that activity's hourly cells to `avoid`
  for the whole day (safety floor on the app's bar charts).
- No generated text anywhere in the response — verdicts select from canned copy by band.

### Files

```
backend/services/typesafe.py     # thin httpx System One client (zero new dependencies)
backend/services/advisory.py     # hourly threshold bands + overlay merge (pure, unit-tested)
backend/services/chat.py         # TypeSafe-first intent routing (keyword fallback preserved)
backend/routers/mobile.py        # /advisory: hourly bands + AI overlay + additive fields
backend/routers/chat.py          # meta: intent_engine / intent_confidence
backend/routers/dev.py           # ai_decisions diagnostics
backend/.env.example             # TYPESAFE_* configuration
backend/tests/test_typesafe.py   # System One client + routing tests (httpx.MockTransport)
backend/tests/test_advisory_ai.py  # hourly bands, overlay merge, endpoint-level
backend/tests/test_chat_guard.py   # abuse probe, reply gate, /dev/intent inspector
patches/0001-add-typesafe-system-one-integration.patch   # core integration (one commit)
patches/0002-extend-typesafe-abuse-reply-gate-intent-inspector-farm-context.patch  # v2 (apply after 0001)
```

Apply **both patches in order** (or just copy the `backend/` files here over the backend
repo's `backend/` — they are the final v2 state):

Option A — apply the patch to a checkout of `omsenjalia/weathergpt`:

```bash
git clone https://github.com/omsenjalia/weathergpt && cd weathergpt
git apply --check /path/to/backend-integration/patches/0001-*.patch
git apply /path/to/backend-integration/patches/0001-*.patch
git apply --check /path/to/backend-integration/patches/0002-*.patch
git apply /path/to/backend-integration/patches/0002-*.patch
git commit -am "Add TypeSafe System One integration" && git push origin master
```

Option B — copy the files under `backend/` here over the backend repo's `backend/`
directory (they are full, final versions of the touched files).

Then set the key in the backend environment (local `.env`, Render/Vercel dashboard — never
in the app):

```
TYPESAFE_API_KEY=<key from https://console.typesafe.ai/settings/keys>
# optional tuning (see backend/.env.example for the full list)
# TYPESAFE_MODEL=jev-latest
# TYPESAFE_INTENT_MIN_CONFIDENCE=0.55
# TYPESAFE_ADVISORY_MIN_CONFIDENCE=0.55
```

Verify:

```bash
cd backend && python -m pytest tests/ -q          # 85 tests, all offline
curl -s "http://localhost:8888/advisory?lat=22.56&lon=72.95&crop=Wheat&days=2" | jq .ai
curl -s -X POST localhost:8888/chat -H 'Content-Type: application/json' \
  -d '{"message":"rain in anand today?","location":"Anand"}' | jq .meta
```

No key configured? Everything still works exactly as before (`advisory_engine:
"thresholds"`, `intent_engine: "keywords"`) — that state is covered by tests.

## How the Flutter app consumes it (already merged here)

- `Farm Action Windows` no longer uses mock data: it fetches `/advisory?days=7`, renders the
  24-hour activity bands (12 two-hour buckets, worst-of per bucket), the 7-day strip, and a
  **"System One · NN% confident"** badge when the AI layer shaped the verdict. Offline or on
  backend errors it falls back to the bundled baseline with a notice banner.
- Chat shows a subtle **"Routed by System One · NN%"** chip under assistant replies when the
  backend's intent engine was System One (`meta.intent_engine`).
- Mapping rules live in `lib/features/farmer/models/advisory_models.dart`
  (pure Dart, unit-tested in `test/advisory_models_test.dart`).

## More ways to use Jev — evaluated roadmap

Judged against the "fast, structured gut-check that code consumes" bar (and the
note that Jev adds value over an LLM only where calibrated probabilities matter):

| Candidate | Primitive sketch | Status & why |
|---|---|---|
| **Abuse / prompt-injection probe** | Noul riding in the intent fan-out | **done (patch 0002)** — zero extra latency, protects the Groq quota |
| **Reply quality gate** on agent output | 1 Noul on question+reply | **done (patch 0002, opt-in `TYPESAFE_REPLY_CHECK=1`)** |
| **`/dev/intent` inspector** | reuses the routing call | **done (patch 0002)** — ops + SIH demo surface |
| **Farm context in advisory state** | state enrichment | **done (patch 0002)** — growth stage/soil/irrigation change the judgment |
| Geocoder disambiguation ("Anand": Gujarat vs Punjab) | Choice over geocoder candidates, user's state as context | worth doing inside `tools.py` when a live key is available for tuning; the LangGraph agent usually disambiguates its own path already |
| Fusion arbitration / calibrated fusion confidence | Noul "is this vendor reading plausible?" when spread > 7 °C; replace the `high/medium/low` spread string with a calibrated value | promising but touches the hot `/weather` path — needs live-key evaluation against real provider disagreements first |
| Sowing / harvesting as 4th–5th advisory activities | 2 more Scores in the same fan-out (nearly free) | natural next step once the app has a seasonal calendar UI to render them |
| IMD CAP alert urgency ranking | Score "how urgent is this alert for this village given the forecast?" | blocked on the IMD official API keys (roadmap item in the backend) |
| Push-notification gating ("is this worth waking the farmer for?") | Noul with thresholds by hour of day | blocked on push infrastructure existing at all |
| Anomaly narrative labels ("delayed monsoon" vs "erratic spell") | Choice over narrative classes for the researcher screens | good fit, low priority until the researcher feature set grows |

**Deliberately NOT Jev** (lookup tables / deterministic code are better): AQI color
bands, language identification (`langdetect`), unit conversion, rain-chance
thresholds, anything requiring arithmetic over arrays. Jev is for *judgment under
ambiguity*, not for lookups — using it there would add latency and cost for worse
determinism.

## Verification notes

- The full backend suite passes offline (85 passed) with both the TypeSafe transport and
  Open-Meteo mocked via `httpx.MockTransport` — no network or key needed in CI.
- `api.typesafe.ai` was not reachable from the build sandbox at authoring time (egress
  allowlist), so live-API behavior should be smoke-tested once with a real key using the
  curl commands above.
