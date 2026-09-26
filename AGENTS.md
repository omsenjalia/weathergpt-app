# Instructions for implementing agents

## ⚠️ Architecture Documentation Policy (MANDATORY)

Whenever any change happens in this codebase — whether it is an architectural
modification, API contract update, new provider/store, new screen/component, new data
model, modified endpoint, changed dependency, or altered workflow:

**You MUST update `ARCHITECTURE.md` in the repository root synchronously.**

`ARCHITECTURE.md` is the canonical, judge-facing technical architecture annex for
WeatherGPT (SIH 2026). It must always accurately reflect the current state of:

- End-to-end system topology and Mermaid diagrams (Section 2)
- Tech stack and package versions in `package.json` (Section 3)
- Repository file footprint and directory layout (Section 4)
- API endpoint surface, parameters, and contract shapes (Sections 6 & 11)
- State management and Zustand stores (Section 7)
- Data flow, null semantics, and generation guards (Section 8)
- Ensemble fusion algorithm and provider trust weights (Section 10)
- Multilingual mappings and voice locales (Section 13)
- Developer options and Debug screen capabilities (Section 16)
- SIH problem statement compliance matrix (Section 18)

Never leave `ARCHITECTURE.md` stale or out of sync with code changes.

---

## Standing Guardrails

1. **CI gate = `bun run typecheck` + `bun test`.** A change counts as verified once the
   **CI Test** workflow is green on the PR. The **Android Compile Check** workflow
   (expo prebuild + debug APK) proves native compilation; it is slower, so never block
   progress or reporting on it unless native compilation itself is the subject of the
   change.
2. **Feature-first structure**: routes live in `app/` (expo-router, `(tabs)` shell);
   domain code lives in `src/features/<domain>/` (`models/`, stores, `theme/`); shared
   primitives live in `src/ui/` and `src/core/`.
3. **Strict null semantics**: parse missing metrics to `null` via
   `src/core/models/jsonValues.ts`. Never substitute `0` for missing temperatures, rain
   or humidity. A missing `weather_code` must stay `null` (`SkyCondition.unknown`), never
   `0` (clear sky).
4. **Security boundary**: only `EXPO_PUBLIC_BACKEND_URL` belongs in app env templates.
   All provider keys, LLM keys and TypeSafe credentials remain server-side.
5. **Generation guards** on async stores (`weatherStore`, `chatStore`, `voiceStore`,
   `actionWindowsStore`) so stale responses never overwrite newer state.

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

## Verification commands

```bash
bun install                 # dependencies
bun run typecheck           # tsc -b --noEmit (strict)
bun test                    # vitest unit tests
bunx expo start --web       # dev server (web preview)
bunx expo export --platform web   # static web build
bunx expo prebuild -p android && (cd android && ./gradlew assembleDebug)  # native Android proof
```
