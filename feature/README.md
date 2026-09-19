# WeatherNext + Jev: start here

**These folders contain plans and environment examples, not executable feature code.** There is currently no WeatherNext integration script, migration, new provider adapter or expanded Jev service to run. The existing Jev integration is separate from the proposed expansion.

The folder names are ownership labels inside this app checkout—not Git branch names or deployed services. No remote backend repository was modified.

## Mandatory cleanup after implementation

**Instruction to the implementing AI:** once the relevant plan is fully implemented and its required verification passes, remove its temporary planning files and templates from `feature/backend/` or `feature/app/`. Do not leave completed plans behind as unfinished work. Do not delete them now or while implementation/access/testing is incomplete.

Before deletion, migrate lasting setup/deployment documentation, API contracts, evaluation records and non-secret environment examples into the actual owning repository. Update all links, including this guide and the root README, to the maintained destinations. Keep the other component's unfinished plan intact; completion on one side does not imply completion on the other. After both are complete, remove this temporary handoff guide and empty feature directories. Inspect first and preserve any unrelated files added later.

This cleanup does **not** include implementation code, tests, real `.env`/credential files, or the pre-existing `backend-integration/` bundle. Root `AGENTS.md` also records this user requirement. The final implementation report must state which planning files were removed and where permanent documentation was retained.

## Which folder belongs where?

| Folder | Target repository / working directory | What you do with it |
|---|---|---|
| [`backend/`](backend/README.md) | `omsenjalia/weathergpt`, inside `backend/` | Implement the Python/FastAPI data, auth, provider, Jev and LangGraph changes. Merge backend environment examples only after their settings are supported. |
| [`app/`](app/README.md) | `omsenjalia/weathergpt-app`, repository root | Implement Flutter models/providers/UI against the backend contract. Set only the public backend URL in the app `.env`. |

```text
feature/
├── README.md                         ← this guide and remaining work
├── backend/
│   ├── README.md                     ← backend setup / execution boundary
│   ├── weathernext_3_integration_plan.md
│   ├── jev_backend_plan.md            ← 45 proposed, extensible decision features
│   ├── weathernext.env.example        ← Google access + dataset/billing settings
│   └── jev.env.example                ← existing/proposed TypeSafe controls
└── app/
    ├── README.md                     ← Flutter setup / execution boundary
    ├── implementation_plan.md         ← extracted app work and mode contracts
    └── app.env.example               ← BACKEND_URL only; no secrets
```

**Do not run `.md` or `.env.example` files.** Read the plans, implement the changes, then run the actual applications. Environment examples are not shell scripts; do not blindly source them or overwrite existing configuration. The subfolder READMEs provide commands for running the existing applications and make clear that doing so does not enable the planned features.

## What is left?

There is no need to add more speculative features before implementation. The important remaining work is:

- [ ] Confirm Google-approved usage/distribution and whether data may be sent to Jev/Groq or other processors.
- [ ] Inventory the actual granted WeatherNext resources and verify a bounded data read using the approved local/production identity.
- [ ] Confirm the deployed backend revision/host, IMD and AccuWeather product entitlements, and cloud budget.
- [ ] Implement provider/auth/ingestion/cache/contract modules and IMD → WeatherNext → AccuWeather → Open-Meteo selection. Run heavy ingestion separately from short API requests.
- [ ] Fix the identified missing-data, per-day verdict, numeric validation and canned-advice bugs before enriching Jev.
- [ ] Implement/evaluate the Jev registry and shared LangGraph tools, beginning in shadow mode; the 45-item catalog is not already running.
- [ ] Agree versioned fixtures/contracts, then implement and test Everyone/Farmer/Researcher views and real chat/voice cards in Flutter.
- [ ] Run offline suites, bounded credentialed smoke tests, scientific/decision evaluations, device builds, cost/load checks and rollback tests.

App work can start against mocked contracts while backend work proceeds, but live rollout depends on compatible, authorized backend endpoints. Explicitly source-pinned WeatherNext research queries must not silently fall back to another provider.

## Configuration boundary

- Backend secrets: Google credentials/OAuth refresh token where applicable, `TYPESAFE_API_KEY`, IMD/AccuWeather credentials and other server provider keys.
- App configuration: `BACKEND_URL` only. The current Flutter `.env` is bundled into the app; it cannot protect secrets.
- Google OAuth client ID + client secret alone are **not** WeatherNext authorization. See the backend authentication plan for ADC/workload identity or the consent-based refresh-token flow.
- Keep new WeatherNext and expanded Jev switches off until implementation/access checks pass. Filling a template today does not activate unimplemented code.

## What was moved vs left alone

The newly written plans and backend templates were moved from `docs/` and the top level of `backend-integration/` into these folders. Flutter-specific planning was extracted to `app/` and all handoff links were updated.

Existing source under `lib/`, existing tests, and the pre-existing `backend-integration/backend/` and `backend-integration/patches/` bundles were **not** moved or changed. Those bundles document earlier work and are not the new WeatherNext implementation. The separate React dashboard in `omsenjalia/weathergpt/frontend` still needs its own client migration if web/mobile parity is required.
