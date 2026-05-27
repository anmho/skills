# BlueBubbles: text search in iMessage bodies

## When to use

- User asks: "search my iMessages/messages for <phrase>".
- You want a quick scan for literal substrings inside message bodies.

## Known-good command

```bash
bluebubbles messages list --limit 50 --text "Seven lions" -o json
```

## Output shape (example)

- `data[]` is a list of message objects.
- Useful fields to summarize back to the user:
  - `text`
  - `dateCreated` (ms epoch)
  - `isFromMe`
  - `handle.address` (REDACT in user-facing output)
  - `guid` (stable message identifier)
  - `replyToGuid` (if present)

Example (redacted):

```json
{
  "ok": true,
  "data": [
    {
      "guid": "63AB6D9D-3768-4E07-8FF0-7666FEB8E05E",
      "text": "Seven lions",
      "isFromMe": false,
      "handle": { "address": "+1***" },
      "dateCreated": 1779782517402
    }
  ]
}
```

## Pitfalls

- This is a literal text filter; if you want broader recall, search variations (case, spacing, artist + venue, etc.).
- Always redact phone numbers in any quoted output.
