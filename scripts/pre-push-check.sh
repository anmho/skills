#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "pre-push: validating skills..."
"${SCRIPT_DIR}/validate-all-skills.sh"

if [[ "${RUN_LOCAL_EVALS_ON_PUSH:-1}" != "1" ]]; then
  echo "pre-push: RUN_LOCAL_EVALS_ON_PUSH!=1, skipping LLM evals."
  exit 0
fi

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  if [[ "${REQUIRE_LOCAL_EVALS_ON_PUSH:-0}" == "1" ]]; then
    echo "pre-push: OPENAI_API_KEY is required (REQUIRE_LOCAL_EVALS_ON_PUSH=1)." >&2
    exit 1
  fi

  echo "pre-push: OPENAI_API_KEY not set, skipping LLM evals."
  echo "pre-push: set REQUIRE_LOCAL_EVALS_ON_PUSH=1 to enforce."
  exit 0
fi

echo "pre-push: running local LLM evals..."
"${SCRIPT_DIR}/run-evals.sh"

echo "pre-push: checks passed."
