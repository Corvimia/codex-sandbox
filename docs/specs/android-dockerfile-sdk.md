# Android SDK in Dockerfile Spec

## Context
We need the `android` container image to include the Android SDK because Android Studio is not available in the container. Builds should work without mounting a host SDK.

## Goals
- Install Android SDK Platform 36 and Build-Tools 36.x in the `android` image.
- Keep the image deterministic and reproducible across rebuilds.
- Ensure Gradle finds the SDK automatically inside the container.

## Non-goals
- Installing Android Studio in the container.
- Running the Android emulator in the container.
- Setting up CI pipelines or publishing artifacts.

## Constraints
- Image size should be reasonable (avoid downloading unused components).
- SDK license acceptance must be automated for non-interactive builds.
- Docker builds should cache well across runs.

## Proposed Dockerfile Changes
- Install Android SDK command line tools in the `android` image.
- Set `ANDROID_SDK_ROOT` and `ANDROID_HOME` (e.g., `/opt/android-sdk`).
- Use `sdkmanager` to install:
  - `platforms;android-36`
  - `build-tools;36.0.0` (latest 36.x at time of writing; update intentionally)
  - `platform-tools`
- Accept SDK licenses during image build.
- Add `platform-tools` and `cmdline-tools/latest/bin` to `PATH`.
- Add a Gradle cache mount for faster builds (e.g., mount to `/home/sandbox/.gradle`).
- On ARM64, replace `aapt2` (and related build-tools binaries) with ARM64-compatible versions.

## Implementation Notes
- Download the command line tools zip from the official source and verify checksum (no vendoring).
- Unzip to `/opt/android-sdk/cmdline-tools/latest`.
- Run `yes | sdkmanager --licenses` during build.
- Consider adding `--no_https` only if build environment blocks SSL.
- Use `ARG ANDROID_SDK_VERSION` / `ARG ANDROID_BUILD_TOOLS_VERSION` to allow overrides.
- Use a vetted ARM64 build-tools bundle to supply `aapt2` on ARM64 hosts.

## Verification
- `sdkmanager --list` shows Platform 36 and Build-Tools 36.x installed.
- `adb version` works in the container.
- `./gradlew :app:assembleDebug` succeeds in a container session.

## Decisions
- Pin Build-Tools to `36.0.0` and update intentionally when a newer 36.x is released.
- Add a Gradle cache mount for faster builds.
- Do not add a separate target for updating SDK components outside the image rebuild.
