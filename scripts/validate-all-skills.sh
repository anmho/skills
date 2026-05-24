#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"

found=0
for validate in "${SKILLS_DIR}"/*/scripts/validate.sh; do
  [[ -f "${validate}" ]] || continue
  found=1
  echo "==> $(dirname "$(dirname "${validate}")" | xargs basename)"
  "${validate}"
done

if (( found == 0 )); then
  echo "No skills with scripts/validate.sh found under ${SKILLS_DIR}"
  exit 1
fi
