---
name: auth-module
description: >-
  Work on the anmho auth repo (Better Auth API on Cloudflare Workers) and the
  authctl operator CLI for service OAuth clients and resource servers. Use when
  working in /Users/andrewho/repos/projects/auth, auth.anmho.com, auth-api,
  authctl, Cloudflare Access, Vault secret/prod/apps/auth/authctl/cloudflare-access,
  service-to-service OAuth, or Terraform-owned auth infrastructure.
---

# Auth module

## Repos

| What | Path |
|------|------|
| Auth (API + authctl) | `/Users/andrewho/repos/projects/auth` |
| Terraform (Neon, Access, Vault bootstrap) | `/Users/andrewho/repos/projects/terraform` |

Auth owns: API code, migrations, Wrangler, local dev, schemas, `authctl`.  
Terraform owns: Neon, Hyperdrive, Cloudflare Access app/service token, Vault paths, deploy OIDC.

Always cite full checkout paths in status messages.

## auth-api (server)

**Stack:** Hono app, Better Auth, Bun local runner, Cloudflare Worker in prod.

| File | Role |
|------|------|
| `apps/auth-api/src/index.ts` | Shared app, routes, local server |
| `apps/auth-api/src/worker.ts` | Worker export |
| `apps/auth-api/src/env.ts`, `auth.ts` | `AuthEnv`, Better Auth setup |
| `apps/auth-api/src/internal-routes.ts`, `oauth-clients.ts` | Access-protected `/internal/*` (authctl API) |
| `apps/auth-api/src/db/oauth-client-state.ts`, `audit-store.ts` | OAuth clients + audit log |
| `packages/schemas/src/index.ts` | Shared Zod contracts |

**Local dev:**

```bash
cd /Users/andrewho/repos/projects/auth
bun install
bun dev   # Compose Postgres, migrations, http://localhost:8787
```

Public OAuth surface: `https://auth.anmho.com/api/auth` (issuer).  
Internal control plane: `https://auth.anmho.com/internal` (Cloudflare Access only).

## authctl (CLI)

**Package:** `tools/authctl` → npm `@anmho/authctl`  
**Entry:** `tools/authctl/src/index.ts`, `client.ts`, `smoke.ts`

| Mode | Base URL | Access headers |
|------|----------|----------------|
| `--local` | `http://localhost:8787/internal` | Not required |
| Production | `https://auth.anmho.com/internal` | CF Access service token |

**Install / link:**

```bash
cd /Users/andrewho/repos/projects/auth
bun run authctl:link && hash -r
authctl --local doctor --json
```

Or: `npm install -g @anmho/authctl` · or `bun run authctl:local -- …` without linking.

**Production credentials** (Vault: `secret/prod/apps/auth/authctl/cloudflare-access`):

| Vault field | Env var |
|-------------|---------|
| `AUTH_INTERNAL_BASE_URL` | `AUTH_INTERNAL_BASE_URL` |
| `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_ID` | `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_ID` |
| `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_SECRET` | `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_SECRET` |

Resolution order: CLI flags → env → **Vault** (if `vault` + token available) → defaults.  
Opt out: `AUTHCTL_DISABLE_VAULT=1`.  
Home shell: `vault-env` in `~/.zshrc` can export the same vars (no `authctl` alias).

**Common commands:**

```bash
authctl doctor --json
authctl --local clients list --json
authctl clients list --json                    # prod
authctl resource-servers list --stage prod --json
authctl clients create --client-app agent --client-identity server \
  --resource-server billing --scope invoices:read --stage prod --yes --json
authctl --local smoke --json
```

**Troubleshooting prod 401:** See [reference.md](reference.md) — distinguish missing Access credentials vs Cloudflare rejecting the service token.

**Operator runbook in auth repo:** `docs/runbooks/authctl-operator-access.md`

## Verification

**Auth repo changes:**

```bash
cd /Users/andrewho/repos/projects/auth
bun test
bun run typecheck
bun run authctl:build
bun run cf-types
git diff --exit-code apps/auth-api/worker-configuration.d.ts
bun run dev:smoke
```

**Production (never print secrets):**

```bash
authctl doctor --json
curl -sS https://auth.anmho.com/.well-known/oauth-authorization-server/api/auth \
  | jq '{issuer, token_endpoint, jwks_uri}'
```

## Guardrails

- Product is **service-to-service OAuth** (userless `oauth_client` rows).
- `client_id` = app + identity + resource server + stage; extra fields in `oauth_client.metadata`.
- `audit_event` = operator/audit log for authctl mutations, not token protocol state.
- `user` / `session` / `account` / `verification` = Better Auth framework tables, not the M2M domain model.
- `/internal/*` is protected by Cloudflare Access; do not re-implement Access auth in app logic.
- Default issuer audience: `https://auth.anmho.com/api/auth` unless `AUTH_VALID_AUDIENCES` adds resource-server audiences.

## Deploy

Workflows: `ci.yml`, `deploy-auth-api.yml`, `publish-authctl.yml`.  
Needs: Vault OIDC `anmho-auth-deploy`, `CLOUDFLARE_ACCOUNT_ID`, Worker `BETTER_AUTH_SECRET` (verify presence only).

Terraform vault project:

```bash
cd /Users/andrewho/repos/projects/terraform
terraform -chdir=projects/vault fmt -check
terraform -chdir=projects/vault validate
terraform -chdir=projects/vault plan
```

## More detail

- authctl Access troubleshooting, `vault-env`, 401 vs missing creds: [reference.md](reference.md)
