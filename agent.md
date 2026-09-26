# agent.md — Agent & Assistant Guidelines for WeatherGPT Mobile

## ⚠️ Mandatory Architecture Sync Policy

Whenever any change happens in this codebase — architectural modification, API contract
update, new store/component, new data model, modified endpoint, changed dependency, or
altered workflow — **update `ARCHITECTURE.md` in the repository root synchronously.**

It must always accurately reflect the topology (Section 2), stack versions from
`package.json` (Section 3), repository layout (Section 4), endpoint surface (Sections 6
& 11), Zustand stores (Section 7), data flow and generation guards (Section 8), fusion
policy (Section 10), multilingual mappings (Section 13), developer options (Section 16),
and the SIH compliance matrix (Section 18).

Never leave `ARCHITECTURE.md` stale or out of sync with code changes.

---

## Instructions for Implementing Agents

### 1. Pushing Changes — Use the Script (REQUIRED)
The linked backend (`omsenjalia/weathergpt`) is a git submodule at `backend/`.
Always publish with:

```bash
./scripts/push-all.sh "<commit message>"
```

Do **not** use a bare `git push`: it only updates `weathergpt-app`, leaving backend
commits unpushed inside `backend/` and the submodule pointer stale.

### 2. Architecture & Code Guidelines
- **Feature-first structure**: `app/` routes (expo-router, `(tabs)` shell);
  `src/features/<domain>/` for models/stores/theme; `src/core/` + `src/ui/` for shared code.
- **Zustand state management**: granular stores, generation guards on async calls, no
  monolithic singletons.
- **Strict null semantics**: parse missing metrics to `null` via
  `src/core/models/jsonValues.ts`. Never substitute `0` for missing temperatures, rain,
  or humidity.
- **Security boundary**: only `EXPO_PUBLIC_BACKEND_URL` belongs in app env templates.
  All provider keys, LLM keys, and TypeSafe credentials remain server-side.

### 3. Verification & Testing
- Before completing any task, ensure code passes `bun run typecheck` and `bun test`.
- Verify `ARCHITECTURE.md` has been updated with any structural, API, or model changes.
