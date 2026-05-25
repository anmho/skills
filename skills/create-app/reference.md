# Create App Reference

## Terraform App Module

The app infrastructure source of truth is
`/Users/andrewho/repos/projects/terraform`.

For a new app:

- Add `projects/<app_id>/`.
- Use a single `module "app"` block with `source = "../../modules//app"`.
- The `app_id` drives standard names:
  - GCP project: `anmho-<app_id>`
  - API domain: `api.<app_id>.anmho.com`
  - Vault server paths:
    `secret/prod/apps/<app_id>/server/{database,storage,temporal,cloud-run}`
  - shared app storage folder: `<app_id>/uploads/`
  - Temporal namespaces: `<app_id>` and `<app_id>-staging`

Do not paste provider admin keys, OAuth secrets, generated server secrets, or
Vault values into docs, commits, PRs, comments, or final answers.

## Consumer Mobile Publishing Critical Path

The consumer template may have working scripts but still be blocked until real
infrastructure exists.

Critical path:

1. Choose app identity: display name, slug, bundle ID, Android package, root
   domain.
2. Apply Terraform app root via `modules/app`.
3. Run `eas init` for the real app and persist `expo.extra.eas.projectId`.
4. Create Apple Developer resources: App ID, capabilities, APNs key, App Store
   Connect API key.
5. Create App Store Connect app record and export compliance defaults.
6. Create Firebase/FCM and Google Play resources.
7. Configure domain and universal-link association files.
8. Pull Vault/env and materialize ignored credential files.
9. Build locally with EAS local and upload with Fastlane.

## Relevant Ticket Meanings

- `ANM-256`: choose real app identifiers and run `eas init`.
- `ANM-257`: Apple Developer App ID/capabilities/APNs/ASC key.
- `ANM-258`: Firebase project and FCM credential.
- `ANM-259` / `ANM-268`: domain and universal links.
- `ANM-267`: App Store Connect app record and export compliance.
- `ANM-269`: App Store privacy, metadata, screenshots, age rating.
- `ANM-270`: stale if it assumes CI-triggered EAS cloud submit by default;
  re-scope to local EAS plus Fastlane unless the user explicitly wants cloud CI.
- `ANM-297`: SaaS store credential Vault parity.
- `ANM-303`: interactive SaaS vs consumer parity review; do not blindly copy
  consumer behavior into SaaS.

## Current Policy Defaults

- Consumer has priority over SaaS unless the user says otherwise.
- Use EAS local as default artifact builder.
- Use Fastlane for TestFlight and Google Play upload/release automation.
- Keep EAS cloud build/submit as explicit fallback, not default.
- CI validates publishing config only; actual build/upload is local/operator
  gated.
- Simulator support is a dev helper, not a publishing lane.
- Store records are verified/used, not auto-created by templates.
