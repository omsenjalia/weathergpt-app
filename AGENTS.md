# Instructions for implementing agents

## ⚠️ Architecture Documentation Policy (MANDATORY)

Whenever any change happens in this codebase — whether it is an architectural modification, API contract update, new provider/notifier, new screen/widget, new data model, modified endpoint, changed dependency, or altered workflow:

**You MUST update `ARCHITECTURE.md` in the repository root synchronously.**

`ARCHITECTURE.md` is the canonical, judge-facing technical architecture annex for WeatherGPT (SIH 2026). It must always accurately reflect the current state of:
- End-to-end system topology and Mermaid diagrams (Section 2)
- Tech stack and package versions in `pubspec.yaml` (Section 3)
- Repository file footprint and directory layout (Section 4)
- API endpoint surface, parameters, and contract shapes (Sections 6 & 11)
- State management and Riverpod providers (Section 7)
- Data flow, null semantics, and generation guards (Section 8)
- Ensemble fusion algorithm and provider trust weights (Section 10)
- Multilingual mappings and voice locales (Section 13)
- Developer options and Debug screen capabilities (Section 16)
- SIH problem statement compliance matrix (Section 18)

Never leave `ARCHITECTURE.md` stale or out of sync with code changes.

---

## Pushing changes — use the script (REQUIRED)

The linked backend (`omsenjalia/weathergpt`) is a git submodule at `backend/`.
Always publish with `./scripts/push-all.sh "<message>"`. Do **not** use a bare
`git push`: it only updates `omsenjalia/weathergpt-app`, leaving backend commits
unpushed inside `backend/` and the submodule pointer stale.

- `./scripts/push-all.sh "message"` pushes both repos in order: first
  `backend/` → `omsenjalia/weathergpt`, then this repo →
  `omsenjalia/weathergpt-app` (current branch). It also commits pending
  changes when needed.
- On a fresh clone, run `git submodule update --init --recursive` before
  working (the script also initialises the submodule if it is missing).

---

## Temporary feature-plan cleanup

The user explicitly requires the temporary plans in `feature/backend/` and
`feature/app/` to be removed after their implementation is complete and verified.
This is part of the implementation's definition of done, not optional housekeeping.

- Read `feature/README.md` and the relevant folder README before implementation.
- Do not delete plans during planning, partial implementation, or while required
  tests/access checks are blocked. Record remaining work instead of claiming completion.
- Before removing a completed plan, preserve lasting API contracts, setup/deployment
  instructions, operational limitations, test/evaluation records and non-secret
  environment examples in the actual owning repository's maintained documentation.
  Update the real backend/app `.env.example` as appropriate; never copy credentials.
- Remove only the completed temporary plan/template artifacts. Do not delete source
  code, tests, real `.env` files, secret files, maintained documentation, or the
  pre-existing `backend-integration/` bundle as part of this cleanup.
- If the other component is unfinished, retain its plans and rewire any links to
  migrated documentation before removing a shared reference. Backend completion is
  not proof of app completion, or vice versa.
- Once both components are complete, remove the remaining temporary `feature/`
  handoff documentation and empty directories. Inspect the folder first; preserve
  any unrelated files added later rather than blindly deleting the entire tree.
- Update root README and other links, then verify there are no broken references.
  Replace the completed feature-specific instructions here with durable instructions
  if needed; if this file still contains only these temporary rules, remove it too.
- In the completion report, identify what was implemented, verification performed,
  which temporary files were removed and where lasting documentation now lives.

No implementation is complete merely because a feature flag or environment value
was added. Feature-specific acceptance and permission gates in the plans still apply.
