---
name: mobile-automation-cli
description: >-
  Use when running or modifying repo-owned Expo/EAS mobile lifecycle automation
  in generated app repos, especially `bun run mobile:*` wrappers, EAS build,
  EAS submit, OTA update, development client, or mobile CI handoff commands.
---

# Mobile Automation CLI

Use this skill in generated app repos that expose `bun run mobile:*` scripts.
For Andrew's current consumer app, the main repo is:

```text
/Users/andrewho/repos/projects/create-app-consumer
```

## Core Rule

Prefer repo-owned mobile automation wrappers over raw `expo` or `eas-cli`.
The wrapper should run from `apps/mobile`, where `eas.json` and the Expo app
config live.

## Command Surface

Common commands:

```bash
bun run mobile:preflight
bun run mobile:dev
bun run mobile:dev:ios
bun run mobile:dev:android
bun run mobile:build:development
bun run mobile:build:preview
bun run mobile:build:production
bun run mobile:submit:production
bun run mobile:update:preview
bun run mobile:update:production
bun run mobile:release:production
```

Forward extra EAS or Expo args after `--`:

```bash
bun run mobile:build:preview -- --platform ios
bun run mobile:update:preview -- --message "Fix onboarding copy"
```

## Secrets And Safety

- Build, submit, and update commands require `EAS_TOKEN` or `EXPO_TOKEN`.
- App identity comes from app env/config, for example `IOS_BUNDLE_ID` and
  `ANDROID_PACKAGE_NAME`.
- Do not commit downloaded provider credentials or generated store key files.
- Uploads and submissions mutate external state. Confirm user intent before
  running production build, submit, or release commands.

## Verification

For wrapper-only changes, run the preflight path with dummy non-secret values:

```bash
EAS_TOKEN=dummy \
IOS_BUNDLE_ID=com.example.test \
ANDROID_PACKAGE_NAME=com.example.test \
bun run mobile:preflight
```

Then run the narrow repo check that covers the changed script, usually:

```bash
bun run typecheck
```

Report whether checks prove wrapper behavior only or a real store upload.
