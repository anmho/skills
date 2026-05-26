---
name: auth
description: >-
  Work on Andrew Ho's auth repo, Better Auth API server, authctl CLI,
  service OAuth clients, resource servers, auth-client packages, Cloudflare
  Access, Vault-backed auth secrets, and Cloudflare Worker deploys. Use when
  working in /Users/andrewho/repos/projects/auth, auth.anmho.com, auth-api,
  authctl, @anmho/authctl, @anmho/auth-client, Better Auth M2M flows,
  Cloudflare Access 401s, or auth Terraform boundaries.
---

# Auth

## Repo Boundary

- Auth repo: `/Users/andrewho/repos/projects/auth`.
- Terraform repo: `/Users/andrewho/repos/projects/terraform`.
- Auth owns API code, migrations, Wrangler config, GitHub workflows, schemas, packages, examples, and `tools/authctl`.
- Terraform owns Neon, Hyperdrive, Cloudflare Access app/service token, Vault bootstrap, deploy OIDC, and persistent infrastructure.
- Always include the full checkout path in status and final messages.
- Keep PRs atomic; avoid mixing Terraform infra edits with auth repo app/CLI edits unless the user explicitly asks for a cross-repo rollout.

## Server Map

- Production issuer: `https://auth.anmho.com/api/auth`.
- Production internal control plane: `https://auth.anmho.com/internal`.
- Worker entry: `apps/auth-api/src/worker.ts`.
- Shared app/routes: `apps/auth-api/src/index.ts`.
- Better Auth setup: `apps/auth-api/src/auth.ts`.
- Internal authctl API: `apps/auth-api/src/internal-routes.ts`, `apps/auth-api/src/oauth-clients.ts`, and `apps/auth-api/src/resource-servers.ts`.
- Token resource policy: `apps/auth-api/src/token-resource-policy.ts`.
- Shared contracts: `packages/schemas/src/index.ts`.

`/api/auth/*` is the public Better Auth/OAuth protocol surface. `/internal/*` is operator-only and protected by Cloudflare Access; do not re-implement Access auth in app logic.

## authctl

Package: `tools/authctl`, npm `@anmho/authctl`.

Useful commands:

```bash
cd /Users/andrewho/repos/projects/auth
bun run authctl:build
bun run authctl:local -- doctor --json
bun run authctl:local -- clients list --json
bun run authctl:local -- resource-servers list --json
authctl doctor --json
authctl clients list --json
authctl resource-servers list --json
authctl smoke --json
```

Production `authctl` uses Cloudflare Access service-token headers:

- `CF-Access-Client-Id`
- `CF-Access-Client-Secret`

Vault source of truth:

```text
secret/prod/apps/auth/authctl/cloudflare-access
```

Fields:

- `AUTH_INTERNAL_BASE_URL`
- `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_ID`
- `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_SECRET`

Resolution order: CLI flags -> env vars -> Vault read, unless `AUTHCTL_DISABLE_VAULT=1` -> defaults. `--local` uses `http://localhost:8787/internal` and skips Access.

## Client Packages

- TypeScript helper: `packages/auth-client`, npm `@anmho/auth-client`.
- Go helper: `go/authclient`.
- Runnable examples: `examples/node-vault-refresher` and `examples/go-vault-refresher`.
- Package-local docs: `tools/authctl/README.md`, `packages/auth-client/README.md`, `go/authclient/README.md`, and `examples/README.md`.

For similar auth helper work, default to an in-process background refresher with `getToken()` and a real Vault SDK client. Do not invent a sidecar or YAML sync unless the user explicitly asks.

## Local Dev

```bash
cd /Users/andrewho/repos/projects/auth
bun install --frozen-lockfile
bun run dev
```

`bun run dev` starts Docker Compose Postgres, runs local migrations, and serves the auth API locally. Use `bun run dev:down` to clean up the local stack.

## Cloudflare Access Failures

If production `authctl clients list` returns raw Cloudflare `401` JSON with `Forbidden`, `aud`, and `ray_id`, the request is failing at Cloudflare Access before auth-api sees it. The common cause is missing, stale, or mismatched Access service-token credentials, not an OAuth client or resource-server bug.

Run:

```bash
authctl doctor --json
```

Expected production state: `ok: true`, `has_access_client_id: true`, `has_access_client_secret: true`, and `base_url: https://auth.anmho.com/internal`.

If `authctl` says `Cloudflare Access service-token credentials are missing`, Vault/env lookup failed. Run `vault login` or `vault-env`, unset `AUTHCTL_DISABLE_VAULT`, then retry. If credentials are present but Cloudflare still returns 401, compare Vault values with the Terraform-managed Cloudflare Access service token and rotate/update Vault if needed.

Never print service-token secrets, OAuth client secrets, Vault tokens, or provider tokens in chat or logs.

## Logging and Production Debugging

For auth-api logs and live incident work, use the `grafana-investigation` skill
when Grafana/Loki/Prometheus tools are available, and keep repo checks separate
from production proof.

Structured logging boundary:

- `apps/auth-api/src/server-log.ts`
- request event: `auth_api.request`
- control-plane mutation event: `auth_api.internal_mutation`

Auth-api logging must use a real logger API. Pino is the known-good Worker
logger for this repo; do not reintroduce `console.log(JSON.stringify(...))` as
the primary structured logging path.

Preserve recursive redaction for fields matching credentials, tokens, cookies,
secrets, passwords, private keys, and API keys. When investigating production
logs, quote only the minimum needed fields and redact identifiers if they could
be credentials.

## Verification

For auth repo changes:

```bash
cd /Users/andrewho/repos/projects/auth
bun install --frozen-lockfile
bun test
bun run typecheck
bun run authctl:build
bun run cf-types
git diff --exit-code apps/auth-api/worker-configuration.d.ts
git diff --check
```

For local end-to-end behavior:

```bash
bun run dev:smoke
bun run examples:smoke
```

For authctl production behavior:

```bash
authctl doctor --json
authctl clients list --json
authctl resource-servers list --json
```

`authctl smoke --json` mutates the configured server; for production, use unique temporary `--client-app`, `--resource-server`, and `--stage` values.

For package truth after publishing:

```bash
npm view @anmho/authctl version
npx --yes @anmho/authctl@latest version
npm view @anmho/auth-client version
```

Do not claim registry parity from the local checkout alone; verify `npm latest` or the live workflow state.

## Guardrails

- Keep v1 CLI-first and programmatic; do not add YAML sync unless explicitly requested.
- `client_id` should remain deterministic from app, identity, resource server, and stage.
- Resource servers are API/resource inventory; OAuth clients must target an active resource server for the requested stage.
- Use `auth-api`, not stale `auth-worker` naming.
- Keep the root README as a routing hub; put package usage detail in package-local READMEs.
- For planning-only requests, save/review the artifact only and stop unless the user reopens implementation.
