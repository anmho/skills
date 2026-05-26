---
name: create-app
description: >-
  Work on Andrew Ho's generated app platform and source templates. Use when
  planning, generating, reviewing, or shipping create-app-consumer or
  create-app-saas apps; when wiring app infrastructure, Terraform app module
  roots, Vault/env, mobile Expo/EAS/Fastlane publishing, store review, or
  app-template parity; or when asked whether a generated app actually works
  end to end.
---

# Create App

Use this skill for the generated app platform, especially:

- `/Users/andrewho/repos/projects/terraform`
- `/Users/andrewho/repos/projects/create-app-consumer`
- `/Users/andrewho/repos/projects/create-app-saas`
- `/Users/andrewho/repos/projects/create-svc`

## Core Rule

Provision app infrastructure first. A generated app is not end-to-end usable
until the Terraform app root has been applied through `modules/app` and the app
repo can consume its outputs, Vault paths, and provider records.

Do not treat green template CI, scripts, or placeholder config as proof that a
real app can publish or run in production.

## Required Order

1. Choose canonical app identity:
   - `APP_DISPLAY_NAME`
   - `APP_SLUG`
   - `IOS_BUNDLE_ID`
   - `ANDROID_PACKAGE_ID`
   - `ROOT_DOMAIN`
   - Default convention: `IOS_BUNDLE_ID=com.anmho.<slug>`,
     `ANDROID_PACKAGE_ID=com.anmho.<slug>`, `ROOT_DOMAIN=<slug>.anmho.com`.
2. Add Terraform app root under `terraform/projects/<app_id>/` using one
   `module "app"` call.
3. Plan/apply Terraform before claiming app generation is real.
4. Verify module-created paths and outputs without printing secret values.
5. Pull/env materialize in the generated app repo with `bun run env:pull`.
6. Run template and generated-app checks.
7. Only then test provider consoles, Expo/EAS, Fastlane, TestFlight, Play, and
   store review flows.

Consumer is usually the priority unless the user says otherwise. Keep SaaS
parity capability-based, not blind file equality: SaaS may intentionally differ
by workspace/org semantics.

## Terraform Gate

Read [reference.md](reference.md) before app provisioning, Vault path, mobile
publishing, or relevant ticket work.

Use the Terraform runbook:

```text
/Users/andrewho/repos/projects/terraform/docs/runbooks/add-app-to-platform.md
```

Minimum Terraform verification:

```bash
terraform -chdir=projects/<app_id> init -backend=false
terraform -chdir=projects/<app_id> validate
terraform -chdir=projects/<app_id> init -reconfigure -backend-config=backend.gcs.hcl
terraform -chdir=projects/<app_id> plan
```

After apply, verify metadata paths, not secret values:

```bash
vault kv metadata get -mount=secret prod/apps/<app_id>
vault kv metadata get -mount=secret prod/apps/<app_id>/server/database
vault kv metadata get -mount=secret prod/apps/<app_id>/server/storage
vault kv metadata get -mount=secret prod/apps/<app_id>/server/temporal
vault kv metadata get -mount=secret prod/apps/<app_id>/server/cloud-run
```

## Template Verification

Always report the full worktree path and distinguish:

- template-level proof: tests, typecheck, CI, scripts, placeholder config
- generated-app proof: placeholders replaced, env pulled, generated app smoke
- infrastructure proof: Terraform apply/output/Vault/provider resources exist
- store proof: Apple/Google records and credentials exist, real artifact uploaded

Useful checks in each template repo:

```bash
bun test
bun run typecheck
bun run mobile:publish:doctor
```

For mobile publishing automation, do not claim end-to-end TestFlight/Play
success unless a real local build and upload were run:

```bash
bun run env:pull -- --env=prod
bun run mobile:build:ios:local
bun run mobile:testflight
bun run mobile:build:android:local
bun run mobile:play:internal
```

Uploads mutate Apple/Google state. Get explicit user intent before running
upload commands.

## Status Language

Be precise:

- "Template automation works" means scripts/config/tests are present and green.
- "Generated app works" means real identity, Terraform outputs, Vault env, and
  runtime smoke pass.
- "Publishing works" means store records and credentials exist and a real
  artifact reached TestFlight or Play internal testing.

If infrastructure has not been created, say the work is blocked by
infrastructure, not done.
