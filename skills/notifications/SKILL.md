---
name: notifications
description: >-
  Send general agent notifications and completion emails to Andy using Resend
  with Vault CLI-backed credentials. Use when asked to notify, email, send a
  completion notice, report an agent run finished, or send a status update to
  andyminhtuanho@gmail.com from agent@anmho.com.
---

# Notifications

Use this skill when the user explicitly asks you to notify, email, or send a completion/status update. The default channel is Resend email.

## Defaults

| Setting | Default |
| --- | --- |
| Recipient | `andyminhtuanho@gmail.com` |
| Sender | `Agent <agent@anmho.com>` |
| Vault path | `secret/prod/providers/resend` |
| Vault field | `api_key` |

Environment overrides:

- `NOTIFICATION_TO`
- `NOTIFICATION_FROM`
- `RESEND_API_KEY`
- `NOTIFICATIONS_RESEND_PATH`
- `NOTIFICATIONS_RESEND_FIELD`
- `NOTIFICATIONS_VAULT_MOUNT`

## Send policy

Only send a real notification when the user explicitly asks to send, email, notify, or report completion. For status updates, drafts, plans, and routine final answers, do not send email.

Never print Vault tokens, Resend API keys, or other secrets. Do not paste command output that may contain secrets. If the send fails, report the safe error summary, not credentials.

## Completion notices

Use [templates/agent-run-completion.md](templates/agent-run-completion.md) for agent-run completion emails. Keep the message concise and include:

- Outcome: completed, blocked, failed, or needs review.
- Workspace path.
- Branch and PR link when available.
- Checks run and their result.
- Blockers or risks, if any.
- Next action needed from Andy, if any.

Subject format:

```text
Agent run <outcome>: <short task/repo>
```

## Sending with Resend

Preferred helper:

```bash
skills/notifications/scripts/send-resend-email.sh \
  --subject "Agent run completed: <task>" \
  --text-file /path/to/message.txt
```

The helper reads `RESEND_API_KEY` if already exported. Otherwise it reads the API key with:

```bash
vault kv get -mount=secret -field=api_key prod/providers/resend
```

Optional flags:

```bash
--to andyminhtuanho@gmail.com
--from "Agent <agent@anmho.com>"
--html-file /path/to/message.html
--dry-run
```

Use `--dry-run` only to verify the non-secret payload shape; it does not call Resend.

## Manual fallback

If the helper cannot be used, build the Resend request with `jq` so message content is escaped correctly. Resend sends through `POST https://api.resend.com/emails` with `Authorization: Bearer <api-key>` and requires `from`, `to`, `subject`, and either `html` or `text`.

Do not write the API key into shell history. Prefer command substitution from Vault or an already exported `RESEND_API_KEY`.
