# React Native migration audit — 2026-09-26

Scope: `app/`, `src/`, package/Expo/Metro configuration, tests, GitHub workflows,
and the pre-migration nightly workflow/Android identity in Git history. Backend
contracts/submodule code were not changed. This is a source and build-pipeline
audit, not a claim that every possible device or backend issue has been eliminated.

## Confirmed issues fixed

| Area | Finding and remediation |
| --- | --- |
| Native dependencies | Missing direct `expo-font` and `react-native-worklets` dependencies could break standalone apps despite pure tests passing. Added SDK-54-compatible versions; system UI support now enables configured dark mode. Vitest moved to dev dependencies; Node/Bun toolchain requirements pinned/documented. |
| GPS | Browser-only `navigator.geolocation` could never locate a native Android user. Uses `expo-location`, foreground permission checks, bounded GPS wait, deny/error fallback. Saved manual choices suppress automatic prompts; stale GPS/reverse-geocode results cannot overwrite newer selection. |
| Speech | Unbound global recognition module, wrong event shape, no permissions. Installed SDK-54-compatible `expo-speech-recognition` plus config plugin; subscribe to native result/error/end events, request permission, wait for final result, remove listeners on cancel. |
| Voice UI/TTS | Mic requests were invisible on the chat screen. Now displays listening/processing/transcript/error/result, stop and dismiss controls. TTS tracks completion via callbacks instead of awaiting a void function. Cancel/context changes invalidate pending answers. Removed the silent retry that replaced the user’s question with a different weather question. |
| Chat context | Selected location, language, persona and farm never reached chat; voice only received part of settings. Root synchronizes both stores. Changing context clears prior conversation and invalidates requests. Retry no longer duplicates the failed user message. |
| Farm coordinates | A typed farm location only changed its label, while requests still used default coordinates. Saving resolves the place and selects its coordinates; unresolved/invalid profiles do not silently save. Avoids per-keystroke reverse overwrites. |
| Unsaved farms | Skipping farm setup no longer sends assumed crop/stage/soil/irrigation details in chat/voice, and Farm does not fetch personalized windows until setup is complete. |
| Weather races | `clear()` did not bump generation; old requests could repopulate it or start fallback work. Fixed. New requests clear misleading prior-location snapshots. Explicit `status: unavailable` is respected regardless of source/error wording. |
| Advisory honesty | Missing tomorrow data was copied from today; missing best-window text said “Good Conditions.” Removed both inventions. Empty weekly data is unavailable. Mode is included in cache context and changes invalidate pending work. |
| Map | Native screen was placeholder prose. Added a real native WebView (web retains iframe), loading/error handling, HTTPS-only mixed content policy. Selected model is now included in embed URL. |
| Navigation/layout | Added an explicit tab-index redirect to Home. Everyone no longer receives the Researcher-only Lab tab. Added safe-area insets around the routed app. Removed dead root bridge code. |
| Settings | Zustand object-spread flattened computed persona getters to stale values. Persona fields now update explicitly. Language changes select matching TTS locale; home temperatures honour Fahrenheit without changing backend Celsius values. |
| Localization | Locale files existed but no app screen called the translator. Added reactive `useTranslation` and connected existing matching UI strings across onboarding/home/chat/explore/farm/lab/profile; onboarding previews selected language. Some new/dynamic labels still lack translations (see limitations). |
| HTTP | Expo public env references used optional chaining, preventing the required static access pattern. Fixed; timeout now includes response body reading. HTML/array/null/empty success responses reject instead of silently becoming empty weather data. |
| Presentation | Atmosphere uses selected-location offset for the current clock (and offset-bearing solar timestamps). Ordinary chat paragraphs now render inline markdown. Links open only HTTP(S), with rejected opens caught. |
| Persistence robustness | Non-array saved-location storage no longer throws during boot. |
| Android identity | Restored original Flutter `com.weathergpt.weathergpt_mobile` application ID. Removed missing favicon reference. Ignored generated native projects/signing outputs. |
| CI/release | Restored daily midnight-IST signed standalone APK release, mandatory stable signing, unique exact-commit tags, version codes, signature verification/checksum. CI now also exports production bundles. Corrected docs that advertised debug APKs as standalone release downloads. |

## Validation evidence

- Baseline: strict typecheck + 91 tests passed, demonstrating gaps in original coverage.
- After fixes: strict typecheck + 124 Vitest tests passed (33 additional tests).
- Production Metro exports: Android Hermes bundle, iOS Hermes bundle, web bundle.
- Expo native Android prebuild passed; Android manifest/native project generated.
- `expo install --check` in offline mode: dependencies up to date with SDK 54.
- Release signing transformation exercised against the actual generated Gradle file,
  plus fixtures testing invalid version codes and fail-closed signing configuration.
- Regression tests cover context changes, late responses, cancel/clear, retries,
  GPS/manual selection race, recognition final event, TTS completion, advisory gaps,
  farm coordinate resolution, omitted unsaved farm details, units/settings, malformed
  HTTP responses and stalled response-body timeout.

## Remaining limitations / release gates

1. **Native verification**: no Java/Android SDK or device exists in this sandbox.
   Expo prebuild and Hermes exports are not APK compilation proof. Run Android
   Compile Check and one manually dispatched Nightly Release, then the device
   checklist in `ANDROID_RELEASES.md`. No release was published from this session.
2. **Signing configuration**: repository-secret metadata could not be read by this
   integration (HTTP 403). Confirm the four signing secrets in GitHub settings.
3. **External tooling**: Expo Doctor's config-schema/directory requests failed due
   to network/TLS access; local compatibility checks passed. Actionlint binary
   download was also blocked. Do not interpret those network failures as validation.
4. **Localization parity**: existing translations are now wired into matching
   screens, but not every new label, dynamic weather description, validation message
   or developer diagnostic has a translated counterpart. Human-reviewed translation
   coverage remains necessary; a keyset test alone never proves translated UI.
5. **Flutter persistence**: Hive data is not imported. Documented re-onboarding is
   required, even when Android's package/signature upgrade succeeds.
6. **Feature parity still pending**: six-question farm voice onboarding is still a
   typed form; sky videos and notification delivery are not implemented in the port.
   Per-language named TTS voice picks are persisted but the active UI uses locale/rate.
   These should not be advertised as fully shipped React Native features.
7. **Live-service/device QA**: recognition requires a native build and an installed
   speech service; permission, service availability, WebView/Windy behaviour, keyboard,
   accessibility, and backend error/contract behaviour need real-device testing.

No backend secret was added to the client. No GitHub release or production deploy
was triggered. Changes are on the session branch pending review/merge.
