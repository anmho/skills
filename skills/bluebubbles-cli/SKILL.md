---
name: bluebubbles-cli
description: Operate the BlueBubbles terminal CLI for iMessage workflows and server administration. Use when tasks involve sending or querying messages/chats/handles/contacts/attachments, managing iCloud or server operations, running local server lifecycle commands, validating webhooks, or diagnosing connectivity with doctor/ping/config.
---

# bluebubbles-cli

Use this skill to perform BlueBubbles work through the `bluebubbles` CLI instead of direct SDK or database access unless explicitly requested.

## Output style (iMessage)

- Default to **short replies** (at most 3 lines unless the user asked for detail). Avoid info-dumps.
- **Answer first**, then at most **one short follow-up** when it genuinely helps (disambiguation or a concrete next step you would execute if they say yes). Do not stack multiple “anything else?” prompts.
- Do **not** lead with tool preambles (“I'll search your messages…”, “Let me check Gmail…”).
- If you need multiple iMessage bubbles, separate paragraphs with a blank line (`\n\n`). Hermes' BlueBubbles adapter splits outgoing messages on double newlines so each paragraph becomes its own bubble, then chunks anything still too long.
- For “can you read X yet” questions: one line first (yes/no + integration path), details only if asked.

## Ambiguous messages

In a BlueBubbles/iMessage chat, **“messages”** means iMessage history unless the user explicitly names email/Gmail/inbox.

- “Search my messages” / “where did I go Saturday?” → `bluebubbles messages list` with a date window (see below).
- Do **not** ask “iMessage or Gmail?” when the channel is already iMessage.

Ask a clarification only when the user explicitly names another source or the request cannot be answered from iMessage context alone. If needed, ask **one** plain-text question — not a numbered menu.

## Email questions in iMessage chats

When the user asks about **email** (Gmail, inbox, confirmation email, order email, “where's the X email”, “send me the link” to a thread), route to **Gmail immediately** — even though the conversation is on iMessage.

- Use Gmail search + thread URL tools (`gmail-threads` skill); do **not** search iMessage first.
- Do **not** ask “want me to check Gmail?” — just check Gmail.
- Reply in at most 3 lines: one-line summary (sender/subject folded in), then the `mail.google.com` deeplink. Do not paste the email body.

Good shape:

```text
iconfit order confirmation from orders@iconfit.com
https://mail.google.com/mail/u/0/#all/<threadId>
```

## Date/location message searches

For “where did I go on Saturday?” / “what did we do last weekend?”:

1. Resolve **which calendar day** the user means from “today” in their timezone (most recent Saturday if today is Wednesday, etc.).
2. Query iMessage with a **time window**, not a vague keyword-only search:
   - CLI: `bluebubbles messages list --after <start_ms> --before <end_ms> --limit 120 --json`
   - API filters use **milliseconds** since epoch, not seconds (see `references/message-query-time-windows.md`).
3. Summarize venues/events/places from message text; redact phone numbers in quotes.
4. Optional one-line follow-up if “Saturday” could mean upcoming vs past and the window was ambiguous.

Do **not** route these to Gmail unless the user asked about email.

## Find My (location) reality check

BlueBubbles can query Find My data that the Apple ID signed into the **BlueBubbles macOS server** is allowed to see.

- It cannot magically “add someone's location” or share location without that Apple ID already having access.
- “Do you have my location?” → list friends/devices the server can see; answer yes/no plainly in one or two lines.

Useful commands:

- `bluebubbles icloud findmy devices list`
- `bluebubbles icloud findmy devices refresh`
- `bluebubbles icloud findmy friends list`
- `bluebubbles icloud findmy friends refresh`

See: `references/findmy-notes.md`

## Sending iMessage

Use `bluebubbles_send_message` / `bluebubbles message send` **only** when the user explicitly asks to text someone.

- Answering a question (“did Alex confirm?”) does **not** imply sending a message.
- Do not text third parties on your own initiative.

## Hermes iMessage nuances

Sometimes the user's question is about Hermes behavior on iMessage (not the CLI).

- **Bubble splitting:** Hermes' BlueBubbles adapter splits outgoing text on `\n\n` (each paragraph → its own bubble), then chunks long text.
- Typing indicators + read receipts need private API + helper connected; otherwise no-ops.
- Tapbacks: inbound tapback webhooks may be filtered; outbound tapback sending may be unimplemented — verify before promising.

See: `references/imessage-bubble-splitting.md`

## Triggers

- iMessage / BlueBubbles: send, list chats, search messages, attachments, contacts
- Server diagnostics: connectivity, config, webhook troubleshooting
- Find My (devices/friends) via iCloud integration

## Core workflow (safe default)

1. Verify CLI: `bluebubbles --help`, `bluebubbles doctor`, `bluebubbles ping`
2. Credentials: `bluebubbles config sync` or `config set baseUrl` / `password`
3. Read/list before mutate; confirm GUIDs before send/update

## Command map

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

Output modes: human `-o table`; scripts `--json` / `-o json`.

## Notes / pitfalls

- For scripts: always use JSON output and parse deterministically.
- Confirm chat GUIDs and handle addresses before sending.
- Literal text search: `bluebubbles messages list --text "..."` (see `references/message-text-search.md`).
