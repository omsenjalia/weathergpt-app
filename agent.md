# agent.md — Agent & Assistant Guidelines for WeatherGPT Mobile

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

## Instructions for Implementing Agents

### 1. Pushing Changes — Use the Script (REQUIRED)
The linked backend (`omsenjalia/weathergpt`) is a git submodule at `backend/`.
Always publish with:
```bash
./scripts/push-all.sh "<commit message>"
```
Do **not** use a bare `git push`: it only updates `weathergpt-app`, leaving backend commits unpushed inside `backend/` and the submodule pointer stale.

### 2. Architecture & Code Guidelines
- **Clean Feature-First Structure**: `lib/features/<domain>/` containing `models/`, `providers/`, `screens/`, `widgets/`.
- **Riverpod State Management**: Granular providers, generation guards on async calls, no monolithic singletons.
- **Strict Null Semantics**: Parse missing metrics to `null` via `lib/core/models/json_values.dart`. Never substitute `0` for missing temperatures, rain, or humidity.
- **Security Boundary**: Only `BACKEND_URL` belongs in the mobile `.env`. All provider keys, LLM keys, and TypeSafe credentials remain server-side.

### 3. Verification & Testing
- Before completing any task, ensure code passes `flutter analyze` and `flutter test`.
- Verify `ARCHITECTURE.md` has been updated with any structural, API, or model changes.
