#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG="${REPO_ROOT}/agent-skills-eval.yaml"
EVAL_VERSION="${AGENT_SKILLS_EVAL_VERSION:-0.1.1}"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "run-evals: OPENAI_API_KEY is required" >&2
  exit 1
fi

"${SCRIPT_DIR}/validate-all-skills.sh"

exec npx --yes "agent-skills-eval@${EVAL_VERSION}" \
  --config "${CONFIG}" \
  --log-format jsonl \
  "$@"
