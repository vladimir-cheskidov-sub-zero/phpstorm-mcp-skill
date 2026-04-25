#!/usr/bin/env bash
set -euo pipefail

skill_name="phpstorm-mcp-workflows"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
source_dir="${repo_root}/${skill_name}"
codex_home="${CODEX_HOME:-${HOME}/.codex}"
dest_root="${codex_home}/skills"
dest_dir="${dest_root}/${skill_name}"
dry_run=0

usage() {
  cat <<'EOF'
Usage: codex/install-codex-phpstorm-mcp-workflows.sh [--dry-run] [--dest DIR]

Installs or updates the phpstorm-mcp-workflows skill for Codex from this
repository into $CODEX_HOME/skills (defaults to ~/.codex/skills).

Options:
  --dry-run   Print the planned actions without changing anything.
  --dest DIR  Override the destination skills directory.
  --help      Show this help message.
EOF
}

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

run() {
  if [[ "${dry_run}" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi

  "$@"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --dest)
      [[ $# -ge 2 ]] || fail "Missing value for --dest"
      dest_root="$2"
      dest_dir="${dest_root}/${skill_name}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

[[ -d "${source_dir}" ]] || fail "Skill source directory not found: ${source_dir}"
[[ -f "${source_dir}/SKILL.md" ]] || fail "Missing SKILL.md in ${source_dir}"

staging_root="${dest_root}/.${skill_name}.tmp"
staging_dir="${staging_root}/${skill_name}"
backup_dir="${dest_root}/.${skill_name}.backup"

if [[ -e "${dest_dir}" ]]; then
  action="Updating"
else
  action="Installing"
fi

log "${action} ${skill_name}"
log "Source: ${source_dir}"
log "Destination: ${dest_dir}"

run mkdir -p "${dest_root}"
run rm -rf "${staging_root}"
run mkdir -p "${staging_root}"
run cp -R "${source_dir}" "${staging_dir}"

if [[ -e "${dest_dir}" ]]; then
  run rm -rf "${backup_dir}"
  run mv "${dest_dir}" "${backup_dir}"
fi

restore_backup() {
  if [[ -d "${backup_dir}" && ! -e "${dest_dir}" ]]; then
    mv "${backup_dir}" "${dest_dir}"
  fi
}

if [[ "${dry_run}" -eq 0 ]]; then
  trap 'restore_backup' ERR
fi

run mv "${staging_dir}" "${dest_dir}"
run rm -rf "${staging_root}"

if [[ -d "${backup_dir}" ]]; then
  run rm -rf "${backup_dir}"
fi

if [[ "${dry_run}" -eq 0 ]]; then
  trap - ERR
fi

log "${skill_name} is available at ${dest_dir}"
log "Restart Codex to pick up the updated skill."
