#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test -f "${SKILL_DIR}/SKILL.md"
test -f "${SKILL_DIR}/reference.md"

grep -q '^name: create-app$' "${SKILL_DIR}/SKILL.md"
grep -q 'modules/app' "${SKILL_DIR}/SKILL.md"
grep -q 'Provision app infrastructure first' "${SKILL_DIR}/SKILL.md"
grep -q 'secret/prod/apps/<app_id>/server' "${SKILL_DIR}/reference.md"
grep -q 'ANM-256' "${SKILL_DIR}/reference.md"

echo "create-app skill OK"
