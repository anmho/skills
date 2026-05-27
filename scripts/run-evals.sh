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
#     (loads DEEPSEEK_API_KEY from Vault when unset — same path as `deepseek-api-key` alias)
#   EVAL_PROVIDER=openai   ./scripts/run-evals.sh
#   EVAL_TARGET=claude-3-5-sonnet-20241022 EVAL_BASE_URL=https://api.anthropic.com/v1 \
#     EVAL_API_KEY_ENV=ANTHROPIC_API_KEY ./scripts/run-evals.sh
EVAL_PROVIDER="${EVAL_PROVIDER:-}"
# Set EVAL_BASELINE=0 to grade with_skill only (faster; avoids without_skill flakes).
EVAL_BASELINE="${EVAL_BASELINE:-}"

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

load_eval_api_key_from_vault() {
  local env_name="$1"
  if [[ -n "${!env_name:-}" ]]; then
    return 0
  fi
  if ! command -v vault >/dev/null 2>&1; then
    return 1
  fi
  case "${env_name}" in
    DEEPSEEK_API_KEY)
      local key
      key="$(vault kv get -mount=secret -field=deepseek.api_key prod/providers/deepseek 2>/dev/null)" || return 1
      export DEEPSEEK_API_KEY="${key}"
      ;;
    *)
      return 1
      ;;
  esac
}

load_eval_api_key_from_vault "${API_KEY_ENV}" || true

if [[ -z "${!API_KEY_ENV:-}" ]]; then
  echo "run-evals: ${API_KEY_ENV} is required." >&2
  echo "  export ${API_KEY_ENV}=\"\$(deepseek-api-key)\"   # zsh alias → Vault" >&2
  echo "  or: vault login && EVAL_PROVIDER=deepseek ./scripts/run-evals.sh" >&2
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

cli_args=(--config "${CONFIG}" --log-format jsonl "${overrides[@]}" "$@")
if [[ "${EVAL_BASELINE}" == "0" ]]; then
  cli_args=(--config "${CONFIG}" --log-format jsonl "${overrides[@]}" "$@")
  # agent-skills-eval reads baseline from YAML; override via ephemeral config.
  tmp_config="$(mktemp)"
  trap 'rm -f "${tmp_config}"' EXIT
  awk 'BEGIN{b=0} /^baseline:/{print "baseline: false"; b=1; next} {print} END{if(!b) print "baseline: false"}' "${CONFIG}" > "${tmp_config}"
  cli_args=(--config "${tmp_config}" --log-format jsonl "${overrides[@]}" "$@")
fi

if [[ -x "${EVAL_RUNNER_PATH}/dist/cli.js" ]]; then
  exec node "${EVAL_RUNNER_PATH}/dist/cli.js" "${cli_args[@]}"
elif [[ -f "${EVAL_RUNNER_PATH}/dist/cli.js" ]]; then
  exec node "${EVAL_RUNNER_PATH}/dist/cli.js" "${cli_args[@]}"
else
  echo "run-evals: local fork not built at ${EVAL_RUNNER_PATH}/dist/cli.js; falling back to npm" >&2
  exec npx --yes "agent-skills-eval@${EVAL_VERSION}" "${cli_args[@]}"
fi
