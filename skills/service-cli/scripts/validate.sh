#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_file="${skill_dir}/SKILL.md"

test -f "${skill_file}"
grep -q '^name: service-cli$' "${skill_file}"
grep -q 'service new' "${skill_file}"
grep -q 'Trigger.dev' "${skill_file}"
grep -q 'Temporal' "${skill_file}"
