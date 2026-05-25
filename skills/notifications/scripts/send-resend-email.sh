#!/usr/bin/env bash
set -euo pipefail

DEFAULT_TO="andyminhtuanho@gmail.com"
DEFAULT_FROM="Agent <agent@anmho.com>"
DEFAULT_VAULT_MOUNT="secret"
DEFAULT_VAULT_PATH="prod/providers/resend"
DEFAULT_VAULT_FIELD="api_key"

to="${NOTIFICATION_TO:-${DEFAULT_TO}}"
from="${NOTIFICATION_FROM:-${DEFAULT_FROM}}"
subject=""
text_file=""
html_file=""
dry_run=0

usage() {
  cat <<'EOF'
Usage:
  send-resend-email.sh --subject <subject> --text-file <path> [options]

Options:
  --to <email>          Recipient. Defaults to NOTIFICATION_TO or Andy.
  --from <sender>       Sender. Defaults to NOTIFICATION_FROM or Agent <agent@anmho.com>.
  --subject <subject>   Email subject. Required.
  --text-file <path>    Plain text body file. Required unless --html-file is set.
  --html-file <path>    HTML body file. Optional.
  --dry-run             Validate and print a safe payload summary without sending.
  -h, --help            Show this help.

Credentials:
  Uses RESEND_API_KEY if set. Otherwise reads Vault with:
  vault kv get -mount=secret -field=api_key prod/providers/resend
EOF
}

fail() {
  echo "send-resend-email: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to)
      [[ $# -ge 2 ]] || fail "--to requires a value"
      to="$2"
      shift 2
      ;;
    --from)
      [[ $# -ge 2 ]] || fail "--from requires a value"
      from="$2"
      shift 2
      ;;
    --subject)
      [[ $# -ge 2 ]] || fail "--subject requires a value"
      subject="$2"
      shift 2
      ;;
    --text-file)
      [[ $# -ge 2 ]] || fail "--text-file requires a value"
      text_file="$2"
      shift 2
      ;;
    --html-file)
      [[ $# -ge 2 ]] || fail "--html-file requires a value"
      html_file="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[[ -n "${subject}" ]] || fail "--subject is required"
[[ -n "${text_file}" || -n "${html_file}" ]] || fail "--text-file or --html-file is required"
[[ -z "${text_file}" || -f "${text_file}" ]] || fail "text file not found: ${text_file}"
[[ -z "${html_file}" || -f "${html_file}" ]] || fail "html file not found: ${html_file}"

command -v jq >/dev/null 2>&1 || fail "jq required"

jq_args=(--arg from "${from}" --arg to "${to}" --arg subject "${subject}")
jq_filter='{from: $from, to: [$to], subject: $subject}'

if [[ -n "${text_file}" ]]; then
  jq_args+=(--rawfile text "${text_file}")
  jq_filter="${jq_filter} + {text: \$text}"
fi

if [[ -n "${html_file}" ]]; then
  jq_args+=(--rawfile html "${html_file}")
  jq_filter="${jq_filter} + {html: \$html}"
fi

payload="$(jq -n "${jq_args[@]}" "${jq_filter}")"

if (( dry_run )); then
  jq '{from, to, subject, has_text: has("text"), has_html: has("html")}' <<<"${payload}"
  exit 0
fi

command -v curl >/dev/null 2>&1 || fail "curl required"

api_key="${RESEND_API_KEY:-}"
if [[ -z "${api_key}" ]]; then
  command -v vault >/dev/null 2>&1 || fail "vault required when RESEND_API_KEY is not set"
  vault_mount="${NOTIFICATIONS_VAULT_MOUNT:-${DEFAULT_VAULT_MOUNT}}"
  vault_path="${NOTIFICATIONS_RESEND_PATH:-${DEFAULT_VAULT_PATH}}"
  vault_field="${NOTIFICATIONS_RESEND_FIELD:-${DEFAULT_VAULT_FIELD}}"
  api_key="$(vault kv get -mount="${vault_mount}" -field="${vault_field}" "${vault_path}")"
fi

[[ -n "${api_key}" ]] || fail "empty Resend API key"

response="$(curl -sS -w $'\n%{http_code}' \
  -X POST "https://api.resend.com/emails" \
  -H "Authorization: Bearer ${api_key}" \
  -H "Content-Type: application/json" \
  -d "${payload}")"

status="${response##*$'\n'}"
body="${response%$'\n'*}"

if [[ "${status}" != 2* ]]; then
  echo "${body}" | jq -c '. // .' >&2 2>/dev/null || echo "${body}" >&2
  fail "Resend request failed with HTTP ${status}"
fi

echo "${body}" | jq -c '.'
