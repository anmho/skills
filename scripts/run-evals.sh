#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG="${EVAL_CONFIG:-${REPO_ROOT}/agent-skills-eval.yaml}"
EVAL_VERSION="${AGENT_SKILLS_EVAL_VERSION:-0.1.1}"
# Path to a local checkout of darkrishabh/agent-skills-eval (or our fork) with
# extra capture for `reasoning_content`. When set and built, we run that build
# instead of fetching the published npm version — lets us iterate on the harness
# locally without publishing.
EVAL_RUNNER_PATH="${EVAL_RUNNER_PATH:-${HOME}/repos/projects/agent-skills-eval}"

# Provider can be overridden per-run without editing the YAML.
# Examples:
#   EVAL_PROVIDER=deepseek ./scripts/run-evals.sh
#   EVAL_PROVIDER=openai   ./scripts/run-evals.sh
#   EVAL_TARGET=claude-3-5-sonnet-20241022 EVAL_BASE_URL=https://api.anthropic.com/v1 \
#     EVAL_API_KEY_ENV=ANTHROPIC_API_KEY ./scripts/run-evals.sh
EVAL_PROVIDER="${EVAL_PROVIDER:-}"

case "${EVAL_PROVIDER}" in
  deepseek)
    : "${EVAL_TARGET:=deepseek-v4-flash}"
    : "${EVAL_JUDGE:=${EVAL_TARGET}}"
    : "${EVAL_BASE_URL:=https://api.deepseek.com/v1}"
    : "${EVAL_API_KEY_ENV:=DEEPSEEK_API_KEY}"
    ;;
  openai)
    : "${EVAL_TARGET:=gpt-4o-mini}"
    : "${EVAL_JUDGE:=${EVAL_TARGET}}"
    : "${EVAL_BASE_URL:=https://api.openai.com/v1}"
    : "${EVAL_API_KEY_ENV:=OPENAI_API_KEY}"
    ;;
  "")
    # No provider preset — use YAML defaults unless individual env vars override.
    ;;
  *)
    echo "run-evals: unknown EVAL_PROVIDER='${EVAL_PROVIDER}' (expected: deepseek, openai, or unset)" >&2
    exit 1
    ;;
esac

# Resolve which API key env var the runner will consult, so we can fail fast
# if it isn't populated. Priority: explicit EVAL_API_KEY_ENV > apiKeyEnv in YAML.
API_KEY_ENV="${EVAL_API_KEY_ENV:-$(awk -F'[: ]+' '/^apiKeyEnv:/ {print $2; exit}' "${CONFIG}" 2>/dev/null || true)}"
API_KEY_ENV="${API_KEY_ENV:-OPENAI_API_KEY}"

if [[ -z "${!API_KEY_ENV:-}" ]]; then
  echo "run-evals: ${API_KEY_ENV} is required (set it or override with EVAL_API_KEY_ENV)" >&2
  exit 1
fi

"${SCRIPT_DIR}/sync-skills.sh"
"${SCRIPT_DIR}/validate-all-skills.sh"

# Build override flags only for env vars that are set, so YAML values stay
# authoritative otherwise.
overrides=()
[[ -n "${EVAL_TARGET:-}" ]]      && overrides+=(--target       "${EVAL_TARGET}")
[[ -n "${EVAL_JUDGE:-}" ]]       && overrides+=(--judge        "${EVAL_JUDGE}")
[[ -n "${EVAL_BASE_URL:-}" ]]    && overrides+=(--base-url     "${EVAL_BASE_URL}")
[[ -n "${EVAL_API_KEY_ENV:-}" ]] && overrides+=(--api-key-env  "${EVAL_API_KEY_ENV}")

if [[ -x "${EVAL_RUNNER_PATH}/dist/cli.js" ]]; then
  exec node "${EVAL_RUNNER_PATH}/dist/cli.js" \
    --config "${CONFIG}" \
    --log-format jsonl \
    "${overrides[@]}" \
    "$@"
elif [[ -f "${EVAL_RUNNER_PATH}/dist/cli.js" ]]; then
  exec node "${EVAL_RUNNER_PATH}/dist/cli.js" \
    --config "${CONFIG}" \
    --log-format jsonl \
    "${overrides[@]}" \
    "$@"
else
  echo "run-evals: local fork not built at ${EVAL_RUNNER_PATH}/dist/cli.js; falling back to npm" >&2
  exec npx --yes "agent-skills-eval@${EVAL_VERSION}" \
    --config "${CONFIG}" \
    --log-format jsonl \
    "${overrides[@]}" \
    "$@"
fi
