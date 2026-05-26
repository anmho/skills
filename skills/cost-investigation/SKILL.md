---
name: cost-investigation
description: >-
  Investigate infrastructure and platform cost spikes across Andrew Ho's stack:
  Cloud Run usage/cost drivers, Cloudflare edge/bandwidth/request cost signals,
  Grafana telemetry correlations, deployment-driven spend regressions, and
  service-level cost attribution. Use when debugging higher-than-expected cloud
  bills, sudden spend changes, runaway traffic, inefficient revisions, or cost
  optimization opportunities backed by runtime evidence.
---

# Cost Investigation

Use this skill when the user asks "why did costs go up?" or wants a concrete,
evidence-backed optimization plan for infra spend.

## Activation triggers

Load this skill for:

- cloud bill increases (day-over-day or month-over-month)
- Cloud Run spend spikes, invocation bursts, memory/CPU waste
- Cloudflare transfer/request increases
- "which service is expensive right now?"
- post-deploy cost regressions

## Investigation flow

1. Pin scope first:
   - time window and baseline window
   - providers in scope (Cloud Run, Cloudflare, others)
   - target services/projects/environments
2. Identify major cost drivers:
   - request volume growth
   - latency/concurrency changes
   - revision/configuration inefficiency
   - noisy clients or retry storms
3. Correlate cost and telemetry:
   - Grafana/Loki/Prometheus for traffic/error/latency saturation
   - Cloud Run runtime indicators (revision behavior, scaling patterns)
   - edge signals (Cloudflare request/transfer shifts)
4. Attribute spend by service/revision where possible.
5. Produce ranked actions by impact and risk.

## Analysis discipline

- Use before/after windows; never infer from a single point.
- Distinguish:
  - **volume-driven** spend (more traffic)
  - **efficiency-driven** spend (same traffic, worse unit economics)
- Prefer measurable deltas:
  - requests, p95 latency, error/retry rates, CPU/memory pressure, egress.
- Avoid speculative recommendations without telemetry support.

## Optimization output format

For each recommendation include:

- expected savings direction (high/medium/low confidence)
- likely root driver
- implementation step
- validation metric
- rollback/safety consideration

## Safety

- Do not expose secrets, tokens, billing account identifiers, or private keys.
- If billing APIs or dashboards are unavailable, state limitations clearly and
  provide a best-effort telemetry-backed estimate instead of fake precision.
