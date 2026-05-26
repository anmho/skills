# Gmail drafts: tax packet status (session pattern)

Use when user asks: "find the tax doc draft" / "whats the status on my tax document collection" and they mean **Gmail Drafts**.

## Minimal workflow

1) List drafts (grab the ID)

- `gws gmail users drafts list --params '{"userId":"me","maxResults":50}' --format json`

2) Get metadata (confirm its the one)

- `gws gmail users drafts get --params '{"userId":"me","id":"<DRAFT_ID>","format":"metadata"}' --format json`

Look for:
- `Subject: Andrew 2025 tax documents`
- `To: ...`
- `Cc: ...`
- `labelIds: ["DRAFT"]`

3) Confirm attachments

- `gws gmail users drafts get --params '{"userId":"me","id":"<DRAFT_ID>","format":"full"}' --format json`
- Parse payload parts for filenames + sizes.

## iOS link expectation management
Users often want: "send me a deeplink that opens the filled draft in the Gmail app".

What to say (one-liner):
- Theres no stable deep link to open an *existing* draft with attachments.

Workarounds:
- Provide a **new-compose** deep link with `googlegmail://co?...` (prefill only).
- Tell them to search by subject inside Gmail app and open the draft.
