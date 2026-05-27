---
name: bluebubbles-cli
description: Operate the BlueBubbles terminal CLI for iMessage workflows and server administration. Use when tasks involve sending or querying messages/chats/handles/contacts/attachments, managing iCloud or server operations, running local server lifecycle commands, validating webhooks, or diagnosing connectivity with doctor/ping/config.
---

# bluebubbles-cli

Use this skill to perform BlueBubbles work through the `bluebubbles` CLI instead of direct SDK or database access unless explicitly requested.

## Output style (iMessage)
- Default to short replies (at most 3 lines unless the user asked for detail).
  Avoid info-dumps unless the user asks.
- If you need multiple iMessage bubbles, separate paragraphs with a blank line (\n\n). Hermes BlueBubbles adapter splits outgoing messages on double newlines so each paragraph becomes its own bubble.
- When answering "can you read X yet"-type questions: respond in **one line** first (yes/no + what integration path), then offer details only if asked.
- Prefer: 1-line status + next action over long explanations.
- When answering a factual question, answer it directly. Do not end with "Want me
  to..." / "Should I..." follow-ups unless the user asked for next steps.

## Triggers

- iMessage / BlueBubbles tasks: sending messages, listing chats, attachments, contacts
- BlueBubbles server diagnostics: connectivity, config, webhook troubleshooting
- Find My requests (devices/friends) via iCloud integration

## Ambiguous "messages" requests

When the conversation is happening through BlueBubbles/iMessage, interpret the
plain word "messages" as iMessage/BlueBubbles messages by default.

Examples that should use BlueBubbles without asking whether the user meant
Gmail:

- "Can you search through my messages?"
- "Where did I go on Saturday?"
- "Search my texts for Saturday"
- "Look through the conversation"

Ask a clarification only when the user explicitly names another source or the
request cannot be answered from iMessage context alone. If clarification is
needed, ask one plain-text question, not a numbered multiple-choice menu.

## Email questions in iMessage chats

When the user asks about **email** (Gmail, inbox, confirmation email, order
email, "where's the X email", "send me the link" to an email thread), route to
Gmail immediately — even though the conversation is on iMessage.

- Use Gmail search + thread URL tools; do **not** search iMessage first.
- Do **not** ask "want me to check Gmail?" — just check Gmail.
- Reply in at most 3 lines: one-line summary mentioning the sender/subject, then
  the `mail.google.com` deeplink. Do not paste the email body.

Good shape:

```text
iconfit order confirmation from orders@iconfit.com
https://mail.google.com/mail/u/0/#all/<threadId>
```

## Date/location message searches

For questions like "Where did I go on Saturday?", do not ask the user for a
keyword first. The implied task is to infer the place from iMessage history.

Workflow:

1. Resolve the requested day in the user's local timezone.
2. Query a broad iMessage window for that day with `bluebubbles messages list`
   using `--after` and `--before`.
3. Inspect nearby messages for venue names, event names, addresses, transit,
   rideshare, restaurant/bar names, ticket links, calendar-ish text, and shared
   plans.
4. If the user later supplies a hint like "Seven Lions", search that term in
   the same date window first, then widen the window if needed.
5. Do not count the user's current hint message as evidence. Ignore messages
   created after the original question unless they are only clarifying the
   search target.

BlueBubbles CLI text filtering is not a full fuzzy-search engine. If exact
`--text` search is too brittle, pull a bounded result set with date/chat filters
and perform fuzzy matching locally over message text:

- normalize case, punctuation, smart quotes, and whitespace
- try token/subsequence matches like `seven`, `lions`, `seven lions`, artist,
  venue, and nearby plan words
- include nearby messages in the same chat as context
- exclude the user's current query/hint from evidence

Use approved CLI-shaped commands plus safe shell tools like `jq`, `rg`, `awk`,
or `sed`; do not pipe untrusted message content into an interpreter.

Good response shape:

```text
looks like saturday was Seven Lions at [venue/city], based on texts with X around 7pm.
```

If evidence is weak, say what was found and the confidence. Ask for one missing
detail only after the date-window search has been attempted.

## Core workflow (safe default)

1) Verify CLI is installed and responding
- `bluebubbles --help`
- `bluebubbles doctor`
- `bluebubbles ping`

2) Confirm credentials are configured (before API calls)
- `bluebubbles config sync` (bootstrap from local macOS server config when available)
- or:
  - `bluebubbles config set baseUrl <url>`
  - `bluebubbles config set password <password>`

3) Prefer read-only discovery before any mutation
- List/get first, confirm GUIDs/targets, then send/update.

## Command map (what to reach for)

Primary resources:
- `bluebubbles chats ...`
- `bluebubbles messages ...`
- `bluebubbles handle ...`
- `bluebubbles attachment ...`
- `bluebubbles contact ...`
- `bluebubbles icloud ...`
- `bluebubbles server ...`
- `bluebubbles ping`
- `bluebubbles doctor`

Output modes:
- Human: `-o table`
- Scriptable: `--json` / `-o json`

## CLI usage patterns (advanced / script-safe)

These were previously captured in a duplicate sibling skill; keeping them here improves discoverability.

- **Local lifecycle management only** (macOS host process control):
  - `bluebubbles server local start|stop|restart|status|logs`

- **Webhook utilities** (local tooling):
  - `bluebubbles webhook validate [file]`
  - `bluebubbles webhook serve`

- **Renderer selection** (when available)
  - `--renderer columnify|compact`

- **Safe query patterns**
  - Prefer read-only discovery first (`list/get`) and only then mutate.
  - For large inboxes/chats/messages: prefer `--limit`, `--offset`, `--sort` when available.
  - For scripts: always use JSON output and parse deterministically.

- **Endpoint mapping**
  - Command help often shows endpoint mappings like `(GET /api/v1/...)` — surface this when explaining *why* a particular command is used.

## Find My (location) reality check

BlueBubbles can query Find My data that the Apple ID signed into the **BlueBubbles macOS server** is allowed to see.

- It cannot magically “add someone’s location.”
- If the person hasn’t shared location with that Apple ID (or the device isn’t owned by that Apple ID), there will be nothing to show.

Useful commands:
- `bluebubbles icloud findmy devices list`
- `bluebubbles icloud findmy devices refresh`
- `bluebubbles icloud findmy friends list`
- `bluebubbles icloud findmy friends refresh`

See: `references/findmy-notes.md`

## Hermes iMessage nuances (when this matters)

Sometimes the user’s question is really about Hermes behavior on iMessage (not the CLI).

- Outbound message splitting: Hermes’ BlueBubbles adapter splits outgoing text on double newlines (`\n\n`) so each paragraph becomes its own iMessage bubble, then chunks anything still too long.
- Typing indicators + read receipts require BlueBubbles private API enabled + helper connected; otherwise those calls are no-ops.
- Tapbacks/reactions: inbound tapback webhook events may be filtered; outbound tapback sending may not be implemented — verify before promising.

See: `references/imessage-bubble-splitting.md`

## Notes / pitfalls

- exact-output requests: if the user says “reply exactly X” (health checks / transport probes), output ONLY that token with no extra text, no tool calls, no formatting, no context summaries. Treat it like a protocol test.
- message search surprises: `messages list --text "..."` searches message bodies, but results may be sparse (e.g., only the literal phrase). If you expect more, broaden the query (case/spacing variants) or search for adjacent keywords.
- phone redaction: message/handle outputs can include full phone numbers. When quoting tool output, redact to +1***.
- For scripts: always use JSON output and parse deterministically.

See: `references/message-text-search.md`
- Confirm chat GUIDs and handle addresses before sending.

### Time filters (`--after` / `--before`) are in milliseconds
BlueBubbles message objects return `dateCreated` like `1779599308031` (ms epoch). In practice, `messages list --after/--before` expects **milliseconds**, not seconds.

- If you pass seconds (10 digits), you may get empty results.
- Use ms (13 digits) for day windows and tight time slices.

See `references/message-query-time-windows.md` for a reusable snippet.

### If `--sort` errors, drop it
The CLI flag says `--sort <direction>`, but the server can reject some values (400 "The selected sort is invalid"). If that happens:
- re-run without `--sort`
- then narrow via `--after/--before` + `--limit`

### Hermes shell safety: don’t do inline python in `terminal`
This runtime blocks unsafe shell composition (pipes/heredocs into interpreters). For timestamp math (like “most recent Saturday”), use `execute_code` (Python) and then feed the computed numbers into `bluebubbles ...`.
