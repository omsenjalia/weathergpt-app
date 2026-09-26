# CLAUDE.md — Agent Guidelines for WeatherGPT Mobile

## ⚠️ Mandatory Architecture Sync Policy

Whenever any change happens in this codebase — architectural modification, API contract
update, new store/component, new screen, new data model, modified endpoint, changed
dependency, or altered workflow:

**You MUST update `ARCHITECTURE.md` in the repository root synchronously.**

It must always accurately reflect the current state of the topology (Section 2), stack
versions from `package.json` (Section 3), repository layout (Section 4), endpoint
surface (Sections 6 & 11), Zustand stores (Section 7), data flow and generation guards
(Section 8), fusion policy (Section 10), multilingual mappings (Section 13), developer
options (Section 16), and the SIH compliance matrix (Section 18).

---

## Codebase Architecture & Conventions

The app is **React Native (Expo SDK 54) + TypeScript (strict)** — ported from Flutter in
September 2026. See [`FLUTTER_TO_REACT_NATIVE_MIGRATION.md`](FLUTTER_TO_REACT_NATIVE_MIGRATION.md).

### 1. Feature-First Structure
- Routes: `app/` (expo-router file tree, `(tabs)` group with a persona-aware shell).
- Domain code: `src/features/<feature>/` with `models/`, stores, and (where present) `theme/`.
- Shared primitives: `src/core/` (config, errors, models, services, theme, utils) and
  `src/ui/` (design tokens + components).

### 2. State Management (Zustand 5)
- One store per concern: `weatherStore`, `chatStore`, `voiceStore`, `settingsStore`,
  `developerOptionsStore`, `farmStores`, `locationStore`, `exploreStores`,
  `researchStores`, `onboardingStore`.
- Implement **generation guards** on asynchronous stores so out-of-order responses
  (switching location/profile/mode mid-flight) are discarded, never rendered.

### 3. Strict Null Semantics (Zero Guesswork)
- Never coerce missing values to default `0` (`0 °C`, `0 mm`, `0%` are deceptive).
- Use `src/core/models/jsonValues.ts` safe coercers (`jsonDouble`, `jsonInt`,
  `jsonString`, `jsonList`, `jsonMap`).
- A missing `weather_code` must remain `null` and map to `SkyCondition.unknown`. It must
  never default to `0` (which is Clear Sky).

### 4. Credential & Environment Boundary
- Only non-secret client configuration (`EXPO_PUBLIC_BACKEND_URL`) belongs in
  `.env`/`env.example` (template at the repo root).
- Upstream credentials (Google Cloud, AccuWeather, Tomorrow.io, OpenWeatherMap, Groq,
  TypeSafe API keys) belong **strictly on the backend**. Never embed them in mobile code.

### 5. Pushing Changes (Submodule Policy)
The backend (`omsenjalia/weathergpt`) is linked as a git submodule at `backend/`.
Always publish with:

```bash
./scripts/push-all.sh "<commit message>"
```

Never use a bare `git push`, as it leaves submodule commits unpushed and submodule
pointers stale.

---

## Verification & Testing

- Typecheck: `bun run typecheck` (strict `tsc --noEmit`)
- Unit tests: `bun test` (vitest)
- Web export: `bunx expo export --platform web`
- Native Android proof: `bunx expo prebuild -p android && (cd android && ./gradlew assembleDebug)`
- Release builds: handled automatically by GitHub Actions CI
  (`.github/workflows/android-compile.yml`)
