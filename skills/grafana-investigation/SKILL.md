---
name: grafana-investigation
description: >-
  Investigate Andrew Ho's production telemetry in Grafana, Loki, Prometheus,
  Grafana Incident, Grafana OnCall, Sift investigations, dashboards, alerts,
  Cloudflare and GCP logs, auth-api structured logs, service errors, latency,
  saturation, deploy regressions, and time-windowed incident debugging. Use
  when the task mentions Grafana, Loki, LogQL, Prometheus, PromQL, dashboards,
  panels, alerts, incidents, logs, traces, Sift, on-call, production errors,
  or debugging live stack behavior from telemetry.
---

# Grafana Investigation

Use this skill when the user's question needs live telemetry, log correlation,
or current incident state. Treat Grafana as the investigation surface; do not
guess from repo code when logs or metrics can answer the question.

## First move

1. Pin the exact service, environment, user-facing symptom, and time window.
2. If the user gave a relative time, restate it with concrete timestamps and
   timezone before querying.
3. Search current dashboards, alert rules, incidents, and datasource names
   before writing queries from memory.
4. Preserve the difference between:
   - live production evidence from Grafana/logs,
   - cloud-provider state,
   - local repo tests,
   - assumptions from code inspection.

When Grafana tools are available, discover them with `tool_search` using terms
like `grafana logs`, `grafana prometheus`, `grafana dashboards`, `grafana
incidents`, or `grafana sift`. Prefer those tools over browser scraping.

## Query discipline

- Start broad, then narrow by labels discovered from the datasource.
- Use label-name and label-value discovery before assuming Loki labels such as
  `service`, `app`, `namespace`, `job`, or `env`.
- Query the smallest useful time range; widen only if the signal is missing.
- Use UTC in tool parameters unless the tool explicitly accepts relative time.
- Keep raw log excerpts short and redacted.
- Never print bearer tokens, cookies, Vault tokens, OAuth secrets, Cloudflare
  Access service-token values, database URLs, or provider tokens.

## Loki flow

1. List Loki datasources.
2. Explore labels for the time window.
3. Identify candidate labels for the service or runtime.
4. Run a high-signal query for errors, request ids, ray ids, deploy ids, or the
   event name.
5. If the app emits JSON logs, parse fields with LogQL after confirming the log
   shape from a sample.

Useful filters once labels are known:

```logql
{<labels>} |= "error"
{<labels>} |= "ray_id"
{<labels>} | json | level =~ "error|warn"
{<labels>} | json | event = "auth_api.request"
{<labels>} | json | event = "auth_api.internal_mutation"
```

If a Cloudflare response includes a `ray_id`, search for that ray id first. If
there are no app logs for the ray id and the response body is Cloudflare Access
JSON, the failure likely happened before the app handled the request.

## Prometheus flow

1. List Prometheus datasources.
2. Search metric metadata for the service/runtime instead of inventing names.
3. Check availability, error rate, latency, saturation, and restart/deploy
   signals.
4. Compare a bad window against a known-good window when possible.

Common query shapes after metric discovery:

```promql
up{<labels>}
sum by (<group>) (rate(<request_total_metric>{<labels>}[5m]))
sum by (<group>) (rate(<error_total_metric>{<labels>}[5m]))
histogram_quantile(0.95, sum by (le, <group>) (rate(<duration_bucket_metric>{<labels>}[5m])))
```

Do not present these as confirmed metric names until metadata proves them.

## Dashboards, Alerts, and Incidents

- Search dashboards by service, repo, product, and runtime names.
- Extract panel queries when a dashboard already encodes the correct labels.
- Check alert rules and contact points when investigating pages or missed pages.
- Search Grafana Incident before opening a new incident; update an existing
  one when the symptom matches.
- Use rendering only when the visual state matters; otherwise quote the query
  result and link the dashboard/panel.

## Auth Signals

Auth production service: `auth.anmho.com`, repo
`/Users/andrewho/repos/projects/auth`.

Structured auth-api logs use these anchors:

- `apps/auth-api/src/server-log.ts`
- `auth_api.request`
- `auth_api.internal_mutation`

For auth incidents:

```bash
cd /Users/andrewho/repos/projects/auth
authctl doctor --json
authctl clients list --json
authctl resource-servers list --json
```

Cloudflare Access 401s with `Forbidden`, `aud`, and `ray_id` are usually
pre-app Access failures. Check `authctl doctor --json` and the Vault-backed
Access service token path before debugging OAuth clients.

## Report Format

Lead with the answer:

- affected service and time window,
- strongest evidence,
- likely cause,
- what is ruled out,
- next command or owner.

Include the full workspace path when repo work is involved. If live telemetry is
unavailable, say exactly what was not checked and fall back to repo/cloud-state
inspection without calling it production proof.
