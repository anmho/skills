#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_MD="${SKILL_DIR}/SKILL.md"
EVALS_JSON="${SKILL_DIR}/evals/evals.json"

fail() {
  echo "validate: $*" >&2
  exit 1
}

[[ -f "${SKILL_MD}" ]] || fail "missing SKILL.md"
[[ -f "${EVALS_JSON}" ]] || fail "missing evals/evals.json"

command -v jq >/dev/null 2>&1 || fail "jq required"

name="$(awk '/^name: / { print $2; exit }' "${SKILL_MD}")"
[[ "${name}" == "grafana-investigation" ]] || fail "SKILL.md name must be grafana-investigation (got: ${name:-empty})"

for required in "Grafana" "Loki" "Prometheus" "auth_api.request" "ray_id" "tool_search"; do
  grep -q "${required}" "${SKILL_MD}" || fail "SKILL.md missing required text: ${required}"
done

skill_name="$(jq -r '.skill_name' "${EVALS_JSON}")"
[[ "${skill_name}" == "grafana-investigation" ]] || fail "evals.json skill_name must be grafana-investigation"

count="$(jq '.evals | length' "${EVALS_JSON}")"
(( count >= 3 )) || fail "expected at least 3 evals (got ${count})"

dupes="$(jq -r '.evals[].id' "${EVALS_JSON}" | sort | uniq -d)"
[[ -z "${dupes}" ]] || fail "duplicate eval ids: ${dupes}"

if grep -R -E 'hvs\.[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{12,}|re_[A-Za-z0-9_-]{12,}' "${SKILL_DIR}" >/dev/null; then
  fail "secret-looking literal found under skill directory"
fi

echo "grafana-investigation skill validation OK (${count} evals)"
