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
[[ "${name}" == "reminders" ]] || fail "SKILL.md name must be reminders (got: ${name:-empty})"

for required in "Google Tasks" "gws tasks" "due" "status" "completed" "recurrence" "notifications" "durable memory" "When should I remind you?"; do
  rg -n "${required}" "${SKILL_MD}" >/dev/null || fail "SKILL.md missing required text: ${required}"
done

skill_name="$(jq -r '.skill_name' "${EVALS_JSON}")"
[[ "${skill_name}" == "reminders" ]] || fail "evals.json skill_name must be reminders"

count="$(jq '.evals | length' "${EVALS_JSON}")"
(( count >= 8 )) || fail "expected at least 8 evals (got ${count})"

for id in create-dated-reminder create-undated-task list-todays-reminders update-reminder-due-date complete-reminder recurrence-limitation missing-date-clarification memory-vs-reminder-routing; do
  jq -e --arg id "${id}" '.evals[] | select(.id == $id)' "${EVALS_JSON}" >/dev/null || fail "missing eval id: ${id}"
done

dupes="$(jq -r '.evals[].id' "${EVALS_JSON}" | sort | uniq -d)"
[[ -z "${dupes}" ]] || fail "duplicate eval ids: ${dupes}"

if rg -n 'hvs\.[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{12,}|re_[A-Za-z0-9_-]{12,}' "${SKILL_DIR}" >/dev/null; then
  fail "secret-looking literal found under skill directory"
fi

echo "reminders skill validation OK (${count} evals)"
