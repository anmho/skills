# gws gmail drafts: safe scan + delete (privacy-minimizing)

This is a playbook for: 
- finding the “mostly filled out” draft among recent duplicates
- avoiding reading too many drafts
- deleting empty/garbage drafts **safely** (permanent delete)

## Why this exists
Users may get (reasonably) annoyed if the agent:
- scans too many drafts
- fetches full bodies unnecessarily
- loops on parsing errors

This playbook keeps reads small and predictable.

## Key facts
- Drafts API path is: `gws gmail users drafts ...`
- `list` returns IDs only
- `get format=metadata` is usually enough for triage
- `get format=full` only when you must confirm attachments
- `delete` is **permanent** (not trash)

## Minimal scan algorithm (last 1–2 days)
1) List a small window (newest first)
- `gws gmail users drafts list --params '{"userId":"me","maxResults":25}' --format json`

2) For each ID in order, fetch metadata only
- `gws gmail users drafts get --params '{"userId":"me","id":"<ID>","format":"metadata"}' --format json`

3) Stop early using `internalDate`
- Compare `message.internalDate` to your cutoff (now - 48h)
- Once it’s older than cutoff, stop scanning

4) Pick “mostly filled out” heuristics (metadata)
- Subject exists
- To exists
- snippet length is non-trivial

5) Only then confirm attachments (full)
- `gws gmail users drafts get --params '{"userId":"me","id":"<ID>","format":"full"}' --format json`
- Look for payload parts where `filename` is non-empty and `body.attachmentId` exists

## Empty/garbage draft identification (be conservative)
Treat a draft as “empty-ish” only if:
- no Subject
- no To
- snippet is empty/very short
- (optional) no attachments

If any of those are present, do NOT delete automatically.

## Deletion workflow (must confirm)
1) Prepare a list of exact IDs to delete
2) For each ID, show user a tiny summary
- subject (or “(no subject)”)
- to (or “(no to)”)
- snippet first ~80 chars
3) Ask for explicit confirmation: “delete these X draft IDs?”
4) Delete
- `gws gmail users drafts delete --params '{"userId":"me","id":"<ID>"}'`

## Parsing quirk: non-JSON prefixes
Some commands print a line like:
- `Using keyring backend: keyring`

When parsing output programmatically:
- strip everything before the first `{`
- also be tolerant of control characters

## Messaging preference reminder (phone)
When user asks “what are you doing”, reply in 2–4 lines:
- what you’re filtering by (time window)
- what you’re fetching (metadata only)
- what you’ll fetch next (full for 1 draft)
