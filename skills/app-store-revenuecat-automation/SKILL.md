---
name: app-store-revenuecat-automation
description: >-
  Use when operating App Store Connect, Fastlane, asc, RevenueCat SDK-key sync,
  subscription setup, TestFlight upload, App Store metadata, or store-side
  automation for Andrew's generated mobile apps.
---

# App Store RevenueCat Automation

Use this skill for store-side app lifecycle automation that sits next to EAS:

- App Store Connect via `asc`
- Fastlane lanes for TestFlight and metadata
- RevenueCat project/app setup and SDK key materialization
- Vault-backed Apple and RevenueCat credentials

## Boundaries

- EAS builds, submits, and OTA updates belong behind `bun run mobile:*`.
- App Store Connect metadata, TestFlight, and richer store operations belong in
  Fastlane or `asc`.
- RevenueCat client apps must use platform public SDK keys, not secret API keys.
- RevenueCat secret/API keys belong in Vault-backed env and server/operator
  automation only.

## Common Commands

In generated app repos, prefer the repo scripts:

```bash
bun run asc:auth:status
bun run asc:apps:list
bun run fastlane:ios:check
bun run fastlane:ios:testflight
bun run revenuecat:sync-sdk-key
```

For dry-run SDK key materialization:

```bash
bun run revenuecat:sync-sdk-key -- --dry-run
```

## Vault Model

Keep provider/account credentials provider-scoped where one key serves many
apps, for example Apple App Store Connect team and in-app purchase keys.

Keep app-instance integration data app-scoped, for example:

```text
secret/prod/apps/<app_name>/revenuecat
```

Typical RevenueCat app fields include:

- `api_key`
- `v2_api_key`
- `project_id`
- `ios_app_id`
- `ios_public_sdk_key`
- `test_store_public_sdk_key`
- `entitlement_id`

Do not print secret values in chat, docs, logs, commits, or PR bodies.

## Verification

Before claiming production readiness, distinguish:

- CLI auth smoke: `asc` or Fastlane can authenticate.
- Config smoke: SDK keys and app IDs resolve without printing values.
- Store proof: a real artifact was uploaded to TestFlight or the store.

Run only non-mutating checks by default. Ask for explicit intent before uploads,
submissions, or dashboard mutations.
