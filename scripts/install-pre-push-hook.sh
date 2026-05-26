#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_HOOK="${REPO_ROOT}/.githooks/pre-push"
TARGET_HOOK="${REPO_ROOT}/.git/hooks/pre-push"

if [[ ! -f "${SOURCE_HOOK}" ]]; then
  echo "install-pre-push-hook: missing ${SOURCE_HOOK}" >&2
  exit 1
fi

chmod +x "${SOURCE_HOOK}"
chmod +x "${REPO_ROOT}/scripts/pre-push-check.sh"

ln -sf "${SOURCE_HOOK}" "${TARGET_HOOK}"
chmod +x "${TARGET_HOOK}"

echo "Installed pre-push hook at ${TARGET_HOOK}"
echo "Use SKIP_LOCAL_EVALS=1 git push to bypass when needed."
