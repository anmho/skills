#!/usr/bin/env bash
# Fail fast before live E2E if Hermes gateway or capture plumbing is unavailable.
set -euo pipefail

HERMES_DIR="${HOME}/.hermes"
ENV_FILE="${HERMES_DIR}/.env"
WEBHOOK_URL="http://localhost:8645/bluebubbles-webhook"
GATEWAY_HEALTH="http://localhost:8645/health"

read_env() {
  local key="$1"
  if [[ -n "${!key:-}" ]]; then
    printf '%s' "${!key}"
    return 0
  fi
  [[ -f "${ENV_FILE}" ]] || return 1
  local line
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -n "${line}" && "${line}" == *"="* ]] || continue
    if [[ "${line%%=*}" == "${key}" ]]; then
      local val="${line#*=}"
      val="${val%\"}"; val="${val#\"}"
      val="${val%\'}"; val="${val#\'}"
      printf '%s' "${val}"
      return 0
    fi
  done < "${ENV_FILE}"
  return 1
}

if ! curl -sf "${GATEWAY_HEALTH}" >/dev/null 2>&1; then
  echo "run-bluebubbles-e2e-preflight: Hermes gateway not reachable at ${GATEWAY_HEALTH}" >&2
  echo "  Start: cd ~/.hermes/hermes-agent && ./venv/bin/python -m hermes_cli.main gateway run" >&2
  exit 2
fi

password="$(read_env BLUEBUBBLES_PASSWORD || true)"
if [[ -z "${password}" ]]; then
  echo "run-bluebubbles-e2e-preflight: BLUEBUBBLES_PASSWORD missing (env or ${ENV_FILE})" >&2
  exit 2
fi

capture_only="${HERMES_E2E_CAPTURE_ONLY:-1}"
if [[ "${capture_only}" != "0" && "${capture_only}" != "false" && "${capture_only}" != "no" ]]; then
  if ! python3 -c "import importlib.util; import sys; sys.exit(0 if importlib.util.find_spec('gateway') else 1)" 2>/dev/null; then
    :
  fi
  if ! grep -q "e2e suppressed outbound" "${HERMES_DIR}/plugins/chat-presence/__init__.py" 2>/dev/null; then
    echo "run-bluebubbles-e2e-preflight: chat-presence plugin missing E2E capture guard" >&2
    echo "  Update ~/.hermes/plugins/chat-presence and restart the gateway." >&2
    exit 2
  fi
fi

if ! command -v bluebubbles >/dev/null 2>&1; then
  echo "run-bluebubbles-e2e-preflight: bluebubbles CLI not on PATH (needed for live-poll mode only)" >&2
fi

echo "run-bluebubbles-e2e-preflight: ok (gateway up, capture-only=${capture_only})" >&2
