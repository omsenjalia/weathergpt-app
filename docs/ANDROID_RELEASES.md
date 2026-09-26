# Android nightly releases

## Schedule and activation

`.github/workflows/nightly-release.yml` restores the old Flutter schedule:
**18:30 UTC / 00:00 Asia/Kolkata every day**. Unlike the old activity gate, this
builds every night, even with no new commits. GitHub may delay scheduled jobs.
Schedules only run from the default branch; merge the workflow there to activate.
The Actions page also exposes **Run workflow** for manual builds.

The build uses Expo prebuild → Gradle `assembleRelease`, embedding the production
JavaScript bundle. No Metro server, EAS account, or provider/LLM credentials are
needed. Release assets are `release.apk` and `release.apk.sha256` (direct downloads).
Debug artifacts from Android Compile Check are not standalone release builds.

## Required repository Actions secrets

Set these through GitHub → Settings → Secrets and variables → Actions. Reuse the
original Flutter signing key. Do not put the values in source control or chat.

| Secret | Meaning |
| --- | --- |
| `KEYSTORE_BASE64` | Base64-encoded original Android release keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Signing key alias |
| `KEY_PASSWORD` | Key password |

Missing secrets fail the job before the build. There is deliberately **no debug
signing fallback**: ephemeral/public debug certificates cannot safely provide
stable production upgrades. This session's GitHub integration could not list
repository secrets (HTTP 403), so their presence has not been verified.

Optional repository variable `EXPO_PUBLIC_BACKEND_URL` selects the public backend.
For compatibility, the former `BACKEND_URL` secret is accepted as a fallback;
otherwise the production Vercel URL is used. The URL is public in the APK. Never
use this variable for an API key or put credentials in its URL.

## Upgrade identity and versions

- Android package: `com.weathergpt.weathergpt_mobile`, matching the old Flutter app.
- The initial React Native port used `com.visionariesbvm.weathergpt`; installs of
  that temporary identity are a separate app and cannot be upgraded in place.
- Existing Flutter installs upgrade only if the signing certificate matches. Old
  debug-signed builds may need uninstall/reinstall, losing local app data.
- `APP_VERSION`: `1.0.0-nightly.YYYYMMDD`, using the IST date.
- `ANDROID_VERSION_CODE`: current Unix epoch minute. This is well above historical
  run-number versions and below Android's maximum. Serialized nightly jobs built
  in later minutes increase it. Local prebuild defaults to 1; set the environment
  variable explicitly when testing upgrades locally.
- Tags: `nightly-YYYYMMDD-RUN_ID-RUN_ATTEMPT`, targeting the exact built commit.
  Manual runs/retries never attach different APKs to yesterday's tag.
- Flutter Hive preferences are **not** migrated to AsyncStorage. Onboarding must
  be repeated; a separate native Hive import project would be needed to preserve them.

## Verification and safety

The job runs typecheck and Vitest before prebuild. A checked signing transformation
configures only the release variant, reads credentials from environment variables,
and fails if Expo's Gradle template has changed. The keystore lives in runner temp
and is removed with `if: always()`. `apksigner verify` checks the final APK before
publication. The APK/checksum are retained as Actions artifacts for 14 days too.

After merging, run one manual release and check on a physical Android device:

1. Download the direct APK, install and launch without a Metro server.
2. Upgrade over an original Flutter release signed with the same key.
3. Complete onboarding, select location, grant/deny GPS and microphone permission.
4. Test chat, voice recognition, TTS, map, and all three personas.
5. Confirm the next scheduled release has a greater version code and installs over it.

Native compilation/signing and these device checks have not been executed in the
sandbox: Java, Android SDK, a device/emulator, and release secrets are unavailable.
