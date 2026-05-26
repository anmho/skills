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
[[ "${name}" == "hermes" ]] || fail "SKILL.md name must be hermes (got: ${name:-empty})"

for required in "web search" "browser access" "cite sources" "Search Only" "Browser Only" "Search Then Browser" "authenticated sessions" "Do not request"; do
  rg -n "${required}" "${SKILL_MD}" >/dev/null || fail "SKILL.md missing required text: ${required}"
done

skill_name="$(jq -r '.skill_name' "${EVALS_JSON}")"
[[ "${skill_name}" == "hermes" ]] || fail "evals.json skill_name must be hermes"

count="$(jq '.evals | length' "${EVALS_JSON}")"
(( count >= 8 )) || fail "expected at least 8 evals (got ${count})"

dupes="$(jq -r '.evals[].id' "${EVALS_JSON}" | sort | uniq -d)"
[[ -z "${dupes}" ]] || fail "duplicate eval ids: ${dupes}"

for required in \
  "Search the web for current info on" \
  "Open this page and inspect it" \
  "Use the browser to compare these two menus" \
  "Find events this weekend" \
  "What is photosynthesis?" \
  "Log into my bank"; do
  rg -n "${required}" "${EVALS_JSON}" >/dev/null || fail "evals.json missing required prompt coverage: ${required}"
done

for required_id in \
  "search-current-info-with-citations" \
  "browser-open-page-inspect" \
  "search-then-browser-events-weekend" \
  "negative-stable-general-knowledge" \
  "negative-credential-request" \
  "negative-unsafe-browser-automation"; do
  jq -e --arg id "${required_id}" '.evals[] | select(.id == $id)' "${EVALS_JSON}" >/dev/null \
    || fail "evals.json missing required eval id: ${required_id}"
done

if rg -n 'hvs\.[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{12,}|re_[A-Za-z0-9_-]{12,}' "${SKILL_DIR}" >/dev/null; then
  fail "secret-looking literal found under skill directory"
fi

echo "hermes skill validation OK (${count} evals)"
