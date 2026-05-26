---
name: stack-debugging
description: >-
  Debug Andrew Ho's whole app/infrastructure stack across auth, create-svc,
  generated services, Terraform, Cloudflare Workers and Access, Cloud Run,
  Grafana/Loki/Prometheus, Neon/Postgres, Vault, Temporal, Symphony worktrees,
  GitHub Actions, Atlantis, Vercel, deploy previews, BlueBubbles/iMessage
  runtime, Tailscale host reachability, and production incidents. Use for broad
  setup/stack debugging, unclear production failures, cross-repo regressions,
  live-vs-local proof questions, and root-cause investigations that span more
  than one repo or platform.
---

# Stack Debugging

Use this skill when the problem is not confined to one repo, or when the user
asks for debugging across "my setup", "the stack", auth, logs, Grafana,
Terraform, deploys, previews, generated services, BlueBubbles, or iMessage.

## Operating Rule

Build a proof ladder and label each rung:

1. user symptom,
2. live telemetry or cloud state,
3. deploy/PR/change history,
4. repo code/config,
5. local tests.

Do not claim production truth from local tests, template generation, or a dry
run. Do not claim infra/store/deploy readiness unless the actual external
system was checked.

Always include the full workspace path in repo-task updates and final messages.

## Repo Map

- Auth: `/Users/andrewho/repos/projects/auth`
- Service generator: `/Users/andrewho/repos/projects/create-svc`
- Terraform: `/Users/andrewho/repos/projects/terraform`
- Symphony: `/Users/andrewho/repos/projects/symphony`
- Agent/iMessage runtime: `/Users/andrewho/repos/projects/agent`
- Skills: `/Users/andrewho/repos/projects/skills`
- Generated services: check for `service.jsonc`
- Symphony worktrees: `.symphony/workspaces/<repo-key>/<issue-id>`

If the cwd is a Symphony worktree, inspect the routed repo and issue context
before editing. If the main checkout is dirty, avoid broad rewrites and preserve
unrelated user changes.

## Triage Sequence

1. State the exact question: broken behavior, affected service, environment,
   and time window.
2. Identify the owning surface: repo, Terraform root, cloud provider, dashboard,
   CI workflow, or published package.
3. Check the fastest authoritative signal:
   - Grafana/Loki/Prometheus for live symptoms,
   - `gh pr view`, `gh pr checks`, GitHub Actions, or Atlantis for PR/deploy
     truth,
   - cloud/provider CLI or dashboard for provisioned resources,
   - package registry checks for published CLI/library truth,
   - repo tests only for local code correctness.
4. Correlate with the most recent relevant change.
5. Make the smallest fix in the owning repo only.
6. Re-run the proof that matches the failure mode.

## Auth and Access

Use the `auth` skill for auth-repo implementation details, and this skill for
cross-stack diagnosis.

Production issuer: `https://auth.anmho.com/api/auth`.
Production internal base: `https://auth.anmho.com/internal`.

Fast checks:

```bash
cd /Users/andrewho/repos/projects/auth
authctl doctor --json
authctl clients list --json
authctl resource-servers list --json
```

Cloudflare Access 401s with `Forbidden`, `aud`, and `ray_id` are usually
pre-app Access failures. Check Access service-token resolution before changing
OAuth client/resource-server code. Never print Access service-token values.

For auth logging work, preserve `apps/auth-api/src/server-log.ts`, structured
event names, Pino-backed logging, and recursive secret redaction.

## Grafana and Logs

Use the `grafana-investigation` skill for detailed Grafana/Loki/Prometheus
work. In cross-stack triage:

- pin the time window first,
- search dashboards/alerts/incidents before inventing queries,
- discover Loki labels and Prometheus metric names before querying,
- use Cloudflare ray ids and request ids to bridge provider logs to app logs,
- keep log excerpts short and redacted.

If Grafana tools are available, discover them with `tool_search` before falling
back to browser or cloud CLI inspection.

## Terraform and Atlantis

Terraform repo: `/Users/andrewho/repos/projects/terraform`.

Local checks:

```bash
terraform fmt -check -recursive
terraform -chdir=<root> init -backend=false
terraform -chdir=<root> validate
git diff --check
```

Treat Atlantis and GitHub PR checks as authoritative for live plan/apply state.
For new Terraform roots, include lock files for both `linux_amd64` and
`darwin_arm64` when provider locks are part of the change.

## Service Generator and Generated Repos

Service generator repo: `/Users/andrewho/repos/projects/create-svc`.

Proof commands:

```bash
cd /Users/andrewho/repos/projects/create-svc
bun test src scripts
bun run typecheck
bun run validate:generated
```

Generated validation proves scaffold behavior. It does not prove that real
cloud infrastructure exists or that a preview deploy succeeded.

In generated repos, prefer the published `authctl` contract:

```bash
service doctor
authctl doctor --json
```

Use `service doctor` to catch PATH shadowing or a stale global/local `service`
binary before debugging generated code.

## BlueBubbles and iMessage

Use the `bluebubbles-cli` skill for direct CLI operations. In cross-stack triage,
separate these layers:

- CLI/config: `bluebubbles --help`, `bluebubbles config ...`
- Server reachability: `bluebubbles ping --json`, `bluebubbles server info --json`
- Local process: `bluebubbles server local status`, server logs, `pgrep -x Messages`
- Private API/enhanced iMessage: `private_api` and `helper_connected`
- Host placement: current macOS user, separate agent account, home MacBook Air,
  Tailscale reachability
- Agent processing: webhook health, replay cursors, dedupe, downstream handling

Normal BlueBubbles API health does not prove enhanced iMessage works. If
`private_api: true` and `helper_connected: false`, say the server is reachable
but the Private API helper is disconnected; repair may require machine-level SIP
or boot-arg work before `helper_connected: true` can be verified.

For agent runtime debugging:

```bash
cd /Users/andrewho/repos/projects/agent
who
pgrep -x Messages
csrutil status
tailscale status
bluebubbles server local status --json
```

Do not assume the current Mac is the intended runtime host. The target shape is
personal Messages on the main account, agent iMessage on a separate macOS user,
and remote access over Tailscale to the home MacBook Air.

## Data, Secrets, and Databases

- Vault is the secret source of truth; use narrow reads and never paste secret
  values into chat.
- Neon/Postgres connection details may be assembled from Vault provider
  credentials plus Neon API inventory when a per-app URL is not pre-baked.
- Existing known database pairs include `grafana/grafana`, auth server DB,
  and Temporal runtime/visibility DBs; verify current values before use.
- Use read-only queries first. Mutate data only when ownership and rollback are
  clear.

## CI, PRs, and Publication

- For GitHub truth, prefer `gh pr view`, `gh pr checks`, explicit workflow runs,
  and branch protection API state over broad status summaries.
- For Graphite stacks, preserve stack order and use `gt pr <number>` or direct
  PR inspection when local `gt log` lacks context.
- For npm packages, verify `npm view` and `npx --yes <pkg>@latest ...`; local
  `dist` is not publication proof.
- When an external write path fails repeatedly with the same auth/DNS/user
  rejection, preserve the proof artifact and report the exact blocker instead
  of looping.

## Final Report

Lead with:

- yes/no or root cause when known,
- full path for any repo touched,
- strongest evidence and exact commands/tool surfaces checked,
- fix made or next owner,
- what remains unproven.

Keep local proof, live telemetry, and external deployment state separate.
