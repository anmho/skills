# BlueBubbles message query: time windows (ms epoch)

## What bit us
BlueBubbles message objects show `dateCreated` like `1779599308031` (milliseconds since epoch).

When filtering messages with:
- `bluebubbles messages list --after ... --before ...`

…the API expects **milliseconds**, not seconds.

## Quick recipe: get a day window
1) Get 00:00 local timestamps in Python via Hermes `execute_code` (NOT inline shell python):

```python
import datetime
now = datetime.datetime.now()
# walk back to most recent Saturday (weekday: Mon=0 .. Sat=5)
d = now
while d.weekday() != 5:
    d -= datetime.timedelta(days=1)
start = datetime.datetime(d.year, d.month, d.day)
end = start + datetime.timedelta(days=1)
print(int(start.timestamp() * 1000))
print(int(end.timestamp() * 1000))
```

2) Use those numbers:

```bash
bluebubbles messages list --after <start_ms> --before <end_ms> --limit 120 --json
```

## Tight slice (when the day window is huge)
Pick a narrower window (e.g. 20 minutes) by adjusting `start/end` and rerun with a smaller `--limit`.

## Sort gotcha
If `--sort` triggers a 400 validation error ("selected sort is invalid"), omit `--sort` and rely on time windows + limit.
