---
name: bluebubbles-cli
description: >-
  Operate and debug the BlueBubbles terminal CLI for iMessage workflows,
  server administration, Private API/enhanced iMessage diagnostics, webhook
  validation, local server lifecycle, Tailscale/home Mac reachability, and
  agent runtime messaging. Use when tasks involve sending or querying
  messages/chats/handles/contacts/attachments, managing iCloud or server
  operations, running local server lifecycle commands, validating webhooks, or
  diagnosing connectivity with doctor/ping/config/server info/logs.
---

# bluebubbles-cli

Use this skill to perform BlueBubbles work through the `bluebubbles` CLI instead of direct SDK or database access unless explicitly requested.

## Instructions

1. Verify CLI availability before action.
Run `bluebubbles --help` and then the relevant `<resource> --help` command.

2. Prefer API-backed resource commands for runtime behavior.
Use these primary resources:
- `bluebubbles chat ...`
- `bluebubbles message ...`
- `bluebubbles handle ...`
- `bluebubbles attachment ...`
- `bluebubbles contact ...`
- `bluebubbles icloud ...`
- `bluebubbles server ...`
- `bluebubbles ping`
- `bluebubbles doctor`

3. Use local-process operations only for local lifecycle management.
Use `bluebubbles server local start|stop|restart|status|logs` for host process control.

4. Set or bootstrap credentials before API calls.
Use one of:
- `bluebubbles config set baseUrl <url>`
- `bluebubbles config set password <password>`
- `bluebubbles config sync` for local bootstrap from BlueBubbles server config on macOS.

5. Use output modes intentionally.
- Human-readable: `-o table` (default)
- Automation: `-o json` or `--json`
- Renderer selection: `--renderer columnify|compact`

6. Apply safe, scriptable command patterns.
- Query/list commands should prefer `--limit`, `--offset`, and `--sort` when available.
- For scripts, always use `--json` and parse deterministically.
- For interactive troubleshooting, use table output first, then rerun with JSON if needed.

7. Keep endpoint mapping visible in responses when useful.
Each command help includes endpoint mapping like `(GET /api/v1/...)`; surface it when explaining why a command is used.

8. Prefer minimal, reversible operations first.
- Start with read/list/get commands before update/delete actions.
- Confirm target GUIDs and addresses before mutating operations (send/edit/unsend/update/delete).

9. Webhook tooling is local utility work.
Use:
- `bluebubbles webhook validate [file]`
- `bluebubbles webhook serve`

10. Use this quick command selection map.
- Messaging: `chat`, `message`, `message schedule`
- Participants/identity: `handle`, `contact`, `icloud`
- Server/admin: `server info|logs|alert|update|restart|settings|theme|local`
- Diagnostics/config: `doctor`, `ping`, `config`

## Runtime Diagnostics

Start by separating the layers:

- CLI installed/configured: `bluebubbles --help`, `bluebubbles config ...`
- Server reachable: `bluebubbles ping`, `bluebubbles server info --json`
- Local host process: `bluebubbles server local status`, `bluebubbles server local logs`
- Normal API health: chat/message/handle read commands work
- Private API health: server info reports enhanced-feature state such as
  `private_api` and `helper_connected`
- Agent runtime health: webhook endpoint, replay cursors, and downstream agent
  processing work

Normal server/API success does not prove enhanced iMessage works. If
`private_api: true` but `helper_connected: false`, report that the server is up
but the Private API helper is not connected.

## Safe Read-Only Checks

Prefer these before mutating messages or server settings:

```bash
bluebubbles doctor --json
bluebubbles ping --json
bluebubbles server info --json
bluebubbles server local status --json
bluebubbles server local logs --limit 100
```

When direct API probing is needed outside the CLI, low-risk endpoints are
`/api/v1/ping` and `/api/v1/server/info?guid=<urlencoded-password>`. Do not
print the password or full URL containing it.

On macOS, the local server config may live at:

```text
~/Library/Application Support/bluebubbles-server/config.db
```

Read it only when the CLI config is insufficient, and do not paste stored
passwords or tokens.

## Agent Runtime Context

Agent repo: `/Users/andrewho/repos/projects/agent`.

Known runtime expectations:

- `agent start` should open Messages before starting or relying on BlueBubbles.
- The daemon wrapper `~/.agent/bin/agent-daemon.sh` should preserve that startup
  behavior.
- Process-level Messages checks should use `pgrep -x Messages`; visible window
  focus is not required.
- The replay model uses Redis-backed per-chat cursors and dedupe markers.
  Advance replay cursors only after successful handling.
- Webhook timestamps must be preserved so replay can anchor correctly.

For local agent verification, prefer deterministic iMessage evals and focused
tests in the agent repo over ad hoc sends.

## Private API and Host Placement

The intended deployment shape is: personal Messages stays in the main macOS
account, agent iMessage runs under a separate macOS user on the home MacBook Air,
and remote access comes over Tailscale.

Do not assume the current Mac is the intended host. Check runtime reality first:

```bash
who
ps aux | rg -i 'BlueBubbles|Messages|agent'
csrutil status
tailscale status
bluebubbles config get
```

If enhanced iMessage is the problem and `helper_connected` is false, likely
repair work is outside the CLI: Recovery-mode SIP changes and possible Apple
Silicon/macOS boot args, then re-check `helper_connected: true` and update stale
LAN/Tailscale host config. Do not claim this repair was done unless those
machine-level steps actually ran.

## Reporting

Lead with the layer that is broken:

- CLI/config,
- server reachability,
- Private API helper,
- Messages process/account placement,
- Tailscale/host routing,
- webhook/replay/agent processing.

Include the full repo path when touching `/Users/andrewho/repos/projects/agent`.
For sends or destructive operations, confirm target chat/handle GUIDs before
executing.
