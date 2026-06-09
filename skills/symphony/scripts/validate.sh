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
[[ "${name}" == "symphony" ]] || fail "SKILL.md name must be symphony (got: ${name:-empty})"

for required in "repo:<key>" "needs-triage" "ready-for-agent" "symphony ticket create" "WORKFLOW.md"; do
  rg -n "${required}" "${SKILL_MD}" >/dev/null || fail "SKILL.md missing required text: ${required}"
done

rg -n -- "--state Todo" "${SKILL_MD}" >/dev/null || fail "SKILL.md missing --state Todo in Linear CLI examples"
rg -n "Backlog is not dispatchable" "${SKILL_MD}" >/dev/null || fail "SKILL.md missing Backlog dispatch guardrail"

skill_name="$(jq -r '.skill_name' "${EVALS_JSON}")"
[[ "${skill_name}" == "symphony" ]] || fail "evals.json skill_name must be symphony"

count="$(jq '.evals | length' "${EVALS_JSON}")"
(( count >= 4 )) || fail "expected at least 4 evals (got ${count})"

dupes="$(jq -r '.evals[].id' "${EVALS_JSON}" | sort | uniq -d)"
[[ -z "${dupes}" ]] || fail "duplicate eval ids: ${dupes}"

if rg -n 'hvs\.[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{12,}|re_[A-Za-z0-9_-]{12,}' "${SKILL_DIR}" >/dev/null; then
  fail "secret-looking literal found under skill directory"
fi

echo "symphony skill validation OK (${count} evals)"
