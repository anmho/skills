#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"
REPO_SLUG="${SKILLS_REPO:-anmho/skills}"

usage() {
  cat <<'EOF'
Usage:
  scripts/skills.sh list
  scripts/skills.sh install <skill-name> [repo-slug] [extra npx skills add flags...]

Examples:
  scripts/skills.sh list
  scripts/skills.sh install bluebubbles-cli
  scripts/skills.sh install bluebubbles-cli anmho/skills
  scripts/skills.sh install auth-module anmho/skills --agent codex claude-code
EOF
}

list_skills() {
  find "${SKILLS_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

install_skill() {
  local skill_name="${1:-}"
  local repo_slug="${2:-${REPO_SLUG}}"
  if (( $# >= 2 )); then
    shift 2
  else
    shift "$#"
  fi

  if [[ -z "${skill_name}" ]]; then
    echo "Missing <skill-name>."
    usage
    exit 1
  fi

  if [[ ! -f "${SKILLS_DIR}/${skill_name}/SKILL.md" ]]; then
    echo "Skill not found: ${skill_name}"
    echo
    echo "Available skills:"
    list_skills
    exit 1
  fi

  npx skills add "${repo_slug}" --skill "${skill_name}" --global -y "$@"
}

main() {
  local cmd="${1:-list}"
  case "${cmd}" in
    list)
      list_skills
      ;;
    install)
      shift || true
      install_skill "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      echo "Unknown command: ${cmd}"
      usage
      exit 1
      ;;
  esac
}

main "$@"
