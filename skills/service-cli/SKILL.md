---
name: service-cli
description: >-
  Work on Andrew Ho's `service` microservice CLI and generated service repos.
  Use when the task mentions create-svc, `service new`, `service create`,
  generated Cloud Run or Cloudflare Workers services, authctl provisioning,
  Trigger.dev Workers tasks, Temporal Cloud Run workers, generated workflows,
  or end-to-end scaffold/deploy validation.
---

# Service CLI

Use this skill for `/Users/andrewho/repos/projects/create-svc` and generated
repos produced by the `service` CLI.

## Core model

- The npm package is `create-svc`; the installed binary is `service`.
- Outside a generated repo, `service new <service_id>` is the preferred scaffold
  command. `service create <service_id>` remains an alias.
- Inside a generated repo, `service create` provisions dependencies and performs
  the first deploy; `service deploy` deploys later changes.
- Generated repos are identified by `service.jsonc`. If no `service.jsonc` is
  found, repo-local commands such as `service destroy` must not scaffold.

## Repository

```bash
cd /Users/andrewho/repos/projects/create-svc
```

Use Bun for repo work:

```bash
bun install
bun test src scripts
bun run typecheck
bun run validate:generated
git diff --check
```

For a narrower generated check:

```bash
bun run validate:generated --variant workers-bun-hono
bun run validate:generated --variant go-connectrpc
```

`validate:generated` is the main truth surface. It scaffolds real generated
variants, installs dependencies, runs migrations/tests/lint, and smoke-checks
local APIs where applicable.

## Target behavior

Cloud Run targets:

- Bun Hono, Bun ConnectRPC, Go Chi, and Go ConnectRPC variants.
- Use Temporal for async work.
- API service starts workflows; a separate Cloud Run worker service polls.
- Worker service names are deterministic:
  - `<service>-worker`
  - `<service>-pr-<slug>-worker`
  - `<service>-dev-<slug>-worker`
- Do not force `minScale: 1` by default.

Cloudflare Workers target:

- Bun Hono only.
- Uses Trigger.dev for async/background work.
- The Cloudflare Worker is the API; do not add a separate worker process,
  worker service, or worker DNS.
- Generated package installs `@trigger.dev/sdk` and the `trigger.dev` package.
  The binary is `trigger`, not `trigger.dev`.
- Generated scripts should use:
  - `bun run trigger -- <args>`
  - `bun run trigger:dev`
  - `bun run trigger:deploy`
- Workers `service create` / `service deploy` should preflight
  `TRIGGER_PROJECT_REF`, `TRIGGER_ACCESS_TOKEN`, and `TRIGGER_SECRET_KEY`
  before cloud/auth/database side effects.

## Auth

Generated services use the auth repo's published `@anmho/authctl`.

- `authctl resource-servers upsert` provisions resource servers.
- `authctl clients create` provisions OAuth client credentials.
- Current generated services should use `@anmho/authctl >= 0.1.1`.
- Verify the command surface with:

```bash
bun run authctl resource-servers upsert --help
```

Do not local-link `/Users/andrewho/repos/projects/auth` for acceptance unless
the user explicitly asks. Fresh generated services should work from published
packages.

## Git and GitHub

- Standalone scaffolds default to a private GitHub repo at
  `github.com/anmho/<service_id>`.
- If the target is inside an existing git worktree, skip git init, repo create,
  remote setup, and push.
- `--no-git` means no git or GitHub side effects.
- `service destroy` must not auto-delete GitHub repos unless the generated
  service marked them CLI-owned. For non-owned repos, print:
  `gh repo delete anmho/<service> --yes`.

## Common checks

Before claiming a change works:

```bash
bun test src scripts
bun run typecheck
bun run validate:generated
git diff --check
```

When touching only Workers templates, also prove the generated Trigger CLI:

```bash
rm -rf /tmp/create-svc-trigger-cli-check
bun run index.ts new trigger-cli-check --target workers --yes \
  --no-auto-deploy --no-git --dir /tmp/create-svc-trigger-cli-check
cd /tmp/create-svc-trigger-cli-check
bun install
bun run trigger -- --version
service create
```

If Trigger.dev credentials are absent, the final `service create` should fail
before side effects with a clear missing-env message.

## Cleanup expectations

After live or generated checks, clean up temp work:

```bash
docker ps -a --format '{{.Names}}' | rg 'create_svc_|svc-temp|temporal-e2e|trigger-cli-check' || true
docker volume ls --format '{{.Name}}' | rg '^(create_svc_|svc-temp|temporal-e2e)' || true
docker network ls --format '{{.Name}}' | rg '^(create_svc_|svc-temp|temporal-e2e)' || true
find /tmp -maxdepth 1 -type d \( -name 'create-svc-*' -o -name 'svc-temp*' \) -print 2>/dev/null || true
find bin/generated -maxdepth 1 -type d -name 'run-*' -print 2>/dev/null || true
```

Remove only resources you created. Do not delete user repos or cloud resources
unless ownership is clear and the command is explicitly destructive.

## Reporting

Always include the full worktree path, branch/PR, checks run, and any live
blockers such as missing Trigger.dev credentials, billing quotas, or auth
failures. Distinguish generated validation from real cloud deployment.
