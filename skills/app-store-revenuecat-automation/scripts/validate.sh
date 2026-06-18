#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test -f "${SKILL_DIR}/SKILL.md"
grep -q '^name: app-store-revenuecat-automation$' "${SKILL_DIR}/SKILL.md"
grep -q 'RevenueCat' "${SKILL_DIR}/SKILL.md"
grep -q 'Fastlane' "${SKILL_DIR}/SKILL.md"
grep -q 'asc' "${SKILL_DIR}/SKILL.md"
grep -q 'secret/prod/apps/<app_name>/revenuecat' "${SKILL_DIR}/SKILL.md"

echo "app-store-revenuecat-automation skill OK"
