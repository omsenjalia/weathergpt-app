# CLAUDE.md — Agent Guidelines for WeatherGPT Mobile

## ⚠️ Mandatory Architecture Sync Policy

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

## Complexity Handling
For any task spanning more than 3 files or requiring multiple decisions:
- Apply Fable Mode: stage map → delegate → verify → self-critique
- Use TodoWrite to track stage progress across tool calls
- Spawn subagents for independent work rather than serializing it
- Use Agent Teams when agents need to share partial results mid-work

---

## Codebase Architecture & Conventions

### 1. Feature-First Clean Architecture
- Code lives in `lib/features/<feature>/` divided into `models/`, `providers/`, `screens/`, and `widgets/`.
- Shared code lives in `lib/core/` (`constants/`, `errors/`, `localization/`, `models/`, `services/`, `theme/`, `utils/`, `widgets/`).
- App routing is configured via `GoRouter` in `lib/router/app_router.dart` using `ShellRoute` for the persistent bottom navigation shell.

### 2. State Management (Riverpod 2.5)
- Use granular `StateNotifier` and `AsyncNotifier` providers.
- Observe dependencies via `ref.watch()`. In background logic or event handlers, use `ref.read()`.
- Implement **generation guards** on asynchronous providers (`ActionWindowsNotifier`, `WeatherNotifier`) to prevent out-of-order race conditions when switching locations or profiles.

### 3. Strict Null Semantics (Zero Guesswork)
- Never coerce missing values to default `0` (`0 °C`, `0 mm`, `0%` are deceptive).
- Use `lib/core/models/json_values.dart` safe coercers (`jsonDouble`, `jsonInt`, `jsonString`, `jsonList`, `jsonMap`).
- A missing `weather_code` must remain `null` and map to `SkyCondition.unknown`. It must never default to `0` (which is Clear Sky).

### 4. Credential & Environment Boundary
- The Flutter app's `.env` is bundled as an asset and is **not** a secret store.
- Only non-secret client configuration (`BACKEND_URL`) belongs in `.env`.
- Upstream credentials (Google Cloud, AccuWeather, Tomorrow.io, OpenWeatherMap, Groq, TypeSafe API keys) belong **strictly on the backend**. Never embed them in mobile code.

### 5. Pushing Changes (Submodule Policy)
The backend (`omsenjalia/weathergpt`) is linked as a git submodule at `backend/`.
Always publish with:
```bash
./scripts/push-all.sh "<commit message>"
```
Never use a bare `git push`, as it leaves submodule commits unpushed and submodule pointers stale.

---

## Verification & Testing
- Static Analysis: `flutter analyze`
- Unit & Widget Tests: `flutter test`
- Release Builds: Handled automatically by GitHub Actions CI (`.github/workflows/ci-build-signed.yml`)
