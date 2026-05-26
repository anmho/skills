---
name: infrastructure-investigation
description: >-
  Unified production investigation skill for Andrew Ho's infrastructure:
  Grafana dashboards, Loki logs, Prometheus metrics, incidents/on-call context,
  Cloud Run revisions and metrics, Cloudflare edge/access signals, and service
  health across the ANM stack. Use when debugging outages, regressions, latency,
  saturation, deploy fallout, or cross-system failures where the root cause may
  span app, edge, and cloud runtime layers.
---

# Infrastructure Investigation

Use this as the default skill for production debugging across the full stack.
It consolidates telemetry + runtime state + deployment context into one flow so
you can quickly isolate where failures start.

## Activation triggers

Load this skill when the user asks to investigate:

- production incidents, outages, or degraded behavior
- "what broke" after deploy/revision changes
- elevated error rates, latency spikes, 5xx bursts, saturation
- Cloud Run regressions (revisions, traffic shifts, cold starts, crashes)
- Cloudflare Access/edge failures (ray id, pre-app denial)
- cross-service symptoms where root cause is unclear

## Investigation contract

Always separate evidence into:

1. **Telemetry evidence** (Grafana/Loki/Prometheus/alerts/incidents)
2. **Runtime evidence** (Cloud Run service/revision/traffic/health state)
3. **Edge evidence** (Cloudflare Access/edge behaviors, ray ids)
4. **Local assumptions** (repo reasoning without live proof)

Never present assumptions as production truth.

## Core workflow

1. Pin service(s), environment, symptom, and exact time window.
2. Start in Grafana:
   - relevant dashboard panels
   - Loki error/log patterns
   - Prometheus SLI/SLO indicators (availability, error rate, latency, saturation)
   - active alerts/incidents/on-call context
3. Correlate with Cloud Run runtime state:
   - current revision(s)
   - recent revision rollout/traffic split changes
   - crash/restart/resource pressure patterns
4. Correlate with Cloudflare edge/access when applicable:
   - use ray id first if present
   - determine pre-app vs app-handled failure
5. Conclude with:
   - most likely fault domain (edge, runtime, app, downstream dependency)
   - ruled-out domains
   - immediate next command/owner

## Query discipline

- Discover labels/metrics before assuming names.
- Start narrow in time and widen only if needed.
- Redact secrets/tokens/cookies/service credentials.
- Prefer structured output (`--json`) where possible.
- Keep raw log excerpts short and high signal.

## Cloud Run focus points

When Cloud Run is in scope, explicitly check:

- revision changes around incident start
- traffic split drift
- container startup failures / crash loops
- concurrency and CPU/memory saturation signals
- request latency/error behavior by revision

## Report format

Lead with:

- affected surface and timeframe
- strongest evidence
- probable root cause
- what is ruled out
- next step (command + owner)

If a tool surface is unavailable, state the gap clearly and continue using the
best available evidence (without claiming full certainty).
