---
name: gmail-threads
description: >-
  Find, inspect, open, or summarize Gmail messages and threads, especially when
  the user asks to open an email, send an email link, check an order/support
  thread, or look up a sender in Gmail.
---

# Gmail Threads

Use this skill for requests like:

- "Hard Jewelry check my Gmail"
- "Open the email"
- "Send me the link"
- "Find the return label email"
- "What did support say in that thread?"

## Lookup Pattern

Use Gmail tools instead of answering from memory.

```bash
gws gmail users messages list --params '{"userId":"me","q":"<gmail search>","maxResults":10}'
gws gmail users messages get --params '{"userId":"me","id":"<message_id>","format":"metadata","metadataHeaders":["From","To","Subject","Date"]}'
```

Use `gws gmail +read --id <message_id> --headers` only when the user asks what
the email says or when the snippet/metadata is not enough to identify the
right thread.

## Reading Email Body Content

**Short path (prefer this):** use `format: "metadata"` and check the `snippet`
field — it usually contains enough of the body to answer "what did it say"
without full extraction.

**Full body extraction** (when snippet is insufficient):

1. List messages: `gws gmail users messages list --params '{"userId":"me","q":"<query>","maxResults":5}'` → returns message ids.
2. Get snippet: `gws gmail users messages get --params '{"userId":"me","id":"<id>","format":"metadata"}'` → the `snippet` field shows a preview.
3. Full raw (if snippet is truncated or missing): `gws gmail users messages get --params '{"userId":"me","id":"<id>","format":"raw"}'`.

   The raw response is `base64.urlsafe_b64decode()` + decode from bytes. For
   common Outlook/Exchange emails (quoted-printable, multipart/alternative):
   - Use `quopri.decodestring()` from stdlib
   - Charset is usually `Windows-1252` or `utf-8`
   - Sender/headers include `From`, `Subject`, `Date` in the raw headers
   - The body may be split across multipart boundaries — hunt for `text/plain`
     content-type inside the right boundary

4. For threads: get the most recent message in a thread to see the latest reply.

Good Gmail search filters:

- `from:support@example.com`
- `from:(support@hardjewelry.com) OR "Hard Jewelry"`
- `subject:"Return label"`
- `order #1121666`
- `has:attachment`
- newer/older bounds when the user gives a date window

## Thread Deeplinks

The Gmail API message id and thread id are debug details. The user needs a
browser-openable Gmail link.

For normal received/sent/archive messages, return the Gmail thread deeplink
first:

```text
https://mail.google.com/mail/u/0/#all/<threadId>
```

If `threadId` is unavailable but `id` is available, use:

```text
https://mail.google.com/mail/u/0/#all/<message_id>
```

Only show raw message/thread ids if the user explicitly asks for ids or if no
Gmail deeplink can be derived.

## Response Requirements

- Lead with the Gmail thread deeplink for the best matching email.
- For link-first requests ("send me the link", "open the email", "where's the
  email"): reply in **at most 3 non-empty lines** — one informal summary line
  (fold sender/subject into the sentence), then the URL on its own line.
- **Never** emit `Subject:`, `From:`, `**Subject:**`, or `**From:**` as separate
  lines or bullet metadata. If you mention subject/sender, keep it inside the
  single summary sentence.
- Include only the minimal supporting details needed to confirm the match.
- If the user asks "send me the link" after a specific email was found, send
  the Gmail deeplink first; include external links only after it.
- Do not paste the full email body unless the user asks for the contents.
- Do not ask clarifying questions ("want the link?", "is this the right email?")
  when a clear match exists.
- Do not include a "tools I used" line, command inventory, or raw tool trace
  unless the user explicitly asks for proof/debug details.

## Example

User:

```text
Hard jewelry check my gmail
```

Good response:

```text
hard jewelry return label from support@hardjewelry.com (order #1121666)
https://mail.google.com/mail/u/0/#all/19e7abc123
```

User:

```text
Open the email
Send me the link
```

Good response:

```text
gmail thread:
https://mail.google.com/mail/u/0/#all/19e7abc123

return label:
https://www.hardjewelry.com/account/orders/.../print
```

Bad response:

```text
opened. here is the full email content:
From: Hard Jewelry...
Subject: Return label...
Instructions:
...
```
