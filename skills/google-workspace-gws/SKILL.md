---
name: google-workspace-gws
description: >-
  Use when the user mentions Gmail, Google mail, email, mail, inbox, drafts,
  threads, unread messages, or Google Workspace — or asks to read, send, reply,
  forward, triage, or search mail. Hermes reaches Gmail through the local `gws`
  CLI via `terminal` (not a separate Hermes Gmail tool). Load this skill with
  skill_view before saying mail access is unavailable; verify `command -v gws`
  and `gws auth status` first. Includes Calendar/Drive via gws and Gmail draft
  workflows.
---

# google-workspace-gws

## Activation triggers (load this skill first)

Treat these as **Gmail / gws** requests — call `skill_view(name="google-workspace-gws")` (or the specific `gws-gmail-*` helper) **before** telling the user you cannot access email:

- **Keywords:** Gmail, Google mail, email, mail, inbox, unread, draft(s), message(s), thread(s), mailbox
- **Intents:** read/triage inbox, send/reply/forward, find a draft, delete drafts, check whether you can access Gmail

**Do not** confuse missing Hermes env vars with missing Gmail access. The `gws` binary may be authenticated under `~/.config/gws` even when `~/.hermes/.env` has no Google keys.

## First steps on every mail task

1. `skill_view("google-workspace-gws")` if not already loaded (or `gws-gmail-triage` / `gws-gmail-send` / `gws-gmail-read` for focused tasks).
2. `command -v gws` — if missing, say gws is not installed (do not claim "no Gmail tool").
3. `gws auth status` — confirm `token_valid` before reading/sending.
4. Run mail commands with **`terminal`** using `gws gmail ...` (see child skills under `gws-gmail*`).

## Output style (important)

- Default to **small messages**: answer in 1–2 lines, then ask one question.
- If you need commands/IDs, keep it minimal.

## Quick checks

1) Verify `gws` exists

- `command -v gws`

2) Verify auth status

- `gws auth status`
  - Key fields: `user`, `token_valid`, `has_refresh_token`

## Gmail helper skills (prefer for common tasks)

| Task | Skill |
|------|--------|
| Unread summary | `gws-gmail-triage` → `gws gmail +triage` |
| Send | `gws-gmail-send` → `gws gmail +send` |
| Read one message | `gws-gmail-read` |
| Reply / reply-all / forward | `gws-gmail-reply`, `gws-gmail-reply-all`, `gws-gmail-forward` |

Full API surface: `gws-gmail` + `gws schema gmail.<resource>.<method>`.

## Gmail: find a draft (tax doc packet)

Goal: locate the draft, show To/Cc/Subject, confirm attachment name/size.

Principle: **minimize reads**

- Start with `list` (IDs only)
- Use `get format=metadata` for only a handful of newest drafts
- Only use `get format=full` for the single best candidate to confirm attachments

1) List drafts (IDs only)

- `gws gmail users drafts list --params '{"userId":"me","maxResults":50}' --format json`

2) Inspect a candidate draft (metadata first)

- `gws gmail users drafts get --params '{"userId":"me","id":"<DRAFT_ID>","format":"metadata"}' --format json`

3) If you need attachments, fetch `format=full` for that draft only.

See `references/gws-gmail-drafts-safe-scan.md` for a safe scan/delete playbook.

## Pitfalls

- Don't say "I don't have a Gmail tool" — use **`gws` via `terminal`** after loading this skill.
- Command hierarchy: drafts live under `gws gmail users drafts ...` (not `gws gmail drafts ...`).
- Output may include non-JSON prefixes (e.g. `Using keyring backend: keyring`) — parse from the first `{`.
- `gws ... drafts delete` is **permanent** — confirm before deleting.

## References

- `references/gws-gmail-drafts-safe-scan.md`
- `references/gmail-drafts-tax-packet.md`
