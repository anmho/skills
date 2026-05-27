#!/usr/bin/env bash
# Mock skill evals (agent-skills-eval) + live Hermes BlueBubbles E2E (capture-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

run_mock=1
run_e2e=1
mock_args=()
e2e_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mock-only)
      run_e2e=0
      shift
      ;;
    --e2e-only)
      run_mock=0
      shift
      ;;
    --)
      shift
      mock_args+=("$@")
      break
      ;;
    *)
      mock_args+=("$1")
      shift
      ;;
  esac
done

status=0

if [[ "${run_mock}" -eq 1 ]]; then
  echo "==> Mock skill evals (agent-skills-eval)" >&2
  if ! "${SCRIPT_DIR}/run-evals.sh" "${mock_args[@]}"; then
    status=1
  fi
fi

if [[ "${run_e2e}" -eq 1 ]]; then
  echo "" >&2
  echo "==> Live Hermes BlueBubbles E2E (capture-only by default)" >&2
  if ! "${SCRIPT_DIR}/run-bluebubbles-e2e-preflight.sh"; then
    status=1
  elif ! "${SCRIPT_DIR}/run-bluebubbles-e2e.py"; then
    status=1
  fi
fi

exit "${status}"
