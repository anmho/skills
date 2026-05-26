#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_MD="${SKILL_DIR}/SKILL.md"
TEMPLATE_MD="${SKILL_DIR}/templates/agent-run-completion.md"
SEND_SCRIPT="${SKILL_DIR}/scripts/send-resend-email.sh"
EVALS_JSON="${SKILL_DIR}/evals/evals.json"

fail() {
  echo "validate: $*" >&2
  exit 1
}

[[ -f "${SKILL_MD}" ]] || fail "missing SKILL.md"
[[ -f "${TEMPLATE_MD}" ]] || fail "missing templates/agent-run-completion.md"
[[ -f "${SEND_SCRIPT}" ]] || fail "missing scripts/send-resend-email.sh"
[[ -f "${EVALS_JSON}" ]] || fail "missing evals/evals.json"
[[ -x "${SEND_SCRIPT}" ]] || fail "scripts/send-resend-email.sh must be executable"

command -v jq >/dev/null 2>&1 || fail "jq required"

name="$(awk '/^name: / { print $2; exit }' "${SKILL_MD}")"
[[ "${name}" == "notifications" ]] || fail "SKILL.md name must be notifications (got: ${name:-empty})"

for required in "Resend" "Vault" "andyminhtuanho@gmail.com" "agent@anmho.com" "prod/providers/resend" "api_key"; do
  grep -q "${required}" "${SKILL_MD}" || fail "SKILL.md missing required text: ${required}"
done

for placeholder in "{{status}}" "{{workspace_path}}" "{{branch}}" "{{pr_url}}" "{{checks_summary}}" "{{blockers_or_risks}}" "{{next_action}}"; do
  grep -q "${placeholder}" "${TEMPLATE_MD}" || fail "template missing placeholder: ${placeholder}"
done

skill_name="$(jq -r '.skill_name' "${EVALS_JSON}")"
[[ "${skill_name}" == "notifications" ]] || fail "evals.json skill_name must be notifications"

count="$(jq '.evals | length' "${EVALS_JSON}")"
(( count >= 3 )) || fail "expected at least 3 evals (got ${count})"

dupes="$(jq -r '.evals[].id' "${EVALS_JSON}" | sort | uniq -d)"
[[ -z "${dupes}" ]] || fail "duplicate eval ids: ${dupes}"

if grep -R -E 're_[A-Za-z0-9_-]{12,}|hvs\.[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{12,}' "${SKILL_DIR}" >/dev/null; then
  fail "secret-looking literal found under skill directory"
fi

"${SEND_SCRIPT}" --dry-run --subject "Validation" --text-file "${TEMPLATE_MD}" >/dev/null

echo "notifications skill validation OK (${count} evals)"
