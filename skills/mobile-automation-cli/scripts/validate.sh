#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test -f "${SKILL_DIR}/SKILL.md"
grep -q '^name: mobile-automation-cli$' "${SKILL_DIR}/SKILL.md"
grep -q 'bun run mobile:\*' "${SKILL_DIR}/SKILL.md"
grep -q 'apps/mobile' "${SKILL_DIR}/SKILL.md"
grep -q 'EAS_TOKEN' "${SKILL_DIR}/SKILL.md"

echo "mobile-automation-cli skill OK"
