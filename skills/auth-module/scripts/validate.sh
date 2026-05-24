#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_MD="${SKILL_DIR}/SKILL.md"
EVALS_JSON="${SKILL_DIR}/evals/evals.json"
REFERENCE_MD="${SKILL_DIR}/reference.md"

fail() {
  echo "validate: $*" >&2
  exit 1
}

[[ -f "${SKILL_MD}" ]] || fail "missing SKILL.md"
[[ -f "${REFERENCE_MD}" ]] || fail "missing reference.md"
[[ -f "${EVALS_JSON}" ]] || fail "missing evals/evals.json"

command -v jq >/dev/null 2>&1 || fail "jq required"

name="$(awk '/^name: / { print $2; exit }' "${SKILL_MD}")"
[[ "${name}" == "auth-module" ]] || fail "SKILL.md name must be auth-module (got: ${name:-empty})"

skill_name="$(jq -r '.skill_name' "${EVALS_JSON}")"
[[ "${skill_name}" == "auth-module" ]] || fail "evals.json skill_name must be auth-module"

count="$(jq '.evals | length' "${EVALS_JSON}")"
(( count >= 3 )) || fail "expected at least 3 evals (got ${count})"

for id in $(jq -r '.evals[].id' "${EVALS_JSON}"); do
  [[ -n "${id}" ]] || fail "eval id must be non-empty"
done

dupes="$(jq -r '.evals[].id' "${EVALS_JSON}" | sort | uniq -d)"
[[ -z "${dupes}" ]] || fail "duplicate eval ids: ${dupes}"

echo "auth-module skill validation OK (${count} evals)"
