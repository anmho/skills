---
name: auth-module
description: Work on Andrew Ho's auth module, including the Better Auth API server, authctl CLI, local development, deploy verification, and Terraform-owned auth infrastructure. Use when working in /Users/andrewho/repos/projects/auth, discussing auth.anmho.com, auth-api, authctl, service OAuth clients, Better Auth, Cloudflare Workers deployment, Cloudflare Access protection, or Vault-backed auth secrets.
---

# Auth Module

## Ownership

- Auth repo: `/Users/andrewho/repos/projects/auth`
- Terraform repo: `/Users/andrewho/repos/projects/terraform`
- Auth owns API code, migrations, Wrangler config, local dev, tests, schemas, and `authctl`.
- Terraform owns Neon, Hyperdrive, Cloudflare Access app/service token, Vault bootstrap paths, and GitHub Actions Vault OIDC deploy role.
- Always include the full checkout path in status and final messages.

## Map

- `apps/auth-api/src/index.ts`: shared Hono app, routes, Bun local runner.
- `apps/auth-api/src/worker.ts`: Cloudflare Worker adapter export.
- `apps/auth-api/src/env.ts`, `auth.ts`: `AuthEnv`, local env parsing, Better Auth construction.
- `apps/auth-api/src/internal-routes.ts`, `oauth-clients.ts`: Access-protected authctl API and service OAuth client control plane.
- `apps/auth-api/src/db/oauth-client-state.ts`, `audit-store.ts`: OAuth client store and audit event adapters.
- `packages/schemas/src/index.ts`: shared Zod contracts and naming helpers.
- `tools/authctl/src/index.ts`, `client.ts`, `smoke.ts`: CLI, API client, smoke proof.

Call it `auth-api`, `auth server`, or `auth API`; use "worker" only for the Cloudflare deployment adapter.

## Local Dev

```bash
cd /Users/andrewho/repos/projects/auth
bun install
bun dev
```

`bun dev` should be idempotent: it starts Compose Postgres, runs migrations, and serves `http://localhost:8787`. If the port is occupied, inspect the running process before changing scripts.

```bash
cd /Users/andrewho/repos/projects/auth
bun run authctl:link
hash -r
which authctl
authctl --local doctor --json
authctl --local smoke --json
```

No-link mode and teardown:

```bash
bun run authctl:local -- doctor --json
bun run authctl:local -- clients list --json
bun run dev:down
```

## Verification

For auth repo changes:

```bash
cd /Users/andrewho/repos/projects/auth
bun test
bun run typecheck
bun run authctl:build
bun run cf-types
git diff --exit-code apps/auth-api/worker-configuration.d.ts
git diff --check
bun run dev:smoke
```

For production checks, never print secret values:

```bash
npm view @anmho/authctl version bin dist.integrity --json
curl -sS https://auth.anmho.com/.well-known/oauth-authorization-server/api/auth | jq '{issuer, token_endpoint, jwks_uri}'
authctl doctor --json
authctl smoke --json
```

If `authctl doctor` reports missing Access credentials, expected Vault path is `secret/prod/apps/auth/authctl/cloudflare-access`; fields are `AUTH_INTERNAL_BASE_URL`, `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_ID`, and `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_SECRET`.

## Guardrails

- Product purpose is service-to-service OAuth.
- `authctl` creates userless Better Auth `oauth_client` rows. `client_id` comes from client app, identity, resource server, and stage.
- Canonical app/resource fields live in `oauth_client.metadata` because Better Auth has no dedicated columns for them.
- `audit_event` is the operator log for authctl mutations, not token protocol state.
- Better Auth `user`, `session`, `account`, and `verification` tables are framework surface, not the M2M domain model.
- Cloudflare Access protects `/internal/*`; use Access headers for audit identity, but do not duplicate Access authentication in business logic.
- Use `https://auth.anmho.com/api/auth` as issuer audience unless a resource-server audience is deliberately added through `AUTH_VALID_AUDIENCES`.

## Deploy

Auth workflows: `ci.yml`, `deploy-auth-api.yml`, `publish-authctl.yml`, and any integration/smoke workflow. Deploy depends on Vault GitHub OIDC role `anmho-auth-deploy`, repo variable `CLOUDFLARE_ACCOUNT_ID`, and Worker secret `BETTER_AUTH_SECRET`; verify presence and status without revealing values.

For Terraform changes:

```bash
cd /Users/andrewho/repos/projects/terraform
terraform -chdir=projects/vault fmt -check
terraform -chdir=projects/vault validate
terraform -chdir=projects/vault plan
```
