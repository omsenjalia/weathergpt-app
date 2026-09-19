# Backend files — use with omsenjalia/weathergpt/backend

[Back to feature guide](../README.md) · [Flutter app files](../app/README.md)

**Target:** the Python/FastAPI backend in `omsenjalia/weathergpt/backend`, not this Flutter repository and not its partial `backend-integration/` bundle. This folder holds planning artifacts only. No new WeatherNext/Jev implementation, install script or database migration exists here to execute.

## Required final step: remove completed planning artifacts

The user requires the implementing AI to remove the temporary files in `feature/backend/` **after this component is implemented and verified**. First preserve its lasting contracts, setup instructions, test/evaluation records and non-secret configuration examples in the owning repository, then update incoming links. Do not remove unfinished work or the other component's plans. Do not delete application code, tests, real environment/credential files or unrelated integration bundles. See the [cleanup policy](../README.md#mandatory-cleanup-after-implementation).

If these files are handed to an AI working in another checkout, carry this requirement with them. Copying templates or writing code without passing the required acceptance gates does not complete the plan. Report the cleanup and permanent documentation destinations in the final handoff.

## File-by-file instructions

| File | Purpose | Run or copy? |
|---|---|---|
| [weathernext_3_integration_plan.md](weathernext_3_integration_plan.md) | Data catalog, Google authentication, provider priority, storage/cache, contracts, LangGraph coverage and rollout | Read/use as the backend implementation specification. Do not execute. |
| [jev_backend_plan.md](jev_backend_plan.md) | 45 proposed decision features, modules, schemas, safeguards and evaluation | Read/use as the Jev implementation specification. Do not execute. |
| [weathernext.env.example](weathernext.env.example) | Planned provider/Google/dataset/billing settings | After support is implemented, merge required settings into the real backend `.env` or hosting secret/environment dashboard. Do not replace existing settings. |
| [jev.env.example](jev.env.example) | Existing TypeSafe settings plus planned Jev expansion controls | Preserve current working settings; new controls are not supported yet. Start expansion in `off`, then validated `shadow`. |

Both templates mention `TYPESAFE_WEATHERNEXT_MODE`: the WeatherNext template has a commented reminder; the Jev template is the active example/default. Use one effective value in the deployed environment, not conflicting duplicate entries.

## Setup order

1. Confirm the actual backend revision and hosting target. The audit inspected commit `1004061` read-only; this is not proof it is deployed.
2. Select Google authentication: local ADC for development, approved keyless workload identity for production where supported, or the explicitly approved user-consent OAuth flow. OAuth client ID/secret alone are insufficient.
3. Verify account/resource grants, dataset IDs, quotas and distribution/processor terms. Do not enable Google reads just because an environment variable is present.
4. Implement the configuration loader, credentials factory and provider adapters described in the plan; install and pin the required dependencies in that backend. The current `requirements.txt` does not yet provide the entire planned Google/Zarr stack.
5. Add bounded ingestion workers and a shared cache, provider selection, typed contracts and corrected deterministic advice. Heavy jobs should not be placed inside the 60-second serverless request path described in the audited config.
6. Implement and test Jev features per registry, with shared evidence and LangGraph tools; preserve deterministic fallbacks and explicit unavailable states.
7. Supply versioned response fixtures to the app implementer, then stage and validate together before enabling live traffic.

## What can be run now?

These commands start the **existing** backend; they do not implement or enable WeatherNext or the Jev expansion. Use a separate checkout of `omsenjalia/weathergpt` and run from its `backend/` directory. Install Python and your normal virtual-environment tooling first; preserve the repository's existing environment configuration.

```bash
# Working directory: omsenjalia/weathergpt/backend
python -m pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8888
```

A known offline test subset in the audited backend is:

```bash
python -m pytest tests/test_fusion.py tests/test_advisory_ai.py -q
```

The broader `tests/test_api.py` suite contains live-upstream cases; review/mock those before treating the entire suite as offline or cost-free. New provider/decision tests still need to be written. These commands were not executed as part of the documentation split.

## Security and environment placement

- Local backend values go in the backend's ignored `.env`; production values go in the host's environment/secret manager. The `.env.example` files contain placeholders, not working credentials.
- Store Google credential files outside Git or mount them as secrets; `GOOGLE_APPLICATION_CREDENTIALS` is a file path, not JSON or an application ID.
- Never copy backend `.env` into Flutter, embed it in an app asset, use `VITE_`/other public frontend variables for secrets, or paste secrets into chat.
- A deployed backend must be reachable at its HTTPS URL from mobile clients. Do not configure a phone/browser to call the server's own `localhost`.
- The remote backend has not been edited by this session. Apply the specifications in that repository; copying Markdown/templates alone does not implement the modules they describe.
